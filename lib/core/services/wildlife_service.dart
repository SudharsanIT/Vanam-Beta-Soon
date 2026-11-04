import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WildlifeService {
  // 🔥 1. LOCAL STORAGE: யூசர் எடுக்குற போட்டோஸ சேமிக்க
  static final List<Map<String, dynamic>> _userSightings = [];

  // 🔥 2. ADD NEW SIGHTING: கேமராவுல போட்டோ எடுத்ததும் இதை கூப்பிடணும்!
  static void reportNewSighting({
    required String imagePath,
    required String speciesName,
    required String locationName,
    required String riskLevel,
  }) {
    _userSightings.insert(0, {
      'title': speciesName,
      'distance': '0.0 km', // யூசர் இருக்குற அதே இடம்
      'time': 'Just now',
      'location': locationName,
      'risk': riskLevel,
      'riskColor': riskLevel == 'High Risk' ? 0xFFFF5252 : (riskLevel == 'Medium Risk' ? 0xFFFFB74D : 0xFF7CB342),
      'image': imagePath, // Local File Path
      'isLocal': true, // 🔥 இது ரொம்ப முக்கியம்! அப்போதான் UI-க்கு இது போன்ல இருக்குற போட்டோனு தெரியும்
    });
  }

  /// Fetches 100% REAL wildlife sightings and FILTERS OUT broken images before showing to UI.
  Future<List<Map<String, dynamic>>> fetchRealNearbySightings(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://api.inaturalist.org/v1/observations?lat=$lat&lng=$lng&radius=15&per_page=10&iconic_taxa=Mammalia,Reptilia,Amphibia,Aves&has_photos=true');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isEmpty) return [..._userSightings]; // API-ல ஒன்னும் இல்லைனாலும் யூசர் போட்டோவ காட்டும்

        List<Future<Map<String, dynamic>?>> futures = results.map((obs) async {
          try {
            final taxon = obs['taxon'];
            final photos = obs['photos'] as List;
            if (taxon == null || photos.isEmpty) return null;

            final speciesName = taxon['preferred_common_name'] ?? taxon['name'] ?? 'Unknown Species';

            String rawUrl = photos[0]['url'].toString();
            if (rawUrl.startsWith('http://')) {
              rawUrl = rawUrl.replaceFirst('http://', 'https://');
            } else if (rawUrl.startsWith('//')) {
              rawUrl = 'https:$rawUrl';
            } else if (!rawUrl.startsWith('http')) {
              rawUrl = 'https://$rawUrl';
            }

            String mediumUrl = rawUrl.replaceAll('square', 'medium');

            bool isImageValid = await _isImageAlive(mediumUrl);
            String finalUrl = mediumUrl;

            if (!isImageValid) {
              isImageValid = await _isImageAlive(rawUrl);
              finalUrl = rawUrl;
            }

            if (!isImageValid) return null;

            final placeGuess = obs['place_guess'] ?? 'Unknown Location';
            final timeObserved = obs['time_observed_at'];

            double obsLat = obs['geojson']['coordinates'][1];
            double obsLng = obs['geojson']['coordinates'][0];
            double distanceInMeters = Geolocator.distanceBetween(lat, lng, obsLat, obsLng);
            String distanceStr = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';

            String risk = _determineRisk(speciesName);

            return {
              'title': _capitalize(speciesName),
              'distance': distanceStr,
              'time': _formatTime(timeStr: timeObserved),
              'location': placeGuess,
              'risk': risk,
              'riskColor': _determineRiskColor(risk),
              'image': finalUrl,
              'isLocal': false, // 🔥 API இமேஜ்னு UI-க்கு சொல்றோம்
            };
          } catch (e) {
            return null;
          }
        }).toList();

        List<Map<String, dynamic>?> resolved = await Future.wait(futures);
        List<Map<String, dynamic>> finalRemoteList = resolved.whereType<Map<String, dynamic>>().toList();

        // 🔥 3. COMBINE: யூசர் எடுத்த போட்டோவை ஃபர்ஸ்ட் காட்டிட்டு, அப்புறம் API போட்டோவ காட்டும்
        return [..._userSightings, ...finalRemoteList];
      }
    } catch (e) {
      print("Wildlife API Error: $e");
    }
    return [..._userSightings];
  }

  Future<bool> _isImageAlive(String url) async {
    try {
      final res = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _formatTime({String? timeStr}) {
    if (timeStr == null) return 'Recently';
    try {
      final obsTime = DateTime.parse(timeStr);
      final diff = DateTime.now().difference(obsTime);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hrs ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (e) {
      return 'Recently';
    }
  }

  String _determineRisk(String name) {
    String n = name.toLowerCase();
    if (n.contains('elephant') || n.contains('tiger') || n.contains('leopard') || n.contains('bear') || n.contains('cobra') || n.contains('viper') || n.contains('crocodile')) {
      return 'High Risk';
    }
    if (n.contains('boar') || n.contains('macaque') || n.contains('monkey') || n.contains('deer') || n.contains('snake') || n.contains('jackal') || n.contains('wild dog')) {
      return 'Medium Risk';
    }
    return 'Low Risk';
  }

  int _determineRiskColor(String risk) {
    if (risk == 'High Risk') return 0xFFFF5252;
    if (risk == 'Medium Risk') return 0xFFFFB74D;
    return 0xFF7CB342;
  }

  String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;
}