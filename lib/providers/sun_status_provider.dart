import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/kst_time_helper.dart';
import '../utils/sun_calculator.dart';

class SunStatusProvider extends ChangeNotifier {
  double _sunLongitude = 0.0;
  double _sunLatitude = 0.0;
  LatLngBounds? _visibleBounds;
  Timer? _timer;
  DateTime? _simulatedTime;

  double get sunLongitude => _sunLongitude;
  double get sunLatitude => _sunLatitude;
  LatLngBounds? get visibleBounds => _visibleBounds;
  bool get isSimulating => _simulatedTime != null;

  DateTime get currentKst {
    final utc = _simulatedTime ?? DateTime.now().toUtc();
    return utc.add(const Duration(hours: 9));
  }

  SunPeriod get currentPeriod => KstTimeHelper.getSunPeriod(currentKst.hour);

  double get periodProgress => KstTimeHelper.getPeriodProgress(currentKst);

  SunStatusProvider() {
    _updateSunPosition();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_simulatedTime == null) _updateSunPosition();
    });
  }

  void _updateSunPosition() {
    final utcNow = _simulatedTime ?? DateTime.now().toUtc();
    _sunLongitude = SunCalculator.calculateSunLongitude(utcNow);
    _sunLatitude = SunCalculator.calculateSunDeclination(utcNow);
    notifyListeners();
  }

  void setSimulatedTime(DateTime time) {
    _simulatedTime = time;
    _updateSunPosition();
  }

  void clearSimulatedTime() {
    _simulatedTime = null;
    _updateSunPosition();
  }

  void updateVisibleBounds(LatLngBounds bounds) {
    _visibleBounds = bounds;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
