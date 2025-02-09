import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_suggestion.dart';
import '../models/place_result.dart';

class PlacesService {
  static const String _apiKey = 'AIzaSyAECg6Ww6B3v3YtibYZkUXE_5tditY5eqI';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String input,
    String language,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=$input&language=$language&components=country:jp&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          return (json['predictions'] as List)
              .map((p) => PlaceSuggestion.fromJson(p))
              .toList();
        }
        print('API Status: ${json['status']}');
        print('Error Message: ${json['error_message']}');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
    return [];
  }

  Future<List<PlaceResult>> searchKaraoke(String query) async {
    final validChains = [
      'まねきねこ',
      'ビッグエコー',
      'BanBan',
      'カラオケ館',
      'ジャンカラ',
      'ジャンボカラオケ',
      'JOYSOUND',
      'JOYJOY',
      'コート・ダジュール',
      'CLUB DAM',
      '歌広場'
    ];

    final url = Uri.parse(
      '$_baseUrl/textsearch/json?query=カラオケ $query&language=ja&region=jp&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') {
        final results = (json['results'] as List)
            .map((p) => PlaceResult.fromJson(p))
            .where((place) => validChains.any(
                  (chain) => place.name.toLowerCase().contains(
                        chain.toLowerCase(),
                      ),
                ))
            .toList();
        return results;
      }
    }
    return [];
  }

  String getPhotoUrl(String photoReference) {
    return '$_baseUrl/photo?maxwidth=400&photo_reference=$photoReference&key=$_apiKey';
  }
}
