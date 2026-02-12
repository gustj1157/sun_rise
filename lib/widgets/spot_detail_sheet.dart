import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/spot_data.dart';
import '../providers/spots_provider.dart';
import '../screens/photo_gallery_screen.dart';
import '../services/weather_service.dart';
import '../utils/distance_calculator.dart';
import 'countdown_timer.dart';
import 'sun_compass.dart';

class SpotDetailSheet extends StatefulWidget {
  final SpotData spot;
  final VoidCallback onClose;

  const SpotDetailSheet({
    super.key,
    required this.spot,
    required this.onClose,
  });

  @override
  State<SpotDetailSheet> createState() => _SpotDetailSheetState();
}

class _SpotDetailSheetState extends State<SpotDetailSheet> {
  int _currentPhotoIndex = 0;
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void didUpdateWidget(SpotDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spot.name != widget.spot.name) {
      _currentPhotoIndex = 0;
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    setState(() => _isLoadingWeather = true);
    final weather = await _weatherService.getWeatherAt(
      widget.spot.lat,
      widget.spot.lng,
    );
    if (mounted) {
      setState(() {
        _weatherData = weather;
        _isLoadingWeather = false;
      });
    }
  }

  String _formatKST(DateTime? dt) {
    if (dt == null) return '--:--';
    final kst = dt.toUtc().add(const Duration(hours: 9));
    return '${kst.hour.toString().padLeft(2, '0')}:${kst.minute.toString().padLeft(2, '0')}';
  }

  void _nextPhoto() {
    if (widget.spot.displayPhotoUrls.isEmpty) return;
    setState(() {
      _currentPhotoIndex = (_currentPhotoIndex + 1) % widget.spot.displayPhotoUrls.length;
    });
  }

  void _prevPhoto() {
    if (widget.spot.displayPhotoUrls.isEmpty) return;
    setState(() {
      _currentPhotoIndex = (_currentPhotoIndex - 1 + widget.spot.displayPhotoUrls.length) % widget.spot.displayPhotoUrls.length;
    });
  }

  int _getRecommendationScore() {
    if (_weatherData == null) return 0;
    final c = _weatherData!.cloudiness;
    if (c <= 20) return 5;
    if (c <= 40) return 4;
    if (c <= 60) return 3;
    if (c <= 80) return 2;
    return 1;
  }

