import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/spot_data.dart';
import '../providers/spots_provider.dart';
import '../services/weather_service.dart';
import '../utils/distance_calculator.dart';

class _ScoredSpot {
  final SpotData spot;
  final int cloudiness;
  final double score;
  final double? distanceKm;

  _ScoredSpot({
    required this.spot,
    required this.cloudiness,
    required this.score,
    this.distanceKm,
  });
}

class WeeklyRecommendation extends StatefulWidget {
  final VoidCallback? onSpotTap;

  const WeeklyRecommendation({super.key, this.onSpotTap});

  @override
  State<WeeklyRecommendation> createState() => _WeeklyRecommendationState();
}

class _WeeklyRecommendationState extends State<WeeklyRecommendation> {
  final WeatherService _weatherService = WeatherService();
  List<_ScoredSpot> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final provider = context.read<SpotsProvider>();
    final spots = provider.spots;
    final userPos = provider.userLocation;

    final scored = <_ScoredSpot>[];
    for (final spot in spots) {
      final weather = await _weatherService.getWeatherAt(spot.lat, spot.lng);
      if (weather == null) continue;

      double distScore = 100 - weather.cloudiness.toDouble();

      double? distKm;
      if (userPos != null) {
        distKm = DistanceCalculator.calculateDistance(
          userPos.latitude, userPos.longitude,
          spot.lat, spot.lng,
        );
        distScore *= 1.0 / (1.0 + distKm / 200);
      }

      scored.add(_ScoredSpot(
        spot: spot,
        cloudiness: weather.cloudiness,
        score: distScore,
        distanceKm: distKm,
      ));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    if (mounted) {
      setState(() {
        _recommendations = scored.take(3).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 추천 명소',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  '날씨 기반',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
            )
          else
            ...List.generate(_recommendations.length, (i) {
              final rec = _recommendations[i];
              return _buildRecommendationCard(rec, i + 1);
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(_ScoredSpot rec, int rank) {
    final stars = rec.cloudiness <= 20 ? 5
        : rec.cloudiness <= 40 ? 4
        : rec.cloudiness <= 60 ? 3
        : rec.cloudiness <= 80 ? 2 : 1;

    final cloudColor = rec.cloudiness < 30 ? Colors.green
        : rec.cloudiness < 70 ? Colors.orange : Colors.redAccent;

    return GestureDetector(
      onTap: () {
        context.read<SpotsProvider>().selectSpot(rec.spot);
        widget.onSpotTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: rank == 1
              ? Border.all(color: Colors.amber.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: rank == 1 ? Colors.amber : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: rank == 1 ? Colors.black : Colors.white70,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Spot info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(rec.spot.typeIcon, color: rec.spot.typeColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rec.spot.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 12,
                      )),
                      const SizedBox(width: 8),
                      Icon(
                        rec.cloudiness < 30 ? Icons.wb_sunny_outlined
                            : rec.cloudiness < 70 ? Icons.cloud_queue : Icons.cloud,
                        color: cloudColor,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text('${rec.cloudiness}%', style: TextStyle(fontSize: 10, color: cloudColor)),
                      if (rec.distanceKm != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.directions_car, size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          DistanceCalculator.formatDistance(rec.distanceKm!),
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
