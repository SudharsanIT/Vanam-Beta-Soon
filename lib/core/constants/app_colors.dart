import 'package:flutter/material.dart';

/// Defines all the colors used in the Vanam App.
/// Centralizing colors ensures consistency and easy rebranding.
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Colors (Nature & Trust)
  static const Color primaryGreen = Color(0xFF2A5C38); // Deep Forest Green
  static const Color lightGreen = Color(0xFFE8F2EA); // Soft Green for cards/chips

  // Background & Surface Colors (Minimalist look)
  static const Color backgroundWhite = Color(0xFFF9FAFB); // Off-White Background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure White for Cards

  // Alert & Danger Colors (Emergencies)
  static const Color dangerRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFF9800);

  // Text Colors (Readability)
  static const Color textPrimary = Color(0xFF1C1C1E); // Dark Charcoal (Not pure black)
  static const Color textSecondary = Color(0xFF757575); // Subtle Grey

  // Border & Divider
  static const Color borderLight = Color(0xFFE0E0E0);
}