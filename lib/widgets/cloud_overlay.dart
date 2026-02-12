import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sun_status_provider.dart';
import '../services/weather_service.dart';

class CloudOverlay extends StatefulWidget {
  const CloudOverlay({super.key});

  @override
  State<CloudOverlay> createState() => _CloudOverlayState();
}

class _CloudOverlayState extends State<CloudOverlay>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  int _cloudiness = 0;
  Timer? _weatherTimer;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // 날씨 정보 주기적 업데이트
    _fetchWeather();
    _weatherTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _fetchWeather(),
    );
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    final bounds = context.read<SunStatusProvider>().visibleBounds;
    if (bounds == null) return;

    // 지도 중앙 위치의 날씨 가져오기
    final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

    final weather = await _weatherService.getWeatherAt(centerLat, centerLng);
    if (weather != null && mounted) {
      setState(() {
        _cloudiness = weather.cloudiness;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cloudiness < 10) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            painter: CloudPainter(
              cloudiness: _cloudiness,
              animationValue: _animController.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class CloudPainter extends CustomPainter {
  final int cloudiness;
  final double animationValue;

  CloudPainter({
    required this.cloudiness,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 구름 개수는 cloudiness에 비례
    final cloudCount = (cloudiness / 10).ceil().clamp(1, 15);
    final alpha = (cloudiness / 100 * 0.4).clamp(0.05, 0.4);

    for (int i = 0; i < cloudCount; i++) {
      _drawCloud(canvas, size, i, alpha);
    }
  }

  void _drawCloud(Canvas canvas, Size size, int index, double alpha) {
    // 각 구름의 고유한 위치와 크기 (인덱스 기반 고정 시드)
    final random = Random(index * 1000 + 42);

    final baseX = random.nextDouble() * size.width;
    final baseY = random.nextDouble() * size.height * 0.8;
    final cloudWidth = size.width * (0.15 + random.nextDouble() * 0.2);
    final cloudHeight = cloudWidth * 0.4;

    // 애니메이션으로 구름 이동
    final offsetX = (animationValue * size.width * 0.3 + index * 50) % (size.width + cloudWidth) - cloudWidth / 2;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // 여러 원을 겹쳐서 구름 형태 생성
    final positions = [
      Offset(baseX + offsetX, baseY),
      Offset(baseX + offsetX + cloudWidth * 0.25, baseY - cloudHeight * 0.2),
      Offset(baseX + offsetX + cloudWidth * 0.5, baseY + cloudHeight * 0.1),
      Offset(baseX + offsetX + cloudWidth * 0.75, baseY - cloudHeight * 0.15),
      Offset(baseX + offsetX + cloudWidth, baseY + cloudHeight * 0.05),
    ];

    for (final pos in positions) {
      canvas.drawOval(
        Rect.fromCenter(
          center: pos,
          width: cloudWidth * 0.4,
          height: cloudHeight * 0.8,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CloudPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.cloudiness != cloudiness;
  }
}
