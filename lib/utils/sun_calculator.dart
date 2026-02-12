import 'dart:math';
import '../models/sun_data.dart';
import '../models/sun_status.dart';

class SunCalculator {
  /// Calculates the sub-solar longitude in degrees (-180..180) for a given UTC time.
  static double calculateSunLongitude(DateTime utcTime) {
    final hours = utcTime.hour +
        utcTime.minute / 60.0 +
        utcTime.second / 3600.0;
    final sunLng = 180.0 - (hours * 15.0);
    return ((sunLng + 180) % 360) - 180;
  }

  /// Calculates the sun's declination (sub-solar latitude) in degrees.
  /// Ranges from -23.44 (winter solstice) to +23.44 (summer solstice).
  static double calculateSunDeclination(DateTime utcTime) {
    final dayOfYear =
        utcTime.difference(DateTime.utc(utcTime.year, 1, 1)).inDays + 1;
    return -23.44 * cos(2 * pi / 365 * (dayOfYear + 10));
  }

  /// Calculates SunStatus based on sun data and current time.
  static SunStatus calculateSunStatus(SunData sunData, DateTime now) {
    final beforeTwilightBegin =
        sunData.civilTwilightBegin.subtract(const Duration(minutes: 30));
    final afterSunrise =
        sunData.sunrise.add(const Duration(minutes: 30));
    final beforeSunset =
        sunData.sunset.subtract(const Duration(minutes: 30));
    final afterTwilightEnd =
        sunData.civilTwilightEnd.add(const Duration(minutes: 30));

    if (now.isBefore(beforeTwilightBegin)) {
      return SunStatus.beforeSunrise;
    } else if (now.isBefore(afterSunrise)) {
      return SunStatus.sunrise;
    } else if (now.isBefore(beforeSunset)) {
      return SunStatus.daytime;
    } else if (now.isBefore(afterTwilightEnd)) {
      return SunStatus.sunset;
    } else {
      return SunStatus.afterSunset;
    }
  }

  /// Returns darkness value 0.0 (bright/day) to 1.0 (dark/night) for a geographic point.
  /// Uses spherical law of cosines for angular distance from the sub-solar point,
  /// considering both latitude and longitude for a realistic day/night terminator.
  static double getDarknessAtPoint(double lat, double lng, DateTime utcNow) {
    final sunLng = calculateSunLongitude(utcNow);
    final sunLat = calculateSunDeclination(utcNow);
    return getDarknessAtPointFast(lat, lng, sunLng, sunLat);
  }

  /// Pre-calculated sun position version — avoids redundant trig in tight loops.
  static double getDarknessAtPointFast(
    double lat, double lng, double sunLng, double sunLat,
  ) {
    final lat1 = sunLat * pi / 180;
    final lat2 = lat * pi / 180;
    final dLng = (lng - sunLng) * pi / 180;

    var cosAngle = sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(dLng);
    cosAngle = cosAngle.clamp(-1.0, 1.0);
    final angle = acos(cosAngle) * 180 / pi;

    if (angle <= 87) return 0.0;
    if (angle >= 96) return 1.0;
    return (angle - 87) / 9.0;
  }
}
