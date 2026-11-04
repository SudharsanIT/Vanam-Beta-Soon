import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

/// Handles all GPS operations. Completely offline capable.
class LocationHelper {
  LocationHelper._();

  /// Requests permission and gets the current offline GPS coordinate.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Check if GPS is turned on in the phone
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Location services are disabled.', name: 'Vanam.GPS');
        return null; // Handle in UI to ask user to turn on GPS
      }

      // 2. Check and request permissions securely
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          developer.log('Location permissions denied by user.', name: 'Vanam.GPS');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('Location permissions permanently denied.', name: 'Vanam.GPS');
        return null;
      }

      // 3. Fetch high-accuracy location from GPS satellites directly
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // High accuracy for forest navigation
      );
    } catch (e) {
      developer.log('Error fetching location', error: e, name: 'Vanam.GPS');
      return null;
    }
  }

  /// Live Stream of user's location.
  /// Used to move the 'Blue Dot' on the offline map continuously.
  static Stream<Position> getLiveLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update stream only if user moves 5 meters (Saves Battery)
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculates distance between two GPS coordinates in meters.
  /// Used for "Geofencing" (triggering map auto-download when nearing the forest).
  static double calculateDistanceInMeters(
      double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}