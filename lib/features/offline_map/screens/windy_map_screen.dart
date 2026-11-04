import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum WindyLayer { radar, wind, clouds, cyclone }

class WindyMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const WindyMapScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<WindyMapScreen> createState() => _WindyMapScreenState();
}

class _WindyMapScreenState extends State<WindyMapScreen> {
  WindyLayer _activeLayer = WindyLayer.radar;
  final MapController _mapController = MapController();

  // 🔥 POTU VACHIRUKKA DUMMY KEY-A THOOKITU UN REAL API KEY-A INGA PODU 🔥
  final String _weatherApiKey = '554d805ba0ab3f20e633706e2eefdc3f';

  static const _bg = Color(0xFF07110D);
  static const _green = Color(0xFF9BE15D);

  // 100% REAL LIVE MAP OVERLAYS FROM OPENWEATHERMAP API
  String _getRealRadarTileUrl() {
    String layerName = 'precipitation_new';
    switch (_activeLayer) {
      case WindyLayer.radar:
        layerName = 'precipitation_new'; // Live Rain Radar
        break;
      case WindyLayer.wind:
        layerName = 'wind_new'; // Live Wind Flow
        break;
      case WindyLayer.clouds:
        layerName = 'clouds_new'; // Live Cloud Coverage
        break;
      case WindyLayer.cyclone:
        layerName = 'pressure_new'; // Live Cyclone/Pressure Isobars
        break;
    }
    return 'https://tile.openweathermap.org/map/$layerName/{z}/{x}/{y}.png?appid=$_weatherApiKey';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18, top: 10, bottom: 10),
          child: Material(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🌍 FULLY INTERACTIVE GLOBAL MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.initialLat, widget.initialLng),
              initialZoom: 6.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Dark Base Map
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.enterprise.vanam',
              ),

              // 🌪️ REAL WINDY WEATHER RADAR LAYER (NO FAKE CIRCLES)
              TileLayer(
                urlTemplate: _getRealRadarTileUrl(),
                backgroundColor: Colors.transparent, // Ensures base map is visible underneath
                userAgentPackageName: 'com.enterprise.vanam',
              ),

              // User Location Pin
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.initialLat, widget.initialLng),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: _green, size: 30),
                  ),
                ],
              ),
            ],
          ),

          // 🎛️ FLOATING LAYER SELECTOR
          Positioned(
            top: 100,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLayerButton(WindyLayer.radar, Icons.water_drop_rounded, 'Rain'),
                      const SizedBox(height: 16),
                      _buildLayerButton(WindyLayer.wind, Icons.air_rounded, 'Wind'),
                      const SizedBox(height: 16),
                      _buildLayerButton(WindyLayer.clouds, Icons.cloud_rounded, 'Clouds'),
                      const SizedBox(height: 16),
                      _buildLayerButton(WindyLayer.cyclone, Icons.cyclone_rounded, 'Cyclone'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 📍 FLOATING RE-CENTER BUTTON
          Positioned(
            bottom: 40,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: _green,
              foregroundColor: Colors.black,
              onPressed: () {
                _mapController.move(LatLng(widget.initialLat, widget.initialLng), 10.0);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLayerButton(WindyLayer layer, IconData icon, String label) {
    bool isActive = _activeLayer == layer;
    return GestureDetector(
      onTap: () => setState(() => _activeLayer = layer),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? _green : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? Colors.black : Colors.white70, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? _green : Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          )
        ],
      ),
    );
  }
}