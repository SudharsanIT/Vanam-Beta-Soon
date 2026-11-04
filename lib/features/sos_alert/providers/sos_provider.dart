import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/aws_api_service.dart';
import '../../../core/utils/location_helper.dart';

final sosProvider = StateNotifierProvider<SOSNotifier, bool>((ref) {
  return SOSNotifier();
});

class SOSNotifier extends StateNotifier<bool> {
  SOSNotifier() : super(false); // false means not currently sending

  /// Triggers an emergency SOS with current GPS coordinates
  Future<bool> triggerEmergencySOS(String type) async {
    state = true; // Loading state while fetching location and sending
    try {
      // 1. Get current GPS location instantly
      final position = await LocationHelper.getCurrentLocation();

      final double lat = position?.latitude ?? 11.1271; // Fallback center
      final double lng = position?.longitude ?? 78.6569;

      // 2. Push alert to Firebase Cloud
      await FirebaseService.triggerSOS(
        lat: lat,
        lng: lng,
        type: type,
      );

      state = false;
      return true;
    } catch (e) {
      state = false;
      return false;
    }
  }
}