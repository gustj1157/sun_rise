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

  Future<GeneratedMarker> _generateMarker(SpotData spot, {bool showLabel = true}) async {
    final cache = showLabel ? _cacheWithLabels : _cacheNoLabels;
    if (cache.containsKey(spot.name)) return cache[spot.name]!;

    const double circleRadius = 15.0;
    const double pinTopPad = 3.0;
    const double tipExtension = 14.0;
    const double pinHeight = pinTopPad + circleRadius * 2 + tipExtension;
    const double labelFontSize = 11.0;
    const double labelPadH = 6.0;
    const double labelPadV = 3.0;
    const double labelGap = 3.0;

    double labelBgWidth = 0.0;
    double labelBgHeight = 0.0;
    TextPainter? labelPainter;
    bool hasValidLabel = false;

    if (showLabel) {
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

    const double pinWidth = circleRadius * 2 + 6;
    final totalWidth = max(pinWidth, labelBgWidth);
    final totalHeight = hasValidLabel
        ? pinHeight + labelGap + labelBgHeight
        : pinHeight;
    final centerX = totalWidth / 2;
    final circleY = pinTopPad + circleRadius;
    final tipY = pinHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, totalWidth, totalHeight),
    );

    final mainColor = _getPinColor(spot.type);
    final darkColor = _getDarkerColor(mainColor);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, tipY - 1), width: 10, height: 4),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Teardrop pin
    final pinPath = Path()
      ..moveTo(centerX, tipY)
      ..quadraticBezierTo(centerX + circleRadius * 1.3, circleY + circleRadius * 0.6, centerX + circleRadius, circleY)
      ..arcTo(Rect.fromCircle(center: Offset(centerX, circleY), radius: circleRadius), 0, -pi, false)
      ..quadraticBezierTo(centerX - circleRadius * 1.3, circleY + circleRadius * 0.6, centerX, tipY)
      ..close();

    canvas.drawPath(pinPath, Paint()..shader = ui.Gradient.radial(
      Offset(centerX - 4, circleY - 4), circleRadius * 2, [mainColor, darkColor],
    ));
    canvas.drawPath(pinPath, Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Icon
    final iconData = spot.typeIcon;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(fontSize: 14, fontFamily: iconData.fontFamily, package: iconData.fontPackage, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(centerX - iconPainter.width / 2, circleY - iconPainter.height / 2));

    // Label
    if (hasValidLabel && labelPainter != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(centerX, pinHeight + labelGap + labelBgHeight / 2), width: labelBgWidth, height: labelBgHeight),
          const Radius.circular(4),
        ),
        Paint()..color = const Color.fromRGBO(30, 30, 30, 0.85),
      );
      labelPainter.paint(canvas, Offset(centerX - labelPainter.width / 2, pinHeight + labelGap + labelPadV));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(totalWidth.ceil(), totalHeight.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(bytes, width: totalWidth, height: totalHeight);
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
    return GeneratedMarker(BitmapDescriptor.defaultMarkerWithHue(hue), const Offset(0.5, 1.0));
  }

  Color _getPinColor(SpotType type) {
    switch (type) {
      case SpotType.sunrise: return const Color(0xFFFF6D00);
      case SpotType.sunset: return const Color(0xFF7C4DFF);
      case SpotType.both: return const Color(0xFFFFC107);
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
        markers[spot.name] = await _generateMarker(spot, showLabel: showLabels);
      } catch (_) {
        markers[spot.name] = _fallbackMarker(spot.type);
      }
    }
    return markers;
  }
}
