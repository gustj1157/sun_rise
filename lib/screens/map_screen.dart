import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/spot_data.dart';
import '../providers/spots_provider.dart';
import '../providers/sun_status_provider.dart';
import '../services/location_service.dart';
import '../widgets/cloud_overlay.dart';
import '../widgets/day_night_overlay.dart';
import '../widgets/spot_detail_sheet.dart';
import '../widgets/star_overlay.dart';
import '../widgets/sun_moon_animation.dart';
import '../widgets/timelapse_overlay.dart';
import '../widgets/top_info_bar.dart';
import '../widgets/weekly_recommendation.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  double _currentZoom = 11.0;
  bool _showRecommendation = false;
  bool _showTimelapse = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          12,
        ),
      );
    }
  }

  Future<void> _updateVisibleBounds() async {
    if (_mapController == null) return;
    try {
      final bounds = await _mapController!.getVisibleRegion();
      if (bounds.southwest.latitude == 0 &&
          bounds.southwest.longitude == 0 &&
          bounds.northeast.latitude == 0 &&
          bounds.northeast.longitude == 0) {
        Future.delayed(
          const Duration(milliseconds: 500),
          _updateVisibleBounds,
        );
        return;
      }
      if (mounted) {
        context.read<SunStatusProvider>().updateVisibleBounds(bounds);
      }
    } catch (_) {}
  }

  void _onCameraMove(CameraPosition position) {
    final newZoom = position.zoom;
    if ((_currentZoom < 9 && newZoom >= 9) ||
        (_currentZoom >= 9 && newZoom < 9)) {
      _currentZoom = newZoom;
      context.read<SpotsProvider>().updateMarkersForZoom(newZoom);
    }
    _currentZoom = newZoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny_rounded, color: AppTheme.sunriseOrange, size: 22),
            const SizedBox(width: 8),
            const Text(
              'SunTime',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
            tooltip: '현재 위치',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, size: 20),
            onPressed: () {
              setState(() {
                _showRecommendation = !_showRecommendation;
                if (_showRecommendation) _showTimelapse = false;
              });
            },
            tooltip: '추천 명소',
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline, size: 20),
            onPressed: () {
              final spot = context.read<SpotsProvider>().selectedSpot;
              if (spot == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('명소를 먼저 선택해주세요'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              setState(() {
                _showTimelapse = !_showTimelapse;
                if (_showTimelapse) _showRecommendation = false;
              });
            },
            tooltip: '타임랩스',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SpotsProvider>().refreshSunData();
            },
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Consumer<SpotsProvider>(
        builder: (context, spotsProvider, _) {
          return Stack(
            children: [
              // (1) Google Map
              GoogleMap(
                initialCameraPosition: AppTheme.kKoreaCenter,
                mapType: MapType.satellite,
                markers: spotsProvider.markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    _updateVisibleBounds,
                  );
                },
                onCameraMove: _onCameraMove,
                onCameraIdle: _updateVisibleBounds,
                onTap: (_) {
                  spotsProvider.clearSelection();
                },
              ),

              // (2) Day/Night gradient overlay
              const Positioned.fill(
                child: DayNightOverlay(),
              ),

              // (3) Cloud overlay
              const Positioned.fill(
                child: CloudOverlay(),
              ),

              // (4) Star overlay (night only)
              const Positioned.fill(
                child: StarOverlay(),
              ),

              // (5) Sun/Moon animation (top area)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 100,
                child: IgnorePointer(child: SunMoonAnimation()),
              ),

              // (6) Top info bar
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                child: const TopInfoBar(),
              ),

              // (7) Timelapse controls
              if (_showTimelapse && spotsProvider.selectedSpot != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 56,
                  child: TimelapseOverlay(
                    spot: spotsProvider.selectedSpot!,
                    onClose: () => setState(() => _showTimelapse = false),
                  ),
                ),

              // (8) Bottom: recommendation, detail sheet, or filter bar
              if (_showRecommendation)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: WeeklyRecommendation(
                    onSpotTap: () =>
                        setState(() => _showRecommendation = false),
                  ),
                )
              else if (spotsProvider.selectedSpot != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SpotDetailSheet(
                    spot: spotsProvider.selectedSpot!,
                    onClose: () => spotsProvider.clearSelection(),
                  ),
                )
              else
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFilterBar(spotsProvider),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(SpotsProvider provider) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterChip(
            icon: Icons.wb_sunny_rounded,
            label: '일출',
            color: AppTheme.sunriseOrange,
            isActive: provider.activeFilters.contains(SpotType.sunrise),
            count:
                provider.spots.where((s) => s.type == SpotType.sunrise).length,
            onTap: () => provider.toggleFilter(SpotType.sunrise),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.nightlight_round,
            label: '일몰',
            color: AppTheme.sunsetPurple,
            isActive: provider.activeFilters.contains(SpotType.sunset),
            count:
                provider.spots.where((s) => s.type == SpotType.sunset).length,
            onTap: () => provider.toggleFilter(SpotType.sunset),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.star_rounded,
            label: '둘다',
            color: AppTheme.sunriseGold,
            isActive: provider.activeFilters.contains(SpotType.both),
            count: provider.spots.where((s) => s.type == SpotType.both).length,
            onTap: () => provider.toggleFilter(SpotType.both),
          ),
          const Spacer(),
          Text(
            '${provider.markers.length}곳',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey[700]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? color : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '$label $count',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
