import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/day_night_painter.dart';
import '../providers/sun_status_provider.dart';
import '../utils/kst_time_helper.dart';

class DayNightOverlay extends StatefulWidget {
  const DayNightOverlay({super.key});

  @override
  State<DayNightOverlay> createState() => _DayNightOverlayState();
}

class _DayNightOverlayState extends State<DayNightOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SunStatusProvider>(
      builder: (context, provider, _) {
        final period = provider.currentPeriod;
        final needsGlow =
            period == SunPeriod.sunrise || period == SunPeriod.sunset;

        if (needsGlow) {
          return AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return IgnorePointer(
                child: CustomPaint(
                  painter: DayNightPainter(
                    sunLongitude: provider.sunLongitude,
                    sunLatitude: provider.sunLatitude,
                    visibleBounds: provider.visibleBounds,
                    period: period,
                    isSimulating: provider.isSimulating,
                    glowAnimation: _glowController.value,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          );
        }

        return IgnorePointer(
          child: CustomPaint(
            painter: DayNightPainter(
              sunLongitude: provider.sunLongitude,
              sunLatitude: provider.sunLatitude,
              visibleBounds: provider.visibleBounds,
              period: period,
              isSimulating: provider.isSimulating,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}
