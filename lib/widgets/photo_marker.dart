import 'package:flutter/material.dart';
import '../models/spot_data.dart';

class PhotoMarker extends StatelessWidget {
  final SpotData spot;
  final double size;

  const PhotoMarker({
    super.key,
    required this.spot,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: spot.typeColor.withValues(alpha: 0.3),
        border: Border.all(
          color: spot.typeColor,
          width: 3,
        ),
      ),
      child: Icon(
        spot.typeIcon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
