import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppTheme {
  static const CameraPosition kKoreaCenter = CameraPosition(
    target: LatLng(36.5, 127.5),
    zoom: 7.0,
  );

  static const Color primaryOrange = Color(0xFFFF6D00);
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color darkBackground = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: primaryOrange,
          secondary: primaryPurple,
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
            borderRadius: BorderRadius.all(Radius.circular(12)),
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
