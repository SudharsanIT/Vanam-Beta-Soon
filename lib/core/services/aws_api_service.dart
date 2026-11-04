import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as developer;
import '../utils/device_id_util.dart';

/// Centralized service for Firebase Realtime Database.
/// Handles syncing live alerts, eco-market data, and background user registration.
class FirebaseService {
  FirebaseService._();

  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Database Reference Nodes
  static final DatabaseReference _usersRef = _db.ref().child('users');
  static final DatabaseReference _alertsRef = _db.ref().child('danger_alerts');
  static final DatabaseReference _marketRef = _db.ref().child('eco_market');

  /// Silently registers or updates the user in the background using their Device ID.
  /// This implements the "Zero-Touch Login" architecture.
  static Future<void> registerAnonymousUser() async {
    try {
      final String deviceId = await DeviceIdUtil.getUniqueDeviceId();

      // We don't overwrite existing data, we just update the 'last_active' timestamp.
      // This ensures if they delete and reinstall, their old linked data remains intact.
      await _usersRef.child(deviceId).update({
        'last_active': ServerValue.timestamp,
        'app_version': '1.0.0', // Helps admins know which version the user is on
        'status': 'active',
      });

      developer.log('Anonymous User Sync complete. ID: $deviceId', name: 'Vanam.Firebase');
    } catch (e) {
      developer.log('Failed to register anonymous user', error: e, name: 'Vanam.Firebase');
      // No throw here. If they are completely offline on first boot, it fails silently
      // and tries again next time they open the app with internet.
    }
  }

  /// Listens to emergency alerts triggered by the Admin App.
  /// Yields real-time updates directly to the UI without needing to pull.
  static Stream<DatabaseEvent> listenToDangerAlerts() {
    // Only listen to active alerts
    return _alertsRef.orderByChild('is_active').equalTo(true).onValue;
  }

  /// Sends an SOS alert to the Admin dashboard.
  static Future<void> triggerSOS({
    required double lat,
    required double lng,
    required String type,
  }) async {
    try {
      final String deviceId = await DeviceIdUtil.getUniqueDeviceId();
      final String alertId = _alertsRef.push().key ?? DateTime.now().millisecondsSinceEpoch.toString();

      await _alertsRef.child(alertId).set({
        'user_id': deviceId,
        'latitude': lat,
        'longitude': lng,
        'type': type, // e.g., 'animal_attack', 'medical_emergency', 'forest_fire'
        'timestamp': ServerValue.timestamp,
        'is_active': true,
      });

      developer.log('SOS Alert successfully sent to Admin Cloud!', name: 'Vanam.Emergency');
    } catch (e) {
      developer.log('Critical failure sending SOS', error: e, name: 'Vanam.Emergency');
      throw Exception('Failed to send SOS. Check network connection.');
    }
  }
}
