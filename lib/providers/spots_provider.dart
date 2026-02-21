import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/spots_data.dart';
import '../models/spot_data.dart';
import '../services/location_service.dart';
import '../services/marker_generator_service.dart';
import '../services/sunrise_api_service.dart';

class SpotsProvider extends ChangeNotifier {
  final SunriseApiService _apiService = SunriseApiService();
  final MarkerGeneratorService _markerService = MarkerGeneratorService();
  final LocationService _locationService = LocationService();

  List<SpotData> _spots = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  SpotData? _selectedSpot;
  Position? _userLocation;

  Set<SpotType> _activeFilters = {
    SpotType.sunrise,
    SpotType.sunset,
    SpotType.both,
  };
  bool _showLabels = false;
  Map<String, GeneratedMarker> _generatedWithLabels = {};
  Map<String, GeneratedMarker> _generatedWithoutLabels = {};
  Map<String, GeneratedMarker> _generatedSelected = {};

  List<SpotData> get spots => _spots;
  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SpotData? get selectedSpot => _selectedSpot;
  Position? get userLocation => _userLocation;
  Set<SpotType> get activeFilters => _activeFilters;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _spots = List.from(kHiddenSpots);

      if (kIsWeb) {
        await Future.delayed(const Duration(seconds: 2));
      }

      _generatedWithoutLabels =
          await _markerService.generateAllMarkers(_spots, showLabels: false);
      _generatedWithLabels =
          await _markerService.generateAllMarkers(_spots, showLabels: true);
      _generatedSelected =
          await _markerService.generateSelectedMarkers(_spots);

      _rebuildMarkers();

      _isLoading = false;
      notifyListeners();

      await Future.wait([
        _apiService.fetchAllSpotsSunData(_spots),
        _fetchUserLocation(),
      ]);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _rebuildMarkers() {
    final markerMap =
        _showLabels ? _generatedWithLabels : _generatedWithoutLabels;
    final visibleSpots =
        _spots.where((s) => _activeFilters.contains(s.type));

    _markers = visibleSpots.map((spot) {
      final isSelected = spot.name == _selectedSpot?.name;
      final gm = isSelected
          ? (_generatedSelected[spot.name] ?? markerMap[spot.name])
          : markerMap[spot.name];

      return Marker(
        markerId: MarkerId(spot.name),
        position: LatLng(spot.lat, spot.lng),
        icon: gm?.descriptor ?? BitmapDescriptor.defaultMarker,
        anchor: gm?.anchor ?? const Offset(0.5, 1.0),
        onTap: () => selectSpot(spot),
      );
    }).toSet();
  }

  void toggleFilter(SpotType type) {
    if (_activeFilters.contains(type)) {
      if (_activeFilters.length > 1) {
        _activeFilters = Set.from(_activeFilters)..remove(type);
      }
    } else {
      _activeFilters = Set.from(_activeFilters)..add(type);
    }
    _rebuildMarkers();
    notifyListeners();
  }

  void updateMarkersForZoom(double zoom) {
    final shouldShowLabels = zoom >= 9;
    if (shouldShowLabels == _showLabels) return;
    _showLabels = shouldShowLabels;
    _rebuildMarkers();
    notifyListeners();
  }

  void selectSpot(SpotData spot) {
    _selectedSpot = spot;
    _rebuildMarkers();
    notifyListeners();
  }

  void clearSelection() {
    _selectedSpot = null;
    _rebuildMarkers();
    notifyListeners();
  }

  Future<void> _fetchUserLocation() async {
    try {
      _userLocation = await _locationService.getCurrentLocation();
    } catch (_) {}
  }

  Future<void> refreshSunData() async {
    try {
      await Future.wait([
        _apiService.fetchAllSpotsSunData(_spots),
        _fetchUserLocation(),
      ]);
      notifyListeners();
    } catch (_) {}
  }
}
