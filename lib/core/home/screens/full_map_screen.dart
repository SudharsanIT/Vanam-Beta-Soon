import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

enum MapTileType {
  satellite,
  topographic,
  dark,
  street,
}

class FullMapScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final String? placeName;

  const FullMapScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.placeName,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> with TickerProviderStateMixin {
  late final MapController _mapController;

  // Map Layer States
  MapTileType _currentTileType = MapTileType.satellite;
  bool _showRadarRings = true;
  bool _showWildlifeAlerts = true;
  bool _showDetailsCard = true;

  // Live Location & Measurement
  Position? _userPosition;
  double? _distanceFromUserKm;
  double _currentZoom = 15.0;

  // Search Bar
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  // Resolved Location Meta Details
  String _resolvedTitle = 'Target Sector';
  String _resolvedAddress = 'Fetching Satellite Geolocation...';
  double _estimatedElevation = 320.0; // Simulated altitude in meters
  bool _isLoadingDetails = true;

  // Simulated Nearby Wildlife Threat Pins around target
  List<Map<String, dynamic>> _threatPins = [];

  // Theme Colors
  static const _primaryGreen = Color(0xFF9BE15D);
  static const _dangerRed = Color(0xFFFF5252);
  static const _blueAccent = Color(0xFF67C7FF);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _resolvedTitle = widget.placeName ?? 'Selected Perimeter';

    _fetchUserLocation();
    _fetchLocationAddress(widget.lat, widget.lng);
    _generateThreatOverlay(widget.lat, widget.lng);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- GPS & GEOLOCATION LOGIC ---

  Future<void> _fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (mounted) {
        setState(() {
          _userPosition = pos;
          _calculateDistance();
        });
      }
    } catch (_) {}
  }

  void _calculateDistance() {
    if (_userPosition == null) return;
    final distanceMeter = const Distance().as(
      LengthUnit.Meter,
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      LatLng(widget.lat, widget.lng),
    );
    setState(() {
      _distanceFromUserKm = distanceMeter / 1000.0;
    });
  }

  Future<void> _fetchLocationAddress(double lat, double lng) async {
    if (mounted) setState(() => _isLoadingDetails = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'jsonv2',
        'zoom': '18',
        'addressdetails': '1',
      });

      final response = await http.get(uri, headers: {'User-Agent': 'VANAM-TacticalMap/1.0'}).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final address = json['address'] ?? {};
        final displayName = json['display_name'] ?? 'Unknown Sector';

        if (mounted) {
          setState(() {
            _resolvedTitle = address['neighbourhood'] ?? address['village'] ?? address['suburb'] ?? address['town'] ?? address['city'] ?? widget.placeName ?? 'Target Zone';
            _resolvedAddress = displayName;
            _estimatedElevation = 150.0 + (math.Random(lat.hashCode).nextDouble() * 450.0); // Procedural Elevation estimate
            _isLoadingDetails = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress = '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E';
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _searchMapLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5');
      final response = await http.get(uri, headers: {'User-Agent': 'VANAM-App'});

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
          _isSearching = false;
        });
      }
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  void _generateThreatOverlay(double lat, double lng) {
    final rng = math.Random(42);
    List<Map<String, dynamic>> pins = [];

    // Generate 3 procedural wildlife risk pins near coordinates
    for (int i = 0; i < 3; i++) {
      double offsetLat = (rng.nextDouble() - 0.5) * 0.04;
      double offsetLng = (rng.nextDouble() - 0.5) * 0.04;
      pins.add({
        'point': LatLng(lat + offsetLat, lng + offsetLng),
        'title': i == 0 ? 'Elephant Movement' : (i == 1 ? 'Wild Boar Herd' : 'Leopard Sighting'),
        'risk': i == 0 ? 'HIGH' : 'MODERATE',
        'color': i == 0 ? _dangerRed : const Color(0xFFFFB74D),
      });
    }
    setState(() => _threatPins = pins);
  }

  // --- MAP CONTROLLER ACTIONS ---

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _recenterToTarget() {
    _animatedMapMove(LatLng(widget.lat, widget.lng), 15.0);
  }

  void _recenterToUser() {
    if (_userPosition != null) {
      _animatedMapMove(LatLng(_userPosition!.latitude, _userPosition!.longitude), 15.5);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acquiring GPS Fix... Please wait.'), backgroundColor: Colors.orange));
      _fetchUserLocation();
    }
  }

  Future<void> _launchExternalNavigation() async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.lng}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open external map app.')));
      }
    }
  }

  void _copyCoordinates() {
    final coords = '${widget.lat.toStringAsFixed(6)}, ${widget.lng.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: coords));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied Coordinates: $coords'),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Tile URL Resolvers - Fixed Default Warning Here 🔥
  String _getTileUrl(MapTileType type, bool isDarkTheme) {
    switch (type) {
      case MapTileType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTileType.topographic:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapTileType.dark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case MapTileType.street:
        return isDarkTheme
            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetLatLng = LatLng(widget.lat, widget.lng);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07110D) : Colors.grey[900],
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. MAIN FLUTTER MAP ENGINE
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: targetLatLng,
              initialZoom: _currentZoom,
              minZoom: 4.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              // 🔥 Fixed MapPosition Rotation Error Here
              onPositionChanged: (position, hasGesture) {
                if (position.zoom != null && mounted) {
                  setState(() {
                    _currentZoom = position.zoom!;
                  });
                }
              },
            ),
            children: [
              // BASE TILE LAYER
              TileLayer(
                urlTemplate: _getTileUrl(_currentTileType, isDark),
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.enterprise.vanam',
                maxZoom: 18,
              ),

              // RADAR SAFETY PERIMETER CIRCLES (5km, 10km, 15km)
              if (_showRadarRings)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: targetLatLng,
                      radius: 5000, // 5km
                      useRadiusInMeter: true,
                      color: _primaryGreen.withValues(alpha: 0.08),
                      borderColor: _primaryGreen.withValues(alpha: 0.6),
                      borderStrokeWidth: 1.5,
                    ),
                    CircleMarker(
                      point: targetLatLng,
                      radius: 10000, // 10km
                      useRadiusInMeter: true,
                      color: Colors.transparent,
                      borderColor: _blueAccent.withValues(alpha: 0.4),
                      borderStrokeWidth: 1.0,
                    ),
                    CircleMarker(
                      point: targetLatLng,
                      radius: 15000, // 15km
                      useRadiusInMeter: true,
                      color: Colors.transparent,
                      borderColor: _dangerRed.withValues(alpha: 0.3),
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                ),

              // DISTANCE LINE FROM LIVE USER POSITION TO TARGET
              if (_userPosition != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        LatLng(_userPosition!.latitude, _userPosition!.longitude),
                        targetLatLng,
                      ],
                      strokeWidth: 2.5,
                      color: _primaryGreen,
                      isDotted: true,
                    ),
                  ],
                ),

              // THREAT OVERLAY & LOCATION MARKERS
              MarkerLayer(
                markers: [
                  // TARGET LOCATION PIN
                  Marker(
                    point: targetLatLng,
                    width: 70,
                    height: 70,
                    child: _buildTargetMarker(),
                  ),

                  // USER LIVE GPS MARKER
                  if (_userPosition != null)
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 44,
                      height: 44,
                      child: _buildUserLocationMarker(),
                    ),

                  // WILDLIFE THREAT OVERLAY PINS
                  if (_showWildlifeAlerts)
                    ..._threatPins.map((threat) {
                      return Marker(
                        point: threat['point'] as LatLng,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚠️ Alert: ${threat['title']} (${threat['risk']} Risk)'),
                                backgroundColor: threat['color'] as Color,
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(color: (threat['color'] as Color).withValues(alpha: 0.85), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.pets_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ],
          ),

          // 2. TOP FLOATING APP BAR & SEARCH
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Interactive In-Map Search Bar
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Search map location...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: _primaryGreen, size: 20),
                              suffixIcon: _isSearching
                                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen)))
                                  : (_searchController.text.isNotEmpty
                                  ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54, size: 18), onPressed: () => setState(() { _searchController.clear(); _searchResults.clear(); }))
                                  : null),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: _searchMapLocation,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Map Type Menu Button
                      GestureDetector(
                        onTap: _showLayerPickerSheet,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                          child: const Icon(Icons.layers_rounded, color: _primaryGreen, size: 20),
                        ),
                      ),
                    ],
                  ),

                  // Search Auto-Suggestions Dropdown
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(color: const Color(0xFF0E1914).withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _searchResults.map((item) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, color: _primaryGreen, size: 18),
                            title: Text(item['display_name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            onTap: () {
                              final lat = double.parse(item['lat']);
                              final lon = double.parse(item['lon']);
                              setState(() {
                                _searchResults.clear();
                                _searchController.clear();
                              });
                              _animatedMapMove(LatLng(lat, lon), 15.0);
                              _fetchLocationAddress(lat, lon);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. RIGHT SIDE CONTROL PANEL (Zoom, Recenter, Compass)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.22,
            child: Column(
              children: [
                // Zoom In (+) Button
                _mapControlButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    if (_currentZoom < 18.0) {
                      _animatedMapMove(_mapController.camera.center, _currentZoom + 1.0);
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Zoom Out (-) Button
                _mapControlButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (_currentZoom > 4.0) {
                      _animatedMapMove(_mapController.camera.center, _currentZoom - 1.0);
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Recenter Target Button
                _mapControlButton(
                  icon: Icons.center_focus_strong_rounded,
                  color: _primaryGreen,
                  onTap: _recenterToTarget,
                ),
                const SizedBox(height: 10),

                // Live GPS User Recenter
                _mapControlButton(
                  icon: Icons.my_location_rounded,
                  color: _blueAccent,
                  onTap: _recenterToUser,
                ),
                const SizedBox(height: 10),

                // Compass Orientation Indicator Button
                _mapControlButton(
                  icon: Icons.navigation_rounded,
                  color: Colors.orangeAccent,
                  onTap: () => _mapController.rotate(0), // Reset Rotation
                ),
              ],
            ),
          ),

          // 4. BOTTOM FLOATING DETAILS PANEL
          if (_showDetailsCard)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildDetailsCard(isDark),
            ),
        ],
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildTargetMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Radar Ripple
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryGreen.withValues(alpha: 0.2),
            border: Border.all(color: _primaryGreen.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        // Center Pin Container
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: const Icon(Icons.location_on_rounded, color: _primaryGreen, size: 26),
        ),
      ],
    );
  }

  Widget _buildUserLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: _blueAccent.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(color: _blueAccent, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _mapControlButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1914).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Hide Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.terrain_rounded, color: _primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resolvedTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isLoadingDetails ? 'Syncing GIS coordinates...' : _resolvedAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showDetailsCard = false),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metadata Chips Row (Elevation, Distance, Coordinates)
              Row(
                children: [
                  _detailChip(
                    Icons.straighten_rounded,
                    _distanceFromUserKm != null ? '${_distanceFromUserKm!.toStringAsFixed(1)} km away' : 'Calculating...',
                    _blueAccent,
                  ),
                  const SizedBox(width: 8),
                  _detailChip(
                    Icons.landscape_rounded,
                    '~${_estimatedElevation.toInt()}m Elev',
                    const Color(0xFFFFB74D),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _copyCoordinates,
                    child: _detailChip(
                      Icons.copy_rounded,
                      '${widget.lat.toStringAsFixed(3)}, ${widget.lng.toStringAsFixed(3)}',
                      _primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons Row (Navigate, Safety Radar Toggle, Share)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _launchExternalNavigation,
                      icon: const Icon(Icons.navigation_rounded, color: Colors.black, size: 18),
                      label: const Text('Navigate (Maps)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _showRadarRings = !_showRadarRings),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: _showRadarRings ? _primaryGreen.withValues(alpha: 0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _showRadarRings ? _primaryGreen : Colors.white24),
                      ),
                      child: Icon(Icons.radar_rounded, color: _showRadarRings ? _primaryGreen : Colors.white54, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 12),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // --- LAYER PICKER MODAL SHEET ---

  void _showLayerPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1914),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Text('Map Layer & Overlays', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Tile Switcher Cards
                  Row(
                    children: [
                      _tileOptionCard('Satellite', Icons.satellite_alt_rounded, MapTileType.satellite, setSheetState),
                      const SizedBox(width: 10),
                      _tileOptionCard('Topographic', Icons.terrain_rounded, MapTileType.topographic, setSheetState),
                      const SizedBox(width: 10),
                      _tileOptionCard('Tactical Dark', Icons.dark_mode_rounded, MapTileType.dark, setSheetState),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Toggles
                  SwitchListTile(
                    activeColor: _primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Safety Perimeter Radar Rings', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Draw 5km / 10km / 15km sector rings', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    value: _showRadarRings,
                    onChanged: (val) {
                      setState(() => _showRadarRings = val);
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    activeColor: _primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wildlife Risk Overlay', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Show live reported threat pins near sector', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    value: _showWildlifeAlerts,
                    onChanged: (val) {
                      setState(() => _showWildlifeAlerts = val);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _tileOptionCard(String label, IconData icon, MapTileType type, StateSetter setSheetState) {
    final isSelected = _currentTileType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentTileType = type);
          setSheetState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? _primaryGreen.withValues(alpha: 0.15) : const Color(0xFF132019),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? _primaryGreen : Colors.white10, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? _primaryGreen : Colors.white54, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? _primaryGreen : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}