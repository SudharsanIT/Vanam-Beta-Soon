import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Internal imports
import 'app.dart';

/// Top-level enterprise entry point for Vanam App (AWS & Offline Architecture).
void main() async {
  runZonedGuarded(() async {
    // 1. Initialize Flutter Engine
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Lock Orientation (Survival apps shouldn't flip unnecessarily)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 3. Initialize Local Offline Database (Hive)
    try {
      await Hive.initFlutter();
      developer.log('Hive Local Storage initialized successfully.', name: 'Vanam.Database');
    } catch (e, stackTrace) {
      developer.log(
        'Hive initialization failed. Storage might be restricted.',
        error: e,
        stackTrace: stackTrace,
        name: 'Vanam.Database',
      );
    }

    // 4. Boot Application
    // Wrapped in ProviderScope to enable Riverpod state management.
    developer.log('Booting Vanam App...', name: 'Vanam.Core');
    runApp(
      const ProviderScope(
        child: VanamApp(),
      ),
    );
  }, (error, stackTrace) {
    // Global Error Catcher
    developer.log(
      'FATAL EXCEPTION CAUGHT BY ZONED GUARD',
      error: error,
      stackTrace: stackTrace,
      name: 'Vanam.Crashlytics',
    );
  });
}