  Color _getCloudinessColor(int cloudiness) {
    if (cloudiness < 30) return Colors.green;
    if (cloudiness < 70) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 사진 영역
          if (widget.spot.displayPhotoUrls.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              height: 160,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhotoGalleryScreen(spot: widget.spot),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: widget.spot.displayPhotoUrls[_currentPhotoIndex],
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  if (widget.spot.displayPhotoUrls.length > 1)
                    Positioned(
                      left: 8, top: 0, bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _prevPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  if (widget.spot.displayPhotoUrls.length > 1)
                    Positioned(
                      right: 8, top: 0, bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _nextPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  if (widget.spot.displayPhotoUrls.length > 1)
                    Positioned(
                      bottom: 8, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.spot.displayPhotoUrls.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: index == _currentPhotoIndex ? 8 : 6,
                            height: index == _currentPhotoIndex ? 8 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentPhotoIndex
                                  ? widget.spot.typeColor
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름 + 설명
                Row(
                  children: [
                    Icon(widget.spot.typeIcon, color: widget.spot.typeColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.spot.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.spot.description,
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 오늘 추천도 + 구름량
                _buildRecommendationRow(),
                const SizedBox(height: 10),

                // 일출/일몰 시간 + 골든아워
                _buildSunTimeRow(),
                const SizedBox(height: 10),

                // 골든아워 시간대
                _buildGoldenHourRow(),
                const SizedBox(height: 10),

                // 일출 카운트다운
                _buildCountdown(),

                // 거리 + 소요시간 + 출발 알림
                _buildDistanceRow(),

                // 날씨 상세
                _buildWeatherRow(),
                const SizedBox(height: 10),

                // 촬영 가이드
                _buildPhotographyGuide(),

                // 태그
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.spot.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showNavigationDialog(context),
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text('길찾기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => SunCompass(spot: widget.spot),
                          );
                        },
                        icon: const Icon(Icons.explore, size: 16),
                        label: const Text('나침반'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.spot.displayPhotoUrls.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PhotoGalleryScreen(spot: widget.spot),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.photo_camera, size: 16),
                        label: const Text('사진'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.spot.typeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 오늘 추천도 별점 + 구름량 바
  Widget _buildRecommendationRow() {
    if (_isLoadingWeather) {
      return Row(
        children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38),
          ),
          const SizedBox(width: 8),
          Text('추천도 계산 중...', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      );
    }
    if (_weatherData == null) return const SizedBox.shrink();

    final score = _getRecommendationScore();
    final cloud = _weatherData!.cloudiness;
    final cloudColor = _getCloudinessColor(cloud);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // 별점
          const Text('추천', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          ...List.generate(5, (i) => Icon(
            i < score ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: 16,
          )),
          const Spacer(),
          // 구름량 아이콘 + 바
          Icon(
            cloud < 30 ? Icons.wb_sunny_outlined
                : cloud < 70 ? Icons.cloud_queue
                : Icons.cloud,
            color: cloudColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: cloud / 100,
                backgroundColor: Colors.grey[800],
                color: cloudColor,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$cloud%',
            style: TextStyle(fontSize: 10, color: cloudColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// 일출/일몰 시간 + 낮/밤 표시
  Widget _buildSunTimeRow() {
    return Row(
      children: [
        _buildTimeChip(
          icon: Icons.wb_sunny,
          label: '일출',
          time: _formatKST(widget.spot.sunriseTime),
          color: Colors.orange,
        ),
        const SizedBox(width: 12),
        _buildTimeChip(
          icon: Icons.nights_stay,
          label: '일몰',
          time: _formatKST(widget.spot.sunsetTime),
          color: Colors.deepPurple,
        ),
        const Spacer(),
        if (widget.spot.isDaytime != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.spot.isDaytime!
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.indigo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.spot.isDaytime! ? Icons.wb_sunny : Icons.nights_stay,
                  size: 14,
                  color: widget.spot.isDaytime! ? Colors.amber : Colors.indigo[200],
                ),
                const SizedBox(width: 4),
                Text(
                  widget.spot.isDaytime! ? '낮' : '밤',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.spot.isDaytime! ? Colors.amber : Colors.indigo[200],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 골든아워 시간대 표시
  Widget _buildGoldenHourRow() {
    final sunrise = widget.spot.sunriseTime;
    final sunset = widget.spot.sunsetTime;
    if (sunrise == null && sunset == null) return const SizedBox.shrink();

    return Row(
      children: [
        if (sunrise != null)
          _buildGoldenChip(
            label: '아침 골든아워',
            start: sunrise.subtract(const Duration(hours: 1)),
            end: sunrise,
            color: Colors.orange,
            icon: Icons.wb_twilight,
          ),
        if (sunrise != null && sunset != null) const SizedBox(width: 10),
        if (sunset != null)
          _buildGoldenChip(
            label: '저녁 골든아워',
            start: sunset,
            end: sunset.add(const Duration(hours: 1)),
            color: Colors.deepPurple,
            icon: Icons.wb_twilight,
          ),
      ],
    );
  }

  Widget _buildGoldenChip({
    required String label,
    required DateTime start,
    required DateTime end,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 8, color: color)),
              Text(
                '${_formatKST(start)} ~ ${_formatKST(end)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 네이버/카카오 길찾기
  void _showNavigationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${widget.spot.name} 길찾기',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.green, size: 28),
                title: const Text('네이버 지도', style: TextStyle(color: Colors.white)),
                subtitle: Text('naver.com', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  final url = 'https://map.naver.com/v5/search/${Uri.encodeComponent(widget.spot.name)}';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined, color: Colors.yellow, size: 28),
                title: const Text('카카오맵', style: TextStyle(color: Colors.white)),
                subtitle: Text('kakao.com', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  final url = 'https://map.kakao.com/link/map/${Uri.encodeComponent(widget.spot.name)},${widget.spot.lat},${widget.spot.lng}';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Colors.blue, size: 28),
                title: const Text('Google Maps', style: TextStyle(color: Colors.white)),
                subtitle: Text('google.com', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.spot.lat},${widget.spot.lng}';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 일출까지 카운트다운
  Widget _buildCountdown() {
    final sunrise = widget.spot.sunriseTime;
    if (sunrise == null) return const SizedBox.shrink();

    final now = DateTime.now().toUtc();
    // 오늘 일출이 아직 안 지났으면 표시
    if (sunrise.toUtc().isBefore(now)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CountdownTimer(
        targetTime: sunrise,
        label: '일출까지',
        color: Colors.orange,
      ),
    );
  }

  /// 거리 + 소요시간 + 출발 알림 배너
  Widget _buildDistanceRow() {
    final userPos = context.watch<SpotsProvider>().userLocation;
    if (userPos == null) return const SizedBox.shrink();

    final distance = DistanceCalculator.calculateDistance(
      userPos.latitude, userPos.longitude,
      widget.spot.lat, widget.spot.lng,
    );
    final travelMin = DistanceCalculator.estimateDrivingMinutes(distance);

    // "지금 출발하면 맞출 수 있어요" 판단
    final sunrise = widget.spot.sunriseTime;
    final canMakeIt = sunrise != null &&
        sunrise.toUtc().isAfter(DateTime.now().toUtc()) &&
        DateTime.now().toUtc().add(Duration(minutes: travelMin + 10)).isBefore(sunrise.toUtc());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.blue, size: 15),
              const SizedBox(width: 6),
              Text(
                DistanceCalculator.formatDistance(distance),
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(width: 1, height: 14, color: Colors.white24),
              ),
              const Icon(Icons.access_time, color: Colors.blue, size: 14),
              const SizedBox(width: 4),
              Text(
                '약 ${DistanceCalculator.formatDrivingTime(travelMin)}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        if (canMakeIt)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.teal.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '지금 출발하면 일출에 맞출 수 있어요!',
                      style: TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// 촬영 가이드
  Widget _buildPhotographyGuide() {
    if (widget.spot.shootingTip == null && widget.spot.compositionTip == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: const Icon(Icons.camera_alt, color: Colors.orange, size: 18),
            title: const Text(
              '촬영 가이드',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            iconColor: Colors.grey[500],
            collapsedIconColor: Colors.grey[500],
            children: [
              if (widget.spot.shootingTip != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('베스트 촬영 포인트', style: TextStyle(fontSize: 10, color: Colors.blue[300], fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              widget.spot.shootingTip!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.spot.compositionTip != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.grid_on, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('추천 구도', style: TextStyle(fontSize: 10, color: Colors.orange[300], fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            widget.spot.compositionTip!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherRow() {
    if (_isLoadingWeather) {
      return Row(
        children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38),
          ),
          const SizedBox(width: 8),
          Text('날씨 정보 불러오는 중...', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      );
    }

    if (_weatherData == null) return const SizedBox.shrink();

    final w = _weatherData!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            w.cloudiness > 70 ? Icons.cloud
                : w.cloudiness > 30 ? Icons.cloud_queue
                : Icons.wb_sunny_outlined,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '구름 ${w.cloudiness}%',
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          _weatherDivider(),
          const Icon(Icons.thermostat_outlined, color: Colors.white54, size: 14),
          const SizedBox(width: 4),
          Text(
            '${w.temperature.toStringAsFixed(1)}\u00B0C',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          _weatherDivider(),
          Flexible(
            child: Text(
              w.description,
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(width: 1, height: 14, color: Colors.white24),
    );
  }

  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: color)),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
