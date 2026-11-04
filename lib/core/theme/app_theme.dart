import 'package:flutter/material.dart';

class AppTheme {
  // Namma App-oda common green color
  static const primaryGreen = Color(0xFF10B981);

  // ============================================
  // 🌙 DARK THEME (Forest Night)
  // ============================================
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1411), // Dark App Background
    primaryColor: primaryGreen,
    cardColor: const Color(0xFF1A221D), // Dark Cards/Containers
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      surface: Color(0xFF1A221D), // Surface color for cards
      onSurface: Colors.white, // Text color on top of surface
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F1411),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70), // Subtitles
      bodySmall: TextStyle(color: Colors.white54),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  );

  // ============================================
  // ☀️ LIGHT THEME (Daylight Forest)
  // ============================================
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Light Gray/White Background
    primaryColor: primaryGreen,
    cardColor: Colors.white, // White Cards
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      surface: Colors.white,
      onSurface: Color(0xFF1E293B), // Dark text on top of white cards
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FAFC),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1E293B)), // Dark Text
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
  );
}