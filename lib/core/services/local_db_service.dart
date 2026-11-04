import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

/// Manages the highly secure, offline-first local database for Vanam App.
class LocalDbService {
  LocalDbService._();

  static const _secureStorage = FlutterSecureStorage();
  static const String _encryptionKeyIdentifier = 'vanam_hive_encryption_key';

  // Hive Box Names
  static const String mapCacheBox = 'offline_map_cache';
  static const String survivalGuideBox = 'survival_guides';
  static const String alertZoneBox = 'danger_alert_zones';

  /// Initializes encrypted Hive boxes. Must be called after Hive.initFlutter()
  static Future<void> initEncryptedBoxes() async {
    try {
      // 1. Get or Generate AES-256 Encryption Key
      String? storedKey = await _secureStorage.read(key: _encryptionKeyIdentifier);
      List<int> encryptionKey;

      if (storedKey == null) {
        // Generate a new secure key if it doesn't exist
        final key = Hive.generateSecureKey();
        await _secureStorage.write(
          key: _encryptionKeyIdentifier,
          value: base64UrlEncode(key),
        );
        encryptionKey = key;
        developer.log('Generated new AES-256 key for local DB', name: 'Vanam.Database');
      } else {
        encryptionKey = base64Url.decode(storedKey);
      }

      final cipher = HiveAesCipher(encryptionKey);

      // 2. Open all necessary boxes with the cipher
      await Future.wait([
        Hive.openBox(mapCacheBox, encryptionCipher: cipher),
        Hive.openBox(survivalGuideBox, encryptionCipher: cipher),
        Hive.openBox(alertZoneBox, encryptionCipher: cipher),
      ]);

      developer.log('Encrypted offline boxes opened successfully.', name: 'Vanam.Database');
    } catch (e) {
      developer.log('Critical Error opening encrypted Hive boxes', error: e, name: 'Vanam.Database');
      throw Exception('Failed to initialize secure offline storage');
    }
  }

  /// Helper to get a specific box easily from anywhere in the app
  static Box getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open. Ensure initEncryptedBoxes() was called.');
    }
    return Hive.box(boxName);
  }

  /// Gracefully clears cache memory (Useful for the Auto-cleanup feature when leaving the forest)
  static Future<void> clearMapCache() async {
    final box = getBox(mapCacheBox);
    await box.clear();
    developer.log('Map cache cleared automatically to save storage.', name: 'Vanam.StorageSaver');
  }
}