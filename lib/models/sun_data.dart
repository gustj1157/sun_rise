class SunData {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime solarNoon;
  final DateTime civilTwilightBegin;
  final DateTime civilTwilightEnd;

  SunData({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.civilTwilightBegin,
    required this.civilTwilightEnd,
  });

  factory SunData.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return SunData(
      sunrise: DateTime.parse(results['sunrise'] as String),
      sunset: DateTime.parse(results['sunset'] as String),
      solarNoon: DateTime.parse(results['solar_noon'] as String),
      civilTwilightBegin:
          DateTime.parse(results['civil_twilight_begin'] as String),
      civilTwilightEnd:
          DateTime.parse(results['civil_twilight_end'] as String),
    );
  }
}
