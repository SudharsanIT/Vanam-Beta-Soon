import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';

class MapScreen extends StatefulWidget {
  // Receives live coordinates from Home Screen
  final double? initialLat;
  final double? initialLng;

  const MapScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  double _currentLat = 13.0827; // Fallback
  double _currentLng = 80.2707; // Fallback
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // If coordinates are passed from HomeScreen, use them instantly!
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentLat = widget.initialLat!;
      _currentLng = widget.initialLng!;
    } else {
      // Otherwise, fetch it manually
      _fetchExactLocation();
    }
  }

  Future<void> _fetchExactLocation() async {
    setState(() => _isLocating = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _isLocating = false;
      });
      // Move map exactly to current location with max zoom
      _mapController.move(LatLng(_currentLat, _currentLng), 17.0);
    } catch (e) {
      setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Live Terrain Map', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentLat, _currentLng),
              initialZoom: 17.0, // High zoom for exact street/building view
              maxZoom: 22.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // Allows pinch to zoom, pan, etc.
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.enterprise.vanam',
              ),
              // Exact Live Location Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentLat, _currentLng),
                    width: 60,
                    height: 60,
                    child: _buildPulsingMarker(),
                  ),
                ],
              ),
            ],
          ),

          // Floating "Recenter to My Location" Button
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryGreen,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: _fetchExactLocation,
              child: _isLocating
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Icon(Icons.my_location_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
          ),
        ),
      ),
    );
  }
}