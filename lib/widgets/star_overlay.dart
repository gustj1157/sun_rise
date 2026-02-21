import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sun_status_provider.dart';
import '../utils/kst_time_helper.dart';

class StarOverlay extends StatefulWidget {
  const StarOverlay({super.key});

  @override
  State<StarOverlay> createState() => _StarOverlayState();
}

class _StarOverlayState extends State<StarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SunStatusProvider>(
      builder: (context, provider, _) {
        if (provider.currentPeriod != SunPeriod.night) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                painter: StarPainter(
                  animationValue: _animController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
        );
      },
    );
  }
}

class StarPainter extends CustomPainter {
  final double animationValue;

  StarPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    const starCount = 80;

    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.7;
      final baseAlpha = 0.3 + random.nextDouble() * 0.7;

      final phase = (animationValue + i * 0.13) % 1.0;
      final twinkle = (sin(phase * 2 * pi) + 1) / 2;
      final alpha = baseAlpha * (0.3 + 0.7 * twinkle);
      final radius = 1.0 + random.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(StarPainter old) => old.animationValue != animationValue;
}
