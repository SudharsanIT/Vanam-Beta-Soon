import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Widgets & Extracted Components
import '../../../core/common/widgets/vanam_preloader.dart';
import '../widgets/premium_weather_card.dart';
import '../widgets/places_horizontal_list.dart';
import '../widgets/recent_sightings_list.dart';

// Services
import '../../../core/services/weather_service.dart';
import '../../../core/services/wildlife_service.dart';
import '../../../core/providers/app_settings_provider.dart';

// Screens
import 'weather_dashboard_screen.dart';
import 'full_map_screen.dart';
import 'package:vanam/features/wild_lens/screens/camera_screen.dart';

// 🔥 GLOBAL PROVIDER TO CONTROL PRELOADER & NAV BAR
final appInitProvider = StateProvider<bool>((ref) => false);

enum _EnvironmentType { forest, mountain, city, village, coastal, unknown }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final WildlifeService _wildlifeService = WildlifeService();

  Map<String, dynamic>? _weather;
  List<Map<String, dynamic>> _realSightings = [];
  List<Map<String, dynamic>> _nearbySpots = [];
  List<Map<String, dynamic>> _nearbyHotels = [];

  bool _isLoading = true;
  bool _isPlacesLoading = false;
  String _currentTime = '';
  double _currentLat = 13.0827;
  double _currentLng = 80.2707;
  bool _hasValidLocation = false;

  _EnvironmentType _environment = _EnvironmentType.unknown;
  String _placeLabel = '';

  late PageController _newsController;
  int _currentNewsIndex = 0;
  Timer? _sliderTimer;
  Timer? _clockTimer;

  static const _green = Color(0xFF9BE15D);
  static const _green2 = Color(0xFF7CB342);
  static const _blue = Color(0xFF67C7FF);

  @override
  void initState() {
    super.initState();
    _newsController = PageController(viewportFraction: 0.92);
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateTime());

    Future.delayed(const Duration(milliseconds: 500), () {
      _loadAllRealData(useGps: true);
    });
    _startNewsSlider();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _newsController.dispose();
    _sliderTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    // 🔥 Fixed syntax error here
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    if (mounted) setState(() => _currentTime = '$hour:$min $period');
  }

  void _startNewsSlider() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_newsController.hasClients && _getDynamicNews().isNotEmpty) {
        _currentNewsIndex = (_currentNewsIndex + 1) % _getDynamicNews().length;
        _newsController.animateToPage(_currentNewsIndex, duration: const Duration(milliseconds: 1000), curve: Curves.easeOutExpo);
      }
    });
  }

  Future<void> _loadAllRealData({bool useGps = true}) async {
    if (mounted) setState(() => _isLoading = true);

    try {
      if (useGps) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) setState(() { _placeLabel = 'GPS Disabled'; _isLoading = false; });
          ref.read(appInitProvider.notifier).state = true;
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted) setState(() { _placeLabel = 'GPS Denied'; _isLoading = false; });
            ref.read(appInitProvider.notifier).state = true;
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          if (mounted) setState(() { _placeLabel = 'GPS Blocked'; _isLoading = false; });
          ref.read(appInitProvider.notifier).state = true;
          return;
        }

        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _hasValidLocation = true;
      }

      final results = await Future.wait<dynamic>([
        _weatherService.fetchWeather(_currentLat, _currentLng),
        _wildlifeService.fetchRealNearbySightings(_currentLat, _currentLng),
        _resolveEnvironment(),
      ]);

      if (mounted) {
        setState(() {
          _weather = results[0] as Map<String, dynamic>?;
          _realSightings = List<Map<String, dynamic>>.from(results[1] as List);
        });
      }

      _fetchNearbyPlacesAndHotelsAsync(_currentLat, _currentLng);

    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
      ref.read(appInitProvider.notifier).state = true;
    }
  }

  Future<void> _fetchNearbyPlacesAndHotelsAsync(double lat, double lng) async {
    if (mounted) {
      setState(() {
        _isPlacesLoading = true;
        _nearbySpots.clear();
        _nearbyHotels.clear();
      });
    }

    List<Map<String, dynamic>> spots = [];
    List<Map<String, dynamic>> hotels = [];

    try {
      final wikiUrl = Uri.parse('https://en.wikipedia.org/w/api.php?action=query&list=geosearch&gscoord=$lat|$lng&gsradius=10000&gslimit=10&format=json');
      final wikiRes = await http.get(wikiUrl).timeout(const Duration(seconds: 8));

      if (wikiRes.statusCode == 200) {
        final wikiData = jsonDecode(wikiRes.body);
        final places = wikiData['query']?['geosearch'] as List? ?? [];

        for (var p in places) {
          spots.add({
            'name': p['title'],
            'type': 'Famous Spot',
            'distanceValue': p['dist'].toDouble(),
            'distance': '${(p['dist'] / 1000).toStringAsFixed(1)} km',
            'lat': p['lat'],
            'lng': p['lon'],
          });
        }
      }
    } catch (e) {
      debugPrint('Wiki Error (Spots): $e');
    }

    try {
      final query = '''
        [out:json][timeout:10];
        (
          nwr["tourism"~"hotel|resort|guest_house|motel"](around:15000,$lat,$lng);
          nwr["amenity"~"place_of_worship"](around:10000,$lat,$lng);
        );
        out center 20;
      ''';

      final overpassUrl = Uri.parse('https://overpass-api.de/api/interpreter');
      final overpassRes = await http.post(
        overpassUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      ).timeout(const Duration(seconds: 10));

      if (overpassRes.statusCode == 200) {
        final data = jsonDecode(overpassRes.body);
        final elements = data['elements'] as List? ?? [];

        for (var el in elements) {
          final tags = el['tags'] ?? {};
          final name = tags['name'] ?? tags['name:en'];
          if (name == null || name.toString().trim().isEmpty) continue;

          double pLat = (el['lat'] ?? el['center']?['lat'] ?? lat).toDouble();
          double pLng = (el['lon'] ?? el['center']?['lon'] ?? lng).toDouble();
          double dist = Geolocator.distanceBetween(lat, lng, pLat, pLng);

          final placeData = {
            'name': name,
            'type': tags.containsKey('tourism') ? 'Hotel / Stay' : 'Temple',
            'distanceValue': dist,
            'distance': '${(dist / 1000).toStringAsFixed(1)} km',
            'lat': pLat,
            'lng': pLng,
          };

          if (tags.containsKey('tourism')) {
            if (!hotels.any((h) => h['name'] == name)) hotels.add(placeData);
          } else {
            if (!spots.any((s) => s['name'] == name)) spots.add(placeData);
          }
        }
      }
    } catch (e) {
      debugPrint('Overpass Error (Hotels): $e');
    }

    if (hotels.isEmpty) {
      try {
        String searchArea = _placeLabel != 'Live Zone' ? _placeLabel : 'Tamil Nadu';
        final nomUrl = Uri.parse('https://nominatim.openstreetmap.org/search?q=hotel+in+$searchArea&format=json&limit=10');
        final nomRes = await http.get(nomUrl, headers: {'User-Agent': 'VANAM-App'}).timeout(const Duration(seconds: 8));

        if (nomRes.statusCode == 200) {
          final nomData = jsonDecode(nomRes.body) as List? ?? [];
          for (var h in nomData) {
            double hLat = double.parse(h['lat']);
            double hLon = double.parse(h['lon']);
            double dist = Geolocator.distanceBetween(lat, lng, hLat, hLon);

            hotels.add({
              'name': h['name']?.toString().isNotEmpty == true ? h['name'] : h['display_name'].split(',').first,
              'type': 'Hotel / Stay',
              'distanceValue': dist,
              'distance': '${(dist / 1000).toStringAsFixed(1)} km',
              'lat': hLat,
              'lng': hLon,
            });
          }
        }
      } catch (e) {
        debugPrint('Nominatim Fallback Error: $e');
      }
    }

    spots.sort((a, b) => (a['distanceValue'] as double).compareTo(b['distanceValue'] as double));
    hotels.sort((a, b) => (a['distanceValue'] as double).compareTo(b['distanceValue'] as double));

    if (mounted) {
      setState(() {
        _nearbySpots = spots.take(8).toList();
        _nearbyHotels = hotels.take(8).toList();
        _isPlacesLoading = false;
      });
    }
  }

  Future<void> _resolveEnvironment() async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {'lat': _currentLat.toString(), 'lon': _currentLng.toString(), 'format': 'jsonv2', 'zoom': '18', 'addressdetails': '1'});
      final response = await http.get(uri, headers: {'User-Agent': 'VANAM-App/1.0'}).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final address = Map<String, dynamic>.from(json['address'] ?? {});

        if (mounted) {
          _environment = _classifyEnvironment(json['display_name']?.toString() ?? '');

          String bestName = '';
          final priorities = ['suburb', 'village', 'town', 'city_district', 'city', 'county', 'neighbourhood', 'state_district'];

          for (var key in priorities) {
            if (address.containsKey(key)) {
              String val = address[key].toString();
              if (!val.toLowerCase().contains('division') &&
                  !val.toLowerCase().contains('ward') &&
                  !val.toLowerCase().contains('zone') &&
                  !val.toLowerCase().contains('cmwssb')) {
                bestName = val;
                break;
              }
            }
          }
          _placeLabel = bestName.isNotEmpty ? bestName : 'Live Zone';
        }
      }
    } catch (_) {
      _placeLabel = '${_currentLat.toStringAsFixed(3)}, ${_currentLng.toStringAsFixed(3)}';
    }
  }

  _EnvironmentType _classifyEnvironment(String text) {
    if (text.contains('forest') || text.contains('national park') || text.contains('reserve')) return _EnvironmentType.forest;
    if (text.contains('hill') || text.contains('mountain') || text.contains('ghat')) return _EnvironmentType.mountain;
    if (text.contains('beach') || text.contains('coast')) return _EnvironmentType.coastal;
    if (text.contains('village') || text.contains('panchayat')) return _EnvironmentType.village;
    return _EnvironmentType.city;
  }

  Future<void> _searchLocation(String query) async {
    if (mounted) {
      setState(() { _isLoading = true; _nearbySpots.clear(); _nearbyHotels.clear(); });
      ref.read(appInitProvider.notifier).state = false;
    }

    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(uri, headers: {'User-Agent': 'VANAM-App'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _currentLat = double.parse(data[0]['lat']);
            _currentLng = double.parse(data[0]['lon']);
            _placeLabel = data[0]['name'] ?? query;
            _hasValidLocation = true;
          });
          await _loadAllRealData(useGps: false);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not found. Try another name.'), backgroundColor: Colors.redAccent));
            setState(() => _isLoading = false);
            ref.read(appInitProvider.notifier).state = true;
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ref.read(appInitProvider.notifier).state = true;
      }
    }
  }

  int _weatherCode() => int.tryParse(_weather?['weatherCode']?.toString() ?? '') ?? 0;

  bool _isRaining() {
    final code = _weatherCode();
    return (code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95;
  }

  Map<String, dynamic> _calculateDynamicRisks() {
    if (_weather == null) return {'fire': 'Low', 'fireColor': _green2, 'flood': 'Low', 'floodColor': _green2, 'health': 'Good', 'healthColor': _green2};
    final temp = int.tryParse(_weather!['temp']?.toString().replaceAll('°C', '').trim() ?? '') ?? 25;
    final humidity = int.tryParse(_weather!['humidity']?.toString().replaceAll('%', '').trim() ?? '') ?? 50;
    final code = _weatherCode();

    String fireRisk = 'Low'; Color fireColor = _green2;
    if (temp >= 38 && humidity < 35) { fireRisk = 'High'; fireColor = const Color(0xFFFF5252); }
    else if (temp >= 35 && humidity < 45) { fireRisk = 'Medium'; fireColor = const Color(0xFFFFB74D); }

    String floodRisk = 'Low'; Color floodColor = _green2;
    if (code >= 95 || code == 65 || code == 61) { floodRisk = 'High'; floodColor = const Color(0xFFFF5252); }
    else if (code == 63 || code == 82) { floodRisk = 'Medium'; floodColor = const Color(0xFFFFB74D); }

    String health = 'Good'; Color healthColor = _green2;
    if (temp > 40 || fireRisk == 'High') { health = 'Stress'; healthColor = const Color(0xFFFFB74D); }

    return {'fire': fireRisk, 'fireColor': fireColor, 'flood': floodRisk, 'floodColor': floodColor, 'health': health, 'healthColor': healthColor};
  }

  List<Map<String, String>> _getDynamicNews() {
    if (_isLoading) return [];
    List<Map<String, String>> news = [];
    final risks = _calculateDynamicRisks();
    final rainChance = int.tryParse(_weather?['rainChanceToday']?.toString().replaceAll('%', '') ?? '0') ?? 0;

    if (risks['fire'] == 'High') news.add({'tag': 'CRITICAL', 'color': '0xFFFF3B30', 'title': 'High Wildfire Risk Detected', 'desc': 'Extreme dry heat in $_placeLabel. Avoid any sparks.'});
    else if (risks['flood'] == 'High' || rainChance > 80) news.add({'tag': 'STORM WARNING', 'color': '0xFF0A84FF', 'title': 'Heavy Precipitation', 'desc': 'Severe rain probability ($rainChance%). Beware of flash floods.'});

    if (_realSightings.isNotEmpty) {
      final latest = _realSightings.first;
      if (latest['risk'] == 'High Risk') news.add({'tag': 'DANGER', 'color': '0xFFFF3B30', 'title': '${latest['title']} Proximity Alert', 'desc': 'Dangerous wildlife spotted ${latest['distance']} away.'});
      else news.add({'tag': 'WILDLIFE', 'color': '0xFF30D158', 'title': '${latest['title']} Activity', 'desc': 'Observed near your sector approximately ${latest['time']}.'});
    }

    if (news.isEmpty) news.add({'tag': 'SAFE ZONE', 'color': '0xFF30D158', 'title': 'Stable Conditions', 'desc': 'No severe weather or dangerous wildlife reported.'});
    return news;
  }

  // 🔥 NEW FEATURE: SHOW LANGUAGE SELECTION POPUP FOR AI CHATBOT
  void _showChatLanguagePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.forest, color: _green, size: 28),
              SizedBox(width: 12),
              Text('Vanam AI Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: const Text(
            'Select your preferred language / உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openChatBot(context, 'ta');
              },
              child: const Text('தமிழ்', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _openChatBot(context, 'en');
              },
              child: const Text('English', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openChatBot(BuildContext context, String lang) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VanamAIChatScreen(language: lang)));
  }

  void _showLocationSearchSheet(Color surfaceColor, Color bgColor, Color textColor) {
    final TextEditingController searchController = TextEditingController();
    Timer? debounce;
    List<dynamic> suggestions = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Set Manual Location", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                    onChanged: (val) {
                      if (debounce?.isActive ?? false) debounce!.cancel();
                      debounce = Timer(const Duration(milliseconds: 600), () async {
                        if (val.trim().isEmpty) {
                          setModalState(() { suggestions = []; isSearching = false; });
                          return;
                        }
                        setModalState(() => isSearching = true);
                        try {
                          final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=$val&format=json&limit=5');
                          final response = await http.get(uri, headers: {'User-Agent': 'VANAM-App'});
                          if (response.statusCode == 200) {
                            setModalState(() {
                              suggestions = jsonDecode(response.body);
                              isSearching = false;
                            });
                          }
                        } catch (_) {
                          setModalState(() { suggestions = []; isSearching = false; });
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "E.g., Mangadu, Valparai",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: bgColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search, color: _green),
                      suffixIcon: isSearching
                          ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _green, strokeWidth: 2)))
                          : (searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () { searchController.clear(); setModalState((){ suggestions.clear(); }); })
                          : null),
                    ),
                    onSubmitted: (val) { Navigator.pop(context); if (val.trim().isNotEmpty) _searchLocation(val.trim()); },
                  ),

                  if (suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.1))
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        itemBuilder: (context, index) {
                          final item = suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_rounded, color: _green, size: 20),
                            title: Text(item['display_name'] ?? '', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              final lat = double.parse(item['lat']);
                              final lon = double.parse(item['lon']);
                              final name = item['name']?.toString().isNotEmpty == true ? item['name'] : item['display_name'].split(',').first;

                              Navigator.pop(context);

                              setState(() {
                                _currentLat = lat;
                                _currentLng = lon;
                                _placeLabel = name;
                                _hasValidLocation = true;
                                _isLoading = true;
                              });
                              ref.read(appInitProvider.notifier).state = false;
                              _loadAllRealData(useGps: false);
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (suggestions.isEmpty)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _green, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () { Navigator.pop(context); if (searchController.text.trim().isNotEmpty) _searchLocation(searchController.text.trim()); },
                      child: const Text("Set Location", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),

                  if (suggestions.isEmpty) const SizedBox(height: 12),

                  Center(
                    child: TextButton.icon(
                      onPressed: () { Navigator.pop(context); ref.read(appInitProvider.notifier).state = false; _loadAllRealData(useGps: true); },
                      icon: const Icon(Icons.my_location, color: _green, size: 18),
                      label: const Text("Use Live GPS", style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
      ),
    );
  }

  void _showSettingsSheet(Color surfaceColor, Color surface2Color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Consumer(
            builder: (context, ref, child) {
              final lang = ref.watch(languageProvider);
              final themeMode = ref.watch(themeModeProvider);
              final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);

              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 32),
                    const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(color: surface2Color, borderRadius: BorderRadius.circular(20)),
                      child: SwitchListTile(
                        title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        secondary: Icon(isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded, color: isDark ? _blue : Colors.orange),
                        activeColor: _green, value: isDark,
                        onChanged: (val) => ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: surface2Color, borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        leading: const Icon(Icons.language_rounded, color: _green),
                        title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(label: const Text('EN', style: TextStyle(fontWeight: FontWeight.w700)), selected: lang == 'en', selectedColor: _green.withOpacity(0.2), onSelected: (val) { if (val) ref.read(languageProvider.notifier).state = 'en'; }),
                            const SizedBox(width: 8),
                            ChoiceChip(label: const Text('தமிழ்', style: TextStyle(fontWeight: FontWeight.w700)), selected: lang == 'ta', selectedColor: _green.withOpacity(0.2), onSelected: (val) { if (val) ref.read(languageProvider.notifier).state = 'ta'; }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  void _openFullWeatherDashboard() {
    if (_weather == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => WeatherDashboardScreen(weatherData: _weather, isLoading: _isLoading, onRefresh: () => _loadAllRealData(useGps: true), currentLat: _currentLat, currentLng: _currentLng)));
  }

  void _openFullMapScreen() { Navigator.push(context, MaterialPageRoute(builder: (_) => FullMapScreen(lat: _currentLat, lng: _currentLng))); }
  void _openWildLensCamera() { Navigator.push(context, MaterialPageRoute(builder: (_) => const WildLensScreen())); }

  void _showPlaceDetailsSheet(Map<String, dynamic> place, Color accentColor, IconData icon, Color surfaceColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place['name'], style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(place['type'], style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Text('${place['distance']} away from your location', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Text('${(place['lat'] as double).toStringAsFixed(4)}, ${(place['lng'] as double).toStringAsFixed(4)}', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FullMapScreen(lat: place['lat'], lng: place['lng'])));
                },
                icon: const Icon(Icons.map_rounded, color: Colors.black),
                label: const Text('View on Map', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSightingImageDialog(Map<String, dynamic> item, int index) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Hero(
                      tag: 'sighting_$index',
                      child: Image.network(
                        item['image']?.toString() ?? '',
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(item['riskColor'] ?? 0xFF7CB342).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['risk']?.toString() ?? 'OBSERVED',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black, Colors.transparent],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item['title']?.toString() ?? 'Wildlife', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Row(children: [const Icon(Icons.location_on_rounded, color: Color(0xFF9BE15D), size: 16), const SizedBox(width: 8), Expanded(child: Text(item['location']?.toString() ?? '--', style: const TextStyle(color: Colors.white70, fontSize: 14)))]),
                          const SizedBox(height: 12),
                          Row(children: [const Icon(Icons.route_rounded, color: Colors.white54, size: 14), const SizedBox(width: 6), Text('${item['distance'] ?? '--'} away', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(width: 20), const Icon(Icons.access_time_rounded, color: Colors.white54, size: 14), const SizedBox(width: 6), Text(item['time']?.toString() ?? '--', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)), child: child));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && theme.brightness == Brightness.dark);
    final isAppInitialized = ref.watch(appInitProvider);

    final bgColor = isDark ? const Color(0xFF07110D) : const Color(0xFFF4F8F5);
    final surfaceColor = isDark ? const Color(0xFF0E1914) : Colors.white;
    final surface2Color = isDark ? const Color(0xFF132019) : const Color(0xFFE5EFE7);
    final textColor = isDark ? Colors.white : const Color(0xFF101913);
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      // 🔥 FLOATING ACTION BUTTON FOR AI CHATBOT 🔥
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChatLanguagePopup(context),
        backgroundColor: _green,
        elevation: 6,
        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
        label: const Text('Vanam AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        child: !isAppInitialized
            ? VanamPreloader(key: const ValueKey('preloader'), isDark: isDark)
            : _buildMainContent(bgColor, surfaceColor, surface2Color, textColor, subTextColor),
      ),
    );
  }

  Widget _buildMainContent(Color bgColor, Color surfaceColor, Color surface2Color, Color textColor, Color subTextColor) {
    return RefreshIndicator(
      color: _green,
      backgroundColor: surfaceColor,
      onRefresh: () => _loadAllRealData(useGps: true),
      child: SafeArea(
        top: false,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: CustomScrollView(
            key: const ValueKey('main_content'),
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(textColor, surface2Color, surfaceColor, bgColor),
                    const SizedBox(height: 8),
                    PremiumWeatherCard(
                      weather: _weather,
                      isLoading: _isLoading,
                      placeLabel: _placeLabel,
                      currentTime: _currentTime,
                      onTap: _openFullWeatherDashboard,
                    ),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLiveContext(surfaceColor, textColor, subTextColor),
                      const SizedBox(height: 26),
                      _buildQuickActions(surfaceColor, textColor),
                      const SizedBox(height: 28),

                      PlacesHorizontalList(
                        title: 'FAMOUS SPOTS',
                        subtitle: 'EXPLORE NEARBY',
                        items: _nearbySpots,
                        icon: Icons.landscape_rounded,
                        accentColor: _green,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        isLoading: _isPlacesLoading,
                        onItemTap: (item) => _showPlaceDetailsSheet(item, _green, Icons.landscape_rounded, surfaceColor),
                      ),
                      if (_nearbySpots.isNotEmpty || _isPlacesLoading) const SizedBox(height: 28),

                      PlacesHorizontalList(
                        title: 'NEARBY HOTELS',
                        subtitle: 'STAY & REST',
                        items: _nearbyHotels,
                        icon: Icons.bed_rounded,
                        accentColor: _blue,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        isLoading: _isPlacesLoading,
                        onItemTap: (item) => _showPlaceDetailsSheet(item, _blue, Icons.bed_rounded, surfaceColor),
                      ),
                      if (_nearbyHotels.isNotEmpty || _isPlacesLoading) const SizedBox(height: 28),

                      RecentSightingsList(
                        sightings: _realSightings,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        accentColor: _green,
                        onItemTap: (item, index) => _showSightingImageDialog(item, index),
                      ),
                      const SizedBox(height: 30),
                      _buildEnvironmentalNote(surface2Color, subTextColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color surface2Color, Color surfaceColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('VANAM', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 3.0)),
              const SizedBox(width: 8),
              const Icon(Icons.eco_rounded, color: _green, size: 18),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showLocationSearchSheet(surfaceColor, bgColor, textColor),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: surface2Color, shape: BoxShape.circle), child: Icon(Icons.search_rounded, color: textColor, size: 20)),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showSettingsSheet(surfaceColor, surface2Color),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: surface2Color, shape: BoxShape.circle), child: Icon(Icons.settings_rounded, color: textColor, size: 20)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveContext(Color surfaceColor, Color textColor, Color subTextColor) {
    final hasSightings = _realSightings.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Icon(Icons.insights_rounded, color: _green, size: 17), const SizedBox(width: 8), const Text('LIVE CONTEXT', style: TextStyle(color: _green, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)), const Spacer(), Text('ATMOSPHERIC SENSORS', style: TextStyle(color: subTextColor, fontSize: 9, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.1))),
          child: Row(
            children: [
              Container(width: 45, height: 45, decoration: BoxDecoration(color: _green.withOpacity(.10), borderRadius: BorderRadius.circular(16)), child: Icon(hasSightings ? Icons.pets_rounded : Icons.shield_rounded, color: hasSightings ? const Color(0xFFFFC857) : _green, size: 21)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(hasSightings ? '${_realSightings.length} wildlife sighting${_realSightings.length == 1 ? '' : 's'} nearby' : 'No recent wildlife activity detected', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(hasSightings ? 'Real observations from your current area.' : 'VANAM is monitoring the available nearby data.', style: TextStyle(color: subTextColor, fontSize: 10, height: 1.35))])),
              if (hasSightings) Icon(Icons.chevron_right_rounded, color: subTextColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Color surfaceColor, Color textColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('QUICK ACTIONS', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height: 12), Row(children: [Expanded(child: _actionCard(title: 'Report Wildlife', subtitle: 'Capture & submit a live sighting', icon: Icons.camera_alt_outlined, accent: _green, surfaceColor: surfaceColor, textColor: textColor, onTap: _openWildLensCamera)), const SizedBox(width: 12), Expanded(child: _actionCard(title: 'Weather Intelligence', subtitle: 'Open live weather & radar', icon: Icons.radar_rounded, accent: _blue, surfaceColor: surfaceColor, textColor: textColor, onTap: _openFullWeatherDashboard))])]);
  }

  Widget _actionCard({required String title, required String subtitle, required IconData icon, required Color accent, required Color surfaceColor, required Color textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 128, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withOpacity(.11), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: accent, size: 19)), const Spacer(), Container(width: 27, height: 27, decoration: BoxDecoration(color: Colors.grey.withOpacity(.1), shape: BoxShape.circle), child: Icon(Icons.arrow_outward_rounded, color: textColor, size: 13))]), const Spacer(), Text(title, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: accent, fontSize: 8.5, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildEnvironmentalNote(Color surface2Color, Color subTextColor) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface2Color, borderRadius: BorderRadius.circular(22), border: Border.all(color: _green.withOpacity(.10))), child: Row(children: [const Icon(Icons.auto_awesome_rounded, color: _green, size: 19), const SizedBox(width: 11), Expanded(child: Text(_isRaining() ? 'Weather-aware visuals are adapting to current precipitation.' : 'VANAM adapts the scene to your local weather and time of day.', style: TextStyle(color: subTextColor, fontSize: 10, height: 1.4)))]) );
  }
}

