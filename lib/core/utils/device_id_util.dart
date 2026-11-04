import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

/// Utility class to generate and retrieve a unique, persistent Device ID.
/// This acts as the "Zero-Touch Login" token for the Vanam User App.
class DeviceIdUtil {
  DeviceIdUtil._();

  static const _storage = FlutterSecureStorage();
  static const String _deviceIdKey = 'vanam_secure_device_id';

  /// Gets the hardware ID or falls back to a secure UUID if hardware ID is unavailable.
  static Future<String> getUniqueDeviceId() async {
    try {
      // 1. Check if we already have a generated ID stored securely
      String? secureId = await _storage.read(key: _deviceIdKey);
      if (secureId != null && secureId.isNotEmpty) {
        return secureId;
      }

      // 2. Fetch Hardware specific ID
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? hardwareId;

      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        hardwareId = androidInfo.id; // Unique Android hardware ID
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        hardwareId = iosInfo.identifierForVendor; // Unique iOS vendor ID
      }

      // 3. Fallback to UUID if hardware ID is null (very rare)
      if (hardwareId == null || hardwareId.isEmpty) {
        hardwareId = const Uuid().v4();
      }

      // 4. Save securely for future sessions even if app is updated
      await _storage.write(key: _deviceIdKey, value: hardwareId);

      developer.log('New Device ID registered: $hardwareId', name: 'Vanam.Security');
      return hardwareId;

    } catch (e) {
      developer.log('Error fetching device ID', error: e, name: 'Vanam.Security');
      // Extreme fallback to ensure app doesn't crash
      return const Uuid().v4();
    }
  }
}