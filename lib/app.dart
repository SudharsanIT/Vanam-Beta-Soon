import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/main_navigation/screens/main_nav_screen.dart';

class VanamApp extends ConsumerWidget {
  const VanamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 IDHU THAAN MASTER SWITCH. IDHU MAARUNA APP FULLA MAARUM!
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Vanam',
      debugShowCheckedModeBanner: false,

      themeMode: currentThemeMode, // Dynamic Theme Engine
      theme: AppTheme.lightTheme,  // Light rules
      darkTheme: AppTheme.darkTheme, // Dark rules

      home: const MainNavigationScreen(),
    );
  }
}