import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_suggestion.dart';
import '../models/place_result.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

class PlacesService {
  static const String _apiKey = 'AIzaSyAECg6Ww6B3v3YtibYZkUXE_5tditY5eqI';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final Logger _logger = Logger();

  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String input,
    String language,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=$input&language=$language&components=country:jp&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          return (json['predictions'] as List)
              .map((p) => PlaceSuggestion.fromJson(p))
              .toList();
        }
        _logger.w('API Status: ${json['status']}');
        _logger.w('Error Message: ${json['error_message']}');
      }
    } catch (e) {
      _logger.e('Error fetching suggestions: $e');
    }
    return [];
  }

  Future<List<PlaceResult>> searchKaraoke(
    String query, {
    LatLng? userLocation,
    LatLng? searchLocation,
    bool isStation = false,
    required Map<String, bool> selectedChains,
    required int radius,
  }) async {
    _logger.d(
        'Search params - Query: $query, IsStation: $isStation, Radius: $radius');

    // 検索タイプによってURLを変更
    Uri searchUrl;
    String searchType = 'text'; // デフォルトはテキスト検索

    // 現在地から検索（クエリが空）かつ位置情報がある場合は、nearbySearchを使用
    if (query.isEmpty && userLocation != null) {
      searchUrl = Uri.parse(
        '$_baseUrl/nearbysearch/json?'
        'location=${userLocation.latitude},${userLocation.longitude}'
        '&radius=$radius'
        '&type=establishment'
        '&keyword=カラオケ'
        '&language=ja'
        '&key=$_apiKey',
      );
      searchType = 'nearby';
      _logger.d('Using Nearby Search: $searchUrl');
    } else {
      // テキスト検索を使用
      searchUrl = Uri.parse(
        '$_baseUrl/textsearch/json?query=カラオケ $query&language=ja&region=jp&key=$_apiKey',
      );
      _logger.d('Using Text Search: $searchUrl');
    }

    final searchResponse = await http.get(searchUrl);
    if (searchResponse.statusCode != 200) {
      _logger.e(
          'API Error: ${searchResponse.statusCode} - ${searchResponse.body}');
      return [];
    }

    final searchJson = jsonDecode(searchResponse.body);

    // 近隣検索がZERO_RESULTSを返した場合、テキスト検索にフォールバック
    if (searchType == 'nearby' &&
        searchJson['status'] == 'ZERO_RESULTS' &&
        userLocation != null) {
      _logger.w(
          'Nearby search returned ZERO_RESULTS, falling back to text search');

      // テキスト検索で「カラオケ」を検索
      final fallbackUrl = Uri.parse(
        '$_baseUrl/textsearch/json?query=カラオケ&location=${userLocation.latitude},${userLocation.longitude}'
        '&radius=$radius&language=ja&region=jp&key=$_apiKey',
      );

      _logger.d('Using fallback Text Search: $fallbackUrl');
      final fallbackResponse = await http.get(fallbackUrl);

      if (fallbackResponse.statusCode == 200) {
        final fallbackJson = jsonDecode(fallbackResponse.body);
        if (fallbackJson['status'] == 'OK') {
          searchJson.clear();
          searchJson.addAll(fallbackJson);
        } else {
          _logger.e(
              'Fallback search also failed: ${fallbackJson['status']} - ${fallbackJson['error_message'] ?? "Unknown error"}');
        }
      }
    }

    if (searchJson['status'] != 'OK') {
      _logger.e(
          'API Status Error: ${searchJson['status']} - ${searchJson['error_message'] ?? "Unknown error"}');
      return [];
    }

    _logger.d(
        'Total results before filtering: ${(searchJson['results'] as List).length}');

    // 検索結果をフィルタリング
    final filteredResults = (searchJson['results'] as List).where((place) {
      final placeName = place['name'] as String;

      // 選択されたチェーン店が空の場合はすべて表示
      if (selectedChains.isEmpty || selectedChains.values.every((v) => !v)) {
        return true;
      }

      // 選択されたチェーン店に含まれているかチェック
      return selectedChains.entries
          .where((entry) => entry.value) // trueのものだけ
          .any((entry) => placeName.contains(entry.key));
    }).toList();

    _logger.d('Results after chain filtering: ${filteredResults.length}');

    // フィルタリングされた結果に対して詳細情報を取得
    final futures = filteredResults.map((place) async {
      // 詳細情報を取得
      final detailsUrl = Uri.parse(
        '$_baseUrl/details/json?place_id=${place['place_id']}&language=ja&fields=formatted_phone_number,website,opening_hours,photos&key=$_apiKey',
      );

      final detailsResponse = await http.get(detailsUrl);
      if (detailsResponse.statusCode == 200) {
        final detailsJson = jsonDecode(detailsResponse.body);
        if (detailsJson['status'] == 'OK') {
          place.addAll(detailsJson['result']);
        }
      }

      final placeLocation = LatLng(
        place['geometry']['location']['lat'],
        place['geometry']['location']['lng'],
      );

      // 距離情報の設定
      double? distance;
      if (query.contains('駅')) {
        // 駅検索の場合
        if (searchLocation != null) {
          distance = _calculateDistance(
            searchLocation.latitude,
            searchLocation.longitude,
            placeLocation.latitude,
            placeLocation.longitude,
          );
          place['distance'] = distance;
          place['distance_type'] = 'station';
          place['station_name'] = query;
          _logger.d('Station search - Distance: $distance, Station: $query');
        }
      } else if (query.isEmpty && userLocation != null) {
        // 現在地検索の場合
        distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          placeLocation.latitude,
          placeLocation.longitude,
        );
        place['distance'] = distance;
        place['distance_type'] = 'current';
        _logger.d('Current location search - Distance: $distance');
      } else {
        // エリア検索の場合
        _logger.d('Area search - Finding nearest station...');
        final nearestStation = await _findNearestStation(placeLocation);
        if (nearestStation != null) {
          // 最寄り駅情報と距離を設定
          place['nearest_station'] = nearestStation;
          distance = nearestStation['distance'];
          place['distance'] = distance;
          place['distance_type'] = 'nearest';
          _logger.d(
              'Found nearest station: ${nearestStation['name']} - Distance: ${distance}m');
        }
      }

      // 距離情報をログに出力（デバッグ用）
      _logger
          .d('Place: ${place['name']}, Distance: $distance, Radius: $radius');

      // 指定された半径内かどうかをチェック
      if (distance != null && distance <= radius) {
        return PlaceResult.fromJson(place);
      }
      return null;
    });

    // nullを除外して結果を返す
    final results = await Future.wait(futures);
    final finalResults = results.whereType<PlaceResult>().toList();

    _logger
        .d('Final results count (within ${radius}m): ${finalResults.length}');

    return finalResults;
  }

  Future<Map<String, dynamic>?> _findNearestStation(LatLng location) async {
    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json?location=${location.latitude},${location.longitude}'
      '&radius=1000&type=train_station&language=ja&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK' && json['results'].isNotEmpty) {
        final station = json['results'][0];
        final stationLocation = LatLng(
          station['geometry']['location']['lat'],
          station['geometry']['location']['lng'],
        );

        final distance = _calculateDistance(
          location.latitude,
          location.longitude,
          stationLocation.latitude,
          stationLocation.longitude,
        );

        return {
          'name': station['name'],
          'distance': distance,
        };
      }
    }
    return null;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // 地球の半径（メートル）
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // メートル単位での距離
  }

  String getPhotoUrl(String photoReference) {
    return '$_baseUrl/photo?maxwidth=400&photo_reference=$photoReference&key=$_apiKey';
  }

  Future<LatLng?> getPlaceLocation(String query) async {
    final url = Uri.parse(
      '$_baseUrl/findplacefromtext/json?input=$query&inputtype=textquery'
      '&fields=geometry&language=ja&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK' && json['candidates'].isNotEmpty) {
        final location = json['candidates'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
  }

  Future<List<PlaceResult>> searchNearby(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=$lat,$lng'
        '&radius=1500'
        '&type=establishment'
        '&keyword=カラオケ'
        '&language=ja'
        '&key=$_apiKey',
      );

      _logger.d('Searching nearby places at: $lat, $lng');
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        _logger.w('API returned status: ${data['status']}');
        return [];
      }

      final List<PlaceResult> results = [];
      for (var place in data['results']) {
        results.add(PlaceResult.fromJson(place));
      }

      _logger.i('Found ${results.length} nearby places');
      return results;
    } catch (e) {
      _logger.e('Error searching nearby places: $e');
      return [];
    }
  }
}
