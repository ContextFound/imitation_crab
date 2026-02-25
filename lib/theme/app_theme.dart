import 'package:flutter/material.dart';

/// Crab/research aesthetic theme for imitationCrab.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF2D5A27); // Deep green (crab shell)
  static const Color secondary = Color(0xFF8B4513); // Sienna (warm undertone)
  static const Color surface = Color(0xFF1A1D21);
  static const Color surfaceVariant = Color(0xFF252830);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFE8E6E3);
  static const Color onSurfaceVariant = Color(0xFFB0AEAB);
  static const Color error = Color(0xFFCF6679);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: onPrimary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFFF5F5F3),
        error: error,
        onPrimary: onPrimary,
        onSurface: const Color(0xFF1A1D21),
        onSurfaceVariant: const Color(0xFF5A5D60),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F3),
        foregroundColor: Color(0xFF1A1D21),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
