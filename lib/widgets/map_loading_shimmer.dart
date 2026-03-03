import 'package:flutter/material.dart';

class MapLoadingShimmer extends StatefulWidget {
  const MapLoadingShimmer({super.key});

  @override
  State<MapLoadingShimmer> createState() => _MapLoadingShimmerState();
}

class _MapLoadingShimmerState extends State<MapLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Container(
          color: const Color(0xFF1A1A2E),
          child: Stack(
            children: [
              // Shimmer sweep
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1.0 + 2.0 * _shimmerController.value, 0),
                      end: Alignment(
                          -1.0 + 2.0 * _shimmerController.value + 0.6, 0),
                      colors: const [
                        Color(0x00FFFFFF),
                        Color(0x18FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(color: const Color(0xFF222244)),
                ),
              ),

              // Skeleton UI
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Fake map placeholder
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    // Shimmer bars
                    _buildShimmerBar(width: 180, height: 14),
                    const SizedBox(height: 10),
                    _buildShimmerBar(width: 120, height: 10),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '지도를 불러오는 중...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),

              // Fake marker dots
              ..._buildFakeMarkers(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  List<Widget> _buildFakeMarkers() {
    final positions = [
      const Offset(0.3, 0.25),
      const Offset(0.7, 0.3),
      const Offset(0.5, 0.55),
      const Offset(0.25, 0.65),
      const Offset(0.75, 0.7),
    ];

    return positions.map((pos) {
      return Positioned(
        left: pos.dx * 300,
        top: pos.dy * 400,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withValues(alpha: 0.12),
          ),
        ),
      );
    }).toList();
  }
}
