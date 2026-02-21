import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/day_night_painter.dart';
import '../providers/sun_status_provider.dart';

class DayNightOverlay extends StatelessWidget {
  const DayNightOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SunStatusProvider>(
      builder: (context, provider, _) {
        return IgnorePointer(
          child: CustomPaint(
            painter: DayNightPainter(
              sunLongitude: provider.sunLongitude,
              sunLatitude: provider.sunLatitude,
              visibleBounds: provider.visibleBounds,
              period: provider.currentPeriod,
              isSimulating: provider.isSimulating,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}
