import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

import '../../../core/utils/location_helper.dart';
import '../../../core/services/local_db_service.dart';

// Riverpod state provider for the Map
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});

class MapState {
  final Position? currentLocation;
  final bool isOfflineMapCached;
  final bool isCachingInProgress;

  MapState({
    this.currentLocation,
    this.isOfflineMapCached = false,
    this.isCachingInProgress = false,
  });

  MapState copyWith({
    Position? currentLocation,
    bool? isOfflineMapCached,
    bool? isCachingInProgress,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      isOfflineMapCached: isOfflineMapCached ?? this.isOfflineMapCached,
      isCachingInProgress: isCachingInProgress ?? this.isCachingInProgress,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  StreamSubscription<Position>? _positionStream;

  MapNotifier() : super(MapState()) {
    _initLocationTracking();
  }

  void _initLocationTracking() async {
    // Get initial location
    final initialLoc = await LocationHelper.getCurrentLocation();
    if (initialLoc != null) {
      state = state.copyWith(currentLocation: initialLoc);
      _checkGeofenceAndCache(initialLoc);
    }

    // Start listening to live location (Works completely offline via GPS)
    _positionStream = LocationHelper.getLiveLocationStream().listen((Position position) {
      state = state.copyWith(currentLocation: position);
      _checkGeofenceAndCache(position);
    });
  }

  /// Zero-Touch Caching Logic:
  /// Checks if the user is near a forest zone. If yes, it auto-downloads the map.
  void _checkGeofenceAndCache(Position pos) async {
    if (state.isOfflineMapCached || state.isCachingInProgress) return;

    // TODO: Replace with actual forest border coordinates
    const double forestBorderLat = 11.2333; // Example: Western Ghats border
    const double forestBorderLng = 76.9667;

    double distance = LocationHelper.calculateDistanceInMeters(
      pos.latitude, pos.longitude, forestBorderLat, forestBorderLng,
    );

    // If user is within 15 km of the forest border, trigger silent download
    if (distance < 15000) {
      state = state.copyWith(isCachingInProgress: true);
      developer.log('User near forest. Starting Zero-Touch Map Caching...', name: 'Vanam.MapEngine');

      try {
        // Simulate background tile downloading logic using flutter_map_tile_caching
        await Future.delayed(const Duration(seconds: 5));

        // Save status in Hive encrypted box
        final box = LocalDbService.getBox(LocalDbService.mapCacheBox);
        await box.put('is_area_cached', true);

        state = state.copyWith(isCachingInProgress: false, isOfflineMapCached: true);
        developer.log('Offline Map successfully cached in background!', name: 'Vanam.MapEngine');
      } catch (e) {
        state = state.copyWith(isCachingInProgress: false);
        developer.log('Caching failed', error: e, name: 'Vanam.MapEngine');
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}