import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/spot_data.dart';
import '../models/sun_data.dart';

class SunApiException implements Exception {
  final String message;
  SunApiException(this.message);

  @override
  String toString() => 'SunApiException: $message';
}

class SunriseApiService {
  static const String _baseUrl = 'https://api.sunrise-sunset.org/json';
  // CORS 프록시 (웹용)
  static const String _corsProxy = 'https://corsproxy.io/?';

  Future<SunData> fetchSunData(double lat, double lng, {DateTime? date}) async {
    final dateStr = date != null
        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : 'today';

    final apiUrl = '$_baseUrl?lat=$lat&lng=$lng&date=$dateStr&formatted=0';

    // 웹에서는 CORS 프록시 사용
    final url = kIsWeb ? '$_corsProxy${Uri.encodeComponent(apiUrl)}' : apiUrl;
    final uri = Uri.parse(url);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw SunApiException('HTTP ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String?;

      if (status != 'OK') {
        throw SunApiException('API status: $status');
      }

      return SunData.fromJson(json);
    } catch (e) {
      if (e is SunApiException) rethrow;
      throw SunApiException(e.toString());
    }
  }

  Future<void> fetchAllSpotsSunData(List<SpotData> spots) async {
    // 병렬 처리 대신 순차 처리 (API 제한 고려)
    for (final spot in spots) {
      try {
        final sunData = await fetchSunData(spot.lat, spot.lng);
        spot.sunriseTime = sunData.sunrise;
        spot.sunsetTime = sunData.sunset;

        final now = DateTime.now().toUtc();
        final sunriseUtc = sunData.sunrise;
        final sunsetUtc = sunData.sunset;

        spot.isDaytime = now.isAfter(sunriseUtc) && now.isBefore(sunsetUtc);
      } catch (e) {
        // 개별 실패는 무시하고 계속 진행
        print('Failed to fetch sun data for ${spot.name}: $e');
      }

      // API 요청 간격 (rate limiting 방지)
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
