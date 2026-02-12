import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/spot_data.dart';

class UnsplashPhoto {
  final String id;
  final String regularUrl;
  final String smallUrl;
  final String photographer;
  final String photographerUrl;

  UnsplashPhoto({
    required this.id,
    required this.regularUrl,
    required this.smallUrl,
    required this.photographer,
    required this.photographerUrl,
  });

  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) {
    final urls = json['urls'] as Map<String, dynamic>? ?? {};
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final links = user['links'] as Map<String, dynamic>? ?? {};
    return UnsplashPhoto(
      id: json['id'] as String? ?? '',
      regularUrl: urls['regular'] as String? ?? '',
      smallUrl: urls['small'] as String? ?? '',
      photographer: user['name'] as String? ?? 'Unknown',
      photographerUrl: links['html'] as String? ?? '',
    );
  }
}

class UnsplashService {
  // Replace with your Unsplash Access Key from https://unsplash.com/developers
  static const _accessKey = 'YOUR_UNSPLASH_ACCESS_KEY';
  static const _baseUrl = 'https://api.unsplash.com';
  static const _corsProxy = 'https://corsproxy.io/?';

  static String _buildQuery(SpotData spot) {
    final typeKeyword = switch (spot.type) {
      SpotType.sunrise => '일출 sunrise',
      SpotType.sunset => '일몰 sunset',
      SpotType.both => '일출 일몰',
    };
    return '${spot.name} $typeKeyword';
  }

  static Future<List<UnsplashPhoto>> searchPhotos(
    SpotData spot, {
    int perPage = 10,
  }) async {
    final query = _buildQuery(spot);
    var url = '$_baseUrl/search/photos'
        '?query=${Uri.encodeComponent(query)}'
        '&per_page=$perPage'
        '&orientation=landscape';

    if (kIsWeb) url = '$_corsProxy${Uri.encodeComponent(url)}';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Client-ID $_accessKey'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Unsplash API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];

    return results
        .map((r) => UnsplashPhoto.fromJson(r as Map<String, dynamic>))
        .where((p) => p.regularUrl.isNotEmpty)
        .toList();
  }
}
