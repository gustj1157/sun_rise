import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppTheme {
  static const CameraPosition kKoreaCenter = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 11.0,
  );

  // Legacy
  static const Color primaryOrange = Color(0xFFFF6D00);
  static const Color primaryPurple = Color(0xFF7C4DFF);

  // Sunrise palette
  static const Color sunriseOrange = Color(0xFFFF9500);
  static const Color sunriseLight = Color(0xFFFFB347);
  static const Color sunriseGold = Color(0xFFFFD700);

  // Sunset palette
  static const Color sunsetPurple = Color(0xFF8B5CF6);
  static const Color sunsetMedium = Color(0xFFA855F7);
  static const Color sunsetLight = Color(0xFFC084FC);

  // Accent
  static const Color accentPink = Color(0xFFFF6B6B);

  // Surfaces
  static const Color darkBackground = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: sunriseOrange,
          secondary: sunsetPurple,
          surface: surfaceDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceDark,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: cardDark,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardDark,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}
