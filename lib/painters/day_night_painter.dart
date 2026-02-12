import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/sun_calculator.dart';

class DayNightPainter extends CustomPainter {
  final double sunLongitude;
  final double sunLatitude;
  final LatLngBounds? visibleBounds;

  static const int _cols = 40;
  static const int _rows = 20;

  DayNightPainter({
    required this.sunLongitude,
    required this.sunLatitude,
    this.visibleBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (visibleBounds == null) return;

    final swLat = visibleBounds!.southwest.latitude;
    final neLat = visibleBounds!.northeast.latitude;
    var swLng = visibleBounds!.southwest.longitude;
    var neLng = visibleBounds!.northeast.longitude;
    if (neLng < swLng) neLng += 360;

    // Quick daylight check — skip rendering if entire viewport is bright
    final checkPoints = [
      [swLat, swLng], [swLat, neLng],
      [neLat, swLng], [neLat, neLng],
      [(swLat + neLat) / 2, (swLng + neLng) / 2],
      [swLat, (swLng + neLng) / 2],
      [neLat, (swLng + neLng) / 2],
      [(swLat + neLat) / 2, swLng],
      [(swLat + neLat) / 2, neLng],
    ];
    bool allDay = true;
    for (final p in checkPoints) {
      var lng = p[1];
      if (lng > 180) lng -= 360;
      if (SunCalculator.getDarknessAtPointFast(p[0], lng, sunLongitude, sunLatitude) > 0) {
        allDay = false;
        break;
      }
    }
    if (allDay) return;

    // Draw vertical gradient strips with overlap for seamless blending
    final stripWidth = size.width / _cols;
    final overlap = 2.0;

    for (int col = 0; col < _cols; col++) {
      final tx = (col + 0.5) / _cols;
      var lng = swLng + tx * (neLng - swLng);
      if (lng > 180) lng -= 360;

      final sunSide = _getSunSide(lng);

      final colors = <Color>[];
      final stops = <double>[];

      for (int row = 0; row <= _rows; row++) {
        final ty = row / _rows;
        final lat = neLat - ty * (neLat - swLat);

        final darkness = SunCalculator.getDarknessAtPointFast(
          lat, lng, sunLongitude, sunLatitude,
        );
        colors.add(_getColor(darkness, sunSide));
        stops.add(ty);
      }

      final left = (col * stripWidth - overlap).clamp(0.0, size.width);
      final right = ((col + 1) * stripWidth + overlap).clamp(0.0, size.width);
      final rect = Rect.fromLTRB(left, 0, right, size.height);

      final gradient = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        colors,
        stops,
      );
      canvas.drawRect(rect, Paint()..shader = gradient);
    }
  }

  /// Returns -1.0 (sunrise/morning side) to 1.0 (sunset/evening side).
  double _getSunSide(double lng) {
    var diff = lng - sunLongitude;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return (diff / 180).clamp(-1.0, 1.0);
  }

  Color _getColor(double darkness, double sunSide) {
    if (darkness <= 0.0) return Colors.transparent;

    // Full night — dark navy
    if (darkness >= 1.0) return const Color.fromRGBO(10, 10, 50, 0.55);

    // Blend factor: 0 = sunrise side, 1 = sunset side
    final sunsetBlend = ((sunSide + 1) / 2).clamp(0.0, 1.0);

    final sunriseColor = _getSunriseColor(darkness);
    final sunsetColor = _getSunsetColor(darkness);
    return Color.lerp(sunriseColor, sunsetColor, sunsetBlend)!;
  }

  /// Golden/amber tones for the sunrise (dawn) side.
  Color _getSunriseColor(double darkness) {
    if (darkness < 0.35) {
      final t = darkness / 0.35;
      return Color.fromRGBO(
        255,
        (210 - t * 30).toInt(),
        (120 - t * 50).toInt(),
        t * 0.22,
      );
    } else if (darkness < 0.65) {
      final t = (darkness - 0.35) / 0.3;
      return Color.fromRGBO(
        (255 - t * 40).toInt(),
        (180 - t * 60).toInt(),
        (70 - t * 30).toInt(),
        0.22 + t * 0.12,
      );
    } else {
      final t = (darkness - 0.65) / 0.35;
      return Color.fromRGBO(
        (215 - t * 205).toInt(),
        (120 - t * 110).toInt(),
        (40 + t * 10).toInt(),
        0.34 + t * 0.21,
      );
    }
  }

  /// Purple/violet tones for the sunset (dusk) side.
  Color _getSunsetColor(double darkness) {
    if (darkness < 0.35) {
      final t = darkness / 0.35;
      return Color.fromRGBO(
        (180 + t * 40).toInt(),
        (80 - t * 30).toInt(),
        (180 + t * 40).toInt(),
        t * 0.22,
      );
    } else if (darkness < 0.65) {
      final t = (darkness - 0.35) / 0.3;
      return Color.fromRGBO(
        (220 - t * 60).toInt(),
        (50 - t * 20).toInt(),
        (220 - t * 30).toInt(),
        0.22 + t * 0.12,
      );
    } else {
      final t = (darkness - 0.65) / 0.35;
      return Color.fromRGBO(
        (160 - t * 150).toInt(),
        (30 - t * 20).toInt(),
        (190 - t * 140).toInt(),
        0.34 + t * 0.21,
      );
    }
  }

  @override
  bool shouldRepaint(DayNightPainter oldDelegate) {
    return oldDelegate.sunLongitude != sunLongitude ||
        oldDelegate.sunLatitude != sunLatitude ||
        oldDelegate.visibleBounds != visibleBounds;
  }
}
