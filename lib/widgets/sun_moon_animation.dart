import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/sun_status_provider.dart';
import '../utils/kst_time_helper.dart';

class SunMoonAnimation extends StatefulWidget {
  const SunMoonAnimation({super.key});

  @override
  State<SunMoonAnimation> createState() => _SunMoonAnimationState();
}

class _SunMoonAnimationState extends State<SunMoonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
        final progress = provider.periodProgress;

        return IgnorePointer(
          child: SizedBox(
            height: 100,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return _buildCelestialBody(period, progress);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCelestialBody(SunPeriod period, double progress) {
    double alignX;
    double alignY;

    switch (period) {
      case SunPeriod.sunrise:
        alignX = 1.0 - progress * 1.0; // right → center
        alignY = -0.3 - sin(progress * pi) * 0.5;
        break;
      case SunPeriod.daytime:
        alignX = 0.0;
        alignY = -0.8;
        break;
      case SunPeriod.sunset:
        alignX = -progress * 1.0; // center → left
        alignY = -0.3 - sin((1 - progress) * pi) * 0.5;
        break;
      case SunPeriod.night:
        alignX = 0.0;
        alignY = -0.7;
        break;
    }

    final isSun = period != SunPeriod.night;
    final glowVal = _glowController.value;

    final glowColor = isSun
        ? AppTheme.sunriseGold.withValues(alpha: 0.3 + 0.15 * glowVal)
        : AppTheme.sunsetLight.withValues(alpha: 0.2 + 0.1 * glowVal);

    final iconColor = isSun ? AppTheme.sunriseGold : Colors.white;
    final iconData = isSun ? Icons.wb_sunny_rounded : Icons.nightlight_round;

    return Stack(
      children: [
        Align(
          alignment: Alignment(alignX, alignY),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 20 + 10 * glowVal,
                  spreadRadius: 5 + 3 * glowVal,
                ),
              ],
            ),
            child: Icon(iconData, color: iconColor, size: 32),
          ),
        ),
        // Night: tiny stars around moon
        if (period == SunPeriod.night) ..._buildMoonStars(glowVal),
      ],
    );
  }

  List<Widget> _buildMoonStars(double glowVal) {
    final offsets = [
      const Alignment(0.25, -0.6),
      const Alignment(-0.2, -0.9),
      const Alignment(0.35, -0.4),
      const Alignment(-0.3, -0.55),
      const Alignment(0.1, -0.95),
    ];

    return List.generate(offsets.length, (i) {
      final phase = ((glowVal + i * 0.2) % 1.0);
      final alpha = 0.3 + 0.7 * phase;
      return Align(
        alignment: offsets[i],
        child: Icon(
          Icons.star_rounded,
          size: 8 + (i % 3) * 3.0,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
    });
  }
}
