import 'dart:math';

class DistanceCalculator {
  /// Haversine formula: distance in km between two coordinates.
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Estimate driving time in minutes (avg ~60 km/h in Korea).
  static int estimateDrivingMinutes(double distanceKm) {
    return (distanceKm / 60 * 60 * 1.15).round(); // 15% traffic buffer
  }

  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()}m';
    if (km < 100) return '${km.toStringAsFixed(1)}km';
    return '${km.round()}km';
  }

  static String formatDrivingTime(int minutes) {
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h시간';
    return '$h시간 $m분';
  }
}