// =====================================================================
// 🔥 NEW AI CHAT SCREEN (FOREST OFFICER PERSONA) 🔥
// Intha class-ah same file oda bottom-la add pannidu da
// =====================================================================

class VanamAIChatScreen extends StatefulWidget {
  final String language;
  const VanamAIChatScreen({super.key, required this.language});

  @override
  State<VanamAIChatScreen> createState() => _VanamAIChatScreenState();
}

class _VanamAIChatScreenState extends State<VanamAIChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  static const _green = Color(0xFF7CB342);

  @override
  void initState() {
    super.initState();
    _setInitialGreeting();
  }

  void _setInitialGreeting() {
    String greeting = widget.language == 'ta'
        ? "வணக்கம்! நான் வனத்துறை அதிகாரி (Forest Officer). தமிழ்நாட்டின் காடுகள், வனவிலங்குகள் பாதுகாப்பு மற்றும் சுற்றுச்சூழல் பற்றி உங்களுக்கு என்ன உதவி வேண்டும்?"
        : "Vanakkam! I am the Forest Officer. How can I guide you regarding Tamil Nadu's forests, wildlife safety, or eco-tourism today?";

    setState(() {
      _messages.add({"role": "bot", "text": greeting});
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isTyping = true;
    });
    _chatController.clear();

    // 🔴 INGA UNGA BACKEND API-AH CONNECT PANNANUM (OpenAI / Gemini) 🔴
    // Simulating API Delay for now
    await Future.delayed(const Duration(seconds: 2));

    String dummyReply = widget.language == 'ta'
        ? "வனத்துறையின் சார்பாக நன்றி. நீங்கள் கேட்ட கேள்விக்கு தற்போதைக்கு பதில் அளிக்க முடியவில்லை. (API-யை இணைக்கவும்)"
        : "Thank you for asking. As a Forest Officer, I am currently disconnected from the main database. (Please connect your AI API).";

    setState(() {
      _messages.add({"role": "bot", "text": dummyReply});
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.security, color: _green),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Forest Officer AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(widget.language == 'ta' ? 'தமிழ் வழிகாட்டி' : 'TN Guide', style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                        color: isUser ? _green : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Forest Officer is typing...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: widget.language == 'ta' ? 'கேள்வி கேளுங்கள்...' : 'Ask a question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF4F8F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}