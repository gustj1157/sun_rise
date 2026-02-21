import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/spot_data.dart';

class GeneratedMarker {
  final BitmapDescriptor descriptor;
  final Offset anchor;
  GeneratedMarker(this.descriptor, this.anchor);
}

class MarkerGeneratorService {
  final Map<String, GeneratedMarker> _cacheWithLabels = {};
  final Map<String, GeneratedMarker> _cacheNoLabels = {};
  final Map<String, GeneratedMarker> _cacheSelected = {};

  Future<GeneratedMarker> _generateMarker(
    SpotData spot, {
    bool showLabel = true,
    bool isSelected = false,
  }) async {
    final cache = isSelected
        ? _cacheSelected
        : (showLabel ? _cacheWithLabels : _cacheNoLabels);
    if (cache.containsKey(spot.name)) return cache[spot.name]!;

    final double scale = isSelected ? 1.25 : 1.0;
    final double circleRadius = 22.0 * scale;
    const double pinTopPad = 3.0;
    final double tipExtension = 16.0 * scale;
    final double pinHeight = pinTopPad + circleRadius * 2 + tipExtension;
    const double labelFontSize = 11.0;
    const double labelPadH = 6.0;
    const double labelPadV = 3.0;
    const double labelGap = 3.0;

    double labelBgWidth = 0.0;
    double labelBgHeight = 0.0;
    TextPainter? labelPainter;
    bool hasValidLabel = false;

    if (showLabel && !isSelected) {
      labelPainter = TextPainter(
        text: TextSpan(
          text: spot.name,
          style: TextStyle(
            fontSize: labelFontSize,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: kIsWeb ? 'Noto Sans KR' : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      hasValidLabel = labelPainter.width > 1 && labelPainter.height > 1;
      if (hasValidLabel) {
        labelBgWidth = labelPainter.width + labelPadH * 2;
        labelBgHeight = labelPainter.height + labelPadV * 2;
      }
    }

    final double pinWidth = circleRadius * 2 + 6;
    final double glowExtra = circleRadius * 0.8;
    final totalWidth = max(pinWidth + glowExtra * 2, labelBgWidth);
    final totalHeight = hasValidLabel
        ? pinHeight + glowExtra + labelGap + labelBgHeight
        : pinHeight + glowExtra;
    final centerX = totalWidth / 2;
    final circleY = pinTopPad + glowExtra / 2 + circleRadius;
    final tipY = circleY + circleRadius + tipExtension;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, totalWidth, totalHeight),
    );

    final mainColor = _getPinColor(spot.type);
    final darkColor = _getDarkerColor(mainColor);
    final glowColor = _getGlowColor(spot.type);

    // Glow halo behind pin
    canvas.drawCircle(
      Offset(centerX, circleY),
      circleRadius * 1.6,
      Paint()
        ..color = glowColor.withValues(alpha: isSelected ? 0.5 : 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(centerX, tipY - 1), width: 12, height: 5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Teardrop pin
    final pinPath = Path()
      ..moveTo(centerX, tipY)
      ..quadraticBezierTo(centerX + circleRadius * 1.3,
          circleY + circleRadius * 0.6, centerX + circleRadius, circleY)
      ..arcTo(
          Rect.fromCircle(center: Offset(centerX, circleY), radius: circleRadius),
          0,
          -pi,
          false)
      ..quadraticBezierTo(centerX - circleRadius * 1.3,
          circleY + circleRadius * 0.6, centerX, tipY)
      ..close();

    canvas.drawPath(
        pinPath,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(centerX - 4, circleY - 4),
            circleRadius * 2,
            [mainColor, darkColor],
          ));
    canvas.drawPath(
        pinPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);

    // Icon
    final iconData = _getIconData(spot.type);
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 16 * scale,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(centerX - iconPainter.width / 2, circleY - iconPainter.height / 2),
    );

    // Label
    if (hasValidLabel && labelPainter != null) {
      final labelY = tipY + labelGap;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, labelY + labelBgHeight / 2),
            width: labelBgWidth,
            height: labelBgHeight,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color.fromRGBO(30, 30, 30, 0.85),
      );
      labelPainter.paint(
        canvas,
        Offset(centerX - labelPainter.width / 2, labelY + labelPadV),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(totalWidth.ceil(), totalHeight.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor =
        BitmapDescriptor.bytes(bytes, width: totalWidth, height: totalHeight);
    final anchor = Offset(0.5, tipY / totalHeight);
    final result = GeneratedMarker(descriptor, anchor);
    cache[spot.name] = result;
    return result;
  }

  static GeneratedMarker _fallbackMarker(SpotType type) {
    final hue = switch (type) {
      SpotType.sunrise => BitmapDescriptor.hueOrange,
      SpotType.sunset => BitmapDescriptor.hueViolet,
      SpotType.both => BitmapDescriptor.hueYellow,
    };
    return GeneratedMarker(
        BitmapDescriptor.defaultMarkerWithHue(hue), const Offset(0.5, 1.0));
  }

  Color _getPinColor(SpotType type) {
    switch (type) {
      case SpotType.sunrise:
        return const Color(0xFFFF9500);
      case SpotType.sunset:
        return const Color(0xFF8B5CF6);
      case SpotType.both:
        return const Color(0xFFFFD700);
    }
  }

  Color _getGlowColor(SpotType type) {
    switch (type) {
      case SpotType.sunrise:
        return const Color(0xFFFFD700);
      case SpotType.sunset:
        return const Color(0xFFC084FC);
      case SpotType.both:
        return const Color(0xFFFFD700);
    }
  }

  IconData _getIconData(SpotType type) {
    switch (type) {
      case SpotType.sunrise:
        return Icons.wb_sunny_rounded;
      case SpotType.sunset:
        return Icons.nightlight_round;
      case SpotType.both:
        return Icons.star_rounded;
    }
  }

  Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }

  Future<Map<String, GeneratedMarker>> generateAllMarkers(
    List<SpotData> spots, {
    bool showLabels = true,
  }) async {
    final Map<String, GeneratedMarker> markers = {};
    for (final spot in spots) {
      try {
        markers[spot.name] =
            await _generateMarker(spot, showLabel: showLabels);
      } catch (_) {
        markers[spot.name] = _fallbackMarker(spot.type);
      }
    }
    return markers;
  }

  Future<Map<String, GeneratedMarker>> generateSelectedMarkers(
    List<SpotData> spots,
  ) async {
    final Map<String, GeneratedMarker> markers = {};
    for (final spot in spots) {
      try {
        markers[spot.name] =
            await _generateMarker(spot, showLabel: false, isSelected: true);
      } catch (_) {
        markers[spot.name] = _fallbackMarker(spot.type);
      }
    }
    return markers;
  }
}
