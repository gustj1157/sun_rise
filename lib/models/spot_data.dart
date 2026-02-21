import 'package:flutter/material.dart';

enum SpotType { sunrise, sunset, both }

class SpotData {
  final String name;
  final String description;
  final double lat;
  final double lng;
  final SpotType type;
  final String imageUrl;
  final List<String> photoUrls;
  final List<String> tags;
  final String? shootingTip;
  final String? compositionTip;

  DateTime? sunriseTime;
  DateTime? sunsetTime;
  bool? isDaytime;

  SpotData({
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.type,
    this.imageUrl = '',
    this.photoUrls = const [],
    this.tags = const [],
    this.shootingTip,
    this.compositionTip,
    this.sunriseTime,
    this.sunsetTime,
    this.isDaytime,
  });

  Color get typeColor {
    switch (type) {
      case SpotType.sunrise:
        return const Color(0xFFFF9500);
      case SpotType.sunset:
        return const Color(0xFF8B5CF6);
      case SpotType.both:
        return const Color(0xFFFFD700);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case SpotType.sunrise:
        return Icons.wb_sunny;
      case SpotType.sunset:
        return Icons.nights_stay;
      case SpotType.both:
        return Icons.brightness_6;
    }
  }

  /// CORS-friendly reliable photo URLs (picsum.photos).
  /// Used as display source since external blog URLs are often dead.
  List<String> get displayPhotoUrls {
    final seed = name.hashCode.abs();
    return List.generate(3, (i) => 'https://picsum.photos/seed/${seed}p$i/800/500');
  }
}
