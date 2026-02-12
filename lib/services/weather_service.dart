import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // OpenWeatherMap 무료 API 키 (데모용)
  // 실제 배포 시 환경변수로 관리해야 함
  static const String _apiKey = 'd1845658f92b31c64bd94f06f7188c9c';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // 구름 타일 URL 템플릿 (OpenWeatherMap Tile Layer)
  static String getCloudTileUrl(int z, int x, int y) {
    return 'https://tile.openweathermap.org/map/clouds_new/$z/$x/$y.png?appid=$_apiKey';
  }

  // 특정 위치의 날씨 정보 가져오기
  Future<WeatherData?> getWeatherAt(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=kr'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }
    } catch (e) {
      // 무시 - 날씨 정보는 선택사항
    }
    return null;
  }
}

class WeatherData {
  final int cloudiness;  // 0-100%
  final String description;
  final String icon;
  final double temperature;
  final int humidity;

  WeatherData({
    required this.cloudiness,
    required this.description,
    required this.icon,
    required this.temperature,
    required this.humidity,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cloudiness: json['clouds']?['all'] ?? 0,
      description: json['weather']?[0]?['description'] ?? '',
      icon: json['weather']?[0]?['icon'] ?? '01d',
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      humidity: json['main']?['humidity'] ?? 0,
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
}
