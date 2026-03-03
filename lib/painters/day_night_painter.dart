import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/kst_time_helper.dart';
import '../utils/sun_calculator.dart';

class DayNightPainter extends CustomPainter {
  final double sunLongitude;
  final double sunLatitude;
  final LatLngBounds? visibleBounds;
  final SunPeriod period;
  final bool isSimulating;
  final double glowAnimation;

  DayNightPainter({
    required this.sunLongitude,
    required this.sunLatitude,
    this.visibleBounds,
    required this.period,
    this.isSimulating = false,
    this.glowAnimation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (visibleBounds == null) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (isSimulating) {
      _paintSimulationMode(canvas, rect, size);
    } else {
      _paintKstMode(canvas, rect, size);
    }
  }

  // ── KST 시간 기반 모드 ──────────────────────────────────
  void _paintKstMode(Canvas canvas, Rect rect, Size size) {
    switch (period) {
      case SunPeriod.sunrise:
        _paintKstSunrise(canvas, rect, size);
        _paintEdgeGlow(canvas, size, isSunrise: true);
        break;
      case SunPeriod.daytime:
        _paintKstDaytime(canvas, rect);
        break;
      case SunPeriod.sunset:
        _paintKstSunset(canvas, rect, size);
        _paintEdgeGlow(canvas, size, isSunrise: false);
        break;
      case SunPeriod.night:
        _paintKstNight(canvas, rect, size);
        break;
    }
  }

  void _paintKstSunrise(Canvas canvas, Rect rect, Size size) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [
            const Color(0xFFFFB6C1).withValues(alpha: 0.25),
            const Color(0xFFFFCC80).withValues(alpha: 0.25),
            const Color(0xFF87CEEB).withValues(alpha: 0.20),
          ],
          [0.0, 0.5, 1.0],
        ),
    );
    // East glow
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width, size.height * 0.5),
          size.width * 0.7,
          [
            const Color(0xFFFFD700).withValues(alpha: 0.2),
            Colors.transparent,
          ],
          [0.0, 1.0],
        ),
    );
  }

  void _paintKstDaytime(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF87CEEB).withValues(alpha: 0.1),
    );
  }

  void _paintKstSunset(Canvas canvas, Rect rect, Size size) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [
            const Color(0xFF8B5CF6).withValues(alpha: 0.30),
            const Color(0xFFFF6B6B).withValues(alpha: 0.28),
            const Color(0xFFFF9500).withValues(alpha: 0.30),
          ],
          [0.0, 0.5, 1.0],
        ),
    );
    // West glow
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(0, size.height * 0.5),
          size.width * 0.7,
          [
            const Color(0xFFFFB347).withValues(alpha: 0.25),
            Colors.transparent,
          ],
          [0.0, 1.0],
        ),
    );
    // East darker
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.6, 0),
          Offset(size.width, 0),
          [Colors.transparent, const Color(0xFF0d1b2a).withValues(alpha: 0.2)],
        ),
    );
  }

  void _paintKstNight(Canvas canvas, Rect rect, Size size) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [
            const Color(0xFF0d1b2a).withValues(alpha: 0.4),
            const Color(0xFF2d1b4e).withValues(alpha: 0.35),
          ],
          [0.0, 1.0],
        ),
    );
  }

  // ── Edge glow 애니메이션 (일출/일몰 다가오는 중) ──────────
  void _paintEdgeGlow(Canvas canvas, Size size, {required bool isSunrise}) {
    final pulseAlpha = 0.08 + glowAnimation * 0.14; // 0.08 ~ 0.22
    final pulseRadius = size.width * (0.5 + glowAnimation * 0.25); // 50%~75%

    if (isSunrise) {
      // 동쪽 가장자리에서 빛이 번지는 효과
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width + size.width * 0.05, size.height * 0.4),
            pulseRadius,
            [
              Color(0xFFFFD700).withValues(alpha: pulseAlpha),
              Color(0xFFFF9500).withValues(alpha: pulseAlpha * 0.5),
              Colors.transparent,
            ],
            [0.0, 0.5, 1.0],
          ),
      );
      // 상단 핑크빛 번짐
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width * 0.8, 0),
            size.height * (0.4 + glowAnimation * 0.15),
            [
              Color(0xFFFFB6C1).withValues(alpha: pulseAlpha * 0.6),
              Colors.transparent,
            ],
            [0.0, 1.0],
          ),
      );
    } else {
      // 서쪽 가장자리에서 빛이 번지는 효과
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(-size.width * 0.05, size.height * 0.4),
            pulseRadius,
            [
              Color(0xFFFF6B6B).withValues(alpha: pulseAlpha),
              Color(0xFF8B5CF6).withValues(alpha: pulseAlpha * 0.5),
              Colors.transparent,
            ],
            [0.0, 0.5, 1.0],
          ),
      );
      // 하단 보라빛 번짐
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width * 0.2, size.height),
            size.height * (0.4 + glowAnimation * 0.15),
            [
              Color(0xFFA855F7).withValues(alpha: pulseAlpha * 0.6),
              Colors.transparent,
            ],
            [0.0, 1.0],
          ),
      );
    }
  }

  // ── 시뮬레이션(타임랩스) 모드 ─────────────────────────
  void _paintSimulationMode(Canvas canvas, Rect rect, Size size) {
    final centerLat =
        (visibleBounds!.northeast.latitude + visibleBounds!.southwest.latitude) / 2;
    final centerLng =
        (visibleBounds!.northeast.longitude + visibleBounds!.southwest.longitude) / 2;

    final darkness = SunCalculator.getDarknessAtPointFast(
      centerLat, centerLng, sunLongitude, sunLatitude,
    );

    var sunDiff = centerLng - sunLongitude;
    if (sunDiff > 180) sunDiff -= 360;
    if (sunDiff < -180) sunDiff += 360;

    if (darkness <= 0.05) {
      _paintKstDaytime(canvas, rect);
    } else if (darkness >= 0.95) {
      _paintKstNight(canvas, rect, size);
    } else if (sunDiff > 0) {
      final opacity = (0.4 * darkness).clamp(0.05, 0.4);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(size.width / 2, 0),
            Offset(size.width / 2, size.height),
            [
              Color(0xFF8B5CF6).withValues(alpha: opacity),
              Color(0xFFFF6B6B).withValues(alpha: opacity),
              Color(0xFFFF9500).withValues(alpha: opacity),
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    } else {
      final opacity = (0.4 * darkness).clamp(0.05, 0.4);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(size.width / 2, 0),
            Offset(size.width / 2, size.height),
            [
              Color(0xFFFFB6C1).withValues(alpha: opacity),
              Color(0xFFFFCC80).withValues(alpha: opacity),
              Color(0xFF87CEEB).withValues(alpha: opacity),
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(DayNightPainter oldDelegate) {
    return oldDelegate.sunLongitude != sunLongitude ||
        oldDelegate.sunLatitude != sunLatitude ||
        oldDelegate.visibleBounds != visibleBounds ||
        oldDelegate.period != period ||
        oldDelegate.isSimulating != isSimulating ||
        oldDelegate.glowAnimation != glowAnimation;
  }
}
