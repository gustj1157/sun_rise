import 'dart:math';
import 'package:flutter/material.dart';
import '../models/spot_data.dart';
import '../utils/sun_calculator.dart';

class SunCompass extends StatelessWidget {
  final SpotData spot;

  const SunCompass({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.explore, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${spot.name} 해 방향',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: _CompassPainter(
                  sunriseAzimuth: _calculateSunriseAzimuth(),
                  sunsetAzimuth: _calculateSunsetAzimuth(),
                  currentSunAzimuth: _calculateCurrentSunAzimuth(),
                  isDaytime: spot.isDaytime ?? true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegendRow(Icons.wb_sunny, '일출 방향', Colors.orange, '${_calculateSunriseAzimuth().round()}°'),
            const SizedBox(height: 6),
            _buildLegendRow(Icons.nights_stay, '일몰 방향', Colors.deepPurple, '${_calculateSunsetAzimuth().round()}°'),
            const SizedBox(height: 6),
            _buildLegendRow(Icons.my_location, '현재 태양', Colors.amber, '${_calculateCurrentSunAzimuth().round()}°'),
            const SizedBox(height: 12),
            Text(
              '* 방위각은 북쪽(0°)에서 시계방향으로 측정됩니다',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(IconData icon, String label, Color color, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// Calculate sunrise azimuth (approximate: based on declination)
  double _calculateSunriseAzimuth() {
    final now = DateTime.now().toUtc();
    final decl = SunCalculator.calculateSunDeclination(now) * pi / 180;
    final lat = spot.lat * pi / 180;
    // cos(azimuth) = sin(decl) / cos(lat)
    final cosAz = sin(decl) / cos(lat);
    final az = acos(cosAz.clamp(-1.0, 1.0)) * 180 / pi;
    return (180 - az) % 360; // Sunrise is roughly east
  }

  /// Calculate sunset azimuth
  double _calculateSunsetAzimuth() {
    final now = DateTime.now().toUtc();
    final decl = SunCalculator.calculateSunDeclination(now) * pi / 180;
    final lat = spot.lat * pi / 180;
    final cosAz = sin(decl) / cos(lat);
    final az = acos(cosAz.clamp(-1.0, 1.0)) * 180 / pi;
    return (180 + az) % 360; // Sunset is roughly west
  }

  /// Current sun azimuth (simplified using hour angle)
  double _calculateCurrentSunAzimuth() {
    final now = DateTime.now().toUtc();
    final sunLng = SunCalculator.calculateSunLongitude(now);
    final sunLat = SunCalculator.calculateSunDeclination(now);

    // Calculate bearing from spot to sub-solar point
    final lat1 = spot.lat * pi / 180;
    final lat2 = sunLat * pi / 180;
    final dLng = (sunLng - spot.lng) * pi / 180;

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }
}

class _CompassPainter extends CustomPainter {
  final double sunriseAzimuth;
  final double sunsetAzimuth;
  final double currentSunAzimuth;
  final bool isDaytime;

  _CompassPainter({
    required this.sunriseAzimuth,
    required this.sunsetAzimuth,
    required this.currentSunAzimuth,
    required this.isDaytime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF0D1B2A));
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Inner grid circles
    canvas.drawCircle(center, radius * 0.66, Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);
    canvas.drawCircle(center, radius * 0.33, Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);

    // Cardinal directions
    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 - pi / 2; // N is top
      final x = center.dx + (radius + 2) * cos(angle);
      final y = center.dy + (radius + 2) * sin(angle);

      final tp = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: i == 0 ? Colors.red[300] : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // Tick marks
    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * pi / 180 - pi / 2;
      final inner = i % 9 == 0 ? radius * 0.85 : radius * 0.92;
      final outer = radius * 0.98;
      canvas.drawLine(
        Offset(center.dx + inner * cos(angle), center.dy + inner * sin(angle)),
        Offset(center.dx + outer * cos(angle), center.dy + outer * sin(angle)),
        Paint()
          ..color = i % 9 == 0 ? Colors.white30 : Colors.white12
          ..strokeWidth = i % 9 == 0 ? 1.5 : 0.8,
      );
    }

    // Sunrise direction (orange wedge)
    _drawSunIndicator(canvas, center, radius * 0.75, sunriseAzimuth, Colors.orange, '☀');

    // Sunset direction (purple wedge)
    _drawSunIndicator(canvas, center, radius * 0.75, sunsetAzimuth, Colors.deepPurple, '🌙');

    // Current sun position (amber dot)
    if (isDaytime) {
      final angle = (currentSunAzimuth - 90) * pi / 180;
      final sunPos = Offset(
        center.dx + radius * 0.55 * cos(angle),
        center.dy + radius * 0.55 * sin(angle),
      );
      canvas.drawCircle(sunPos, 8, Paint()..color = Colors.amber);
      canvas.drawCircle(sunPos, 8, Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.white24);
  }

  void _drawSunIndicator(Canvas canvas, Offset center, double radius, double azimuth, Color color, String emoji) {
    final angle = (azimuth - 90) * pi / 180;
    final endPos = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    // Dashed line from center
    canvas.drawLine(center, endPos, Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5);

    // Indicator circle
    canvas.drawCircle(endPos, 6, Paint()..color = color.withValues(alpha: 0.8));
    canvas.drawCircle(endPos, 6, Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.sunriseAzimuth != sunriseAzimuth ||
      old.sunsetAzimuth != sunsetAzimuth ||
      old.currentSunAzimuth != currentSunAzimuth;
}
