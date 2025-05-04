import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_suggestion.dart';
import '../models/place_result.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import '../config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlacesService {
  static String get _apiKey => EnvConfig.googleMapsApiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final Logger _logger = Logger();

  static const Duration _timeout = Duration(seconds: 10);

  // キャッシュのキー
  static const String _placeDetailsCache = 'place_details_cache';
  static const String _nearbyStationsCache = 'nearby_stations_cache';
  static const Duration _cacheDuration = Duration(hours: 24); // キャッシュの有効期限

  // 通常のHTTPリクエスト
  Future<http.Response> _httpGet(Uri url) async {
    try {
      return await http.get(url).timeout(_timeout);
    } catch (e) {
      _logger.e('リクエストエラー: $e');
      rethrow;
    }
  }

  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String input,
    String language,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=$input&language=$language&components=country:jp&key=$_apiKey',
    );

    try {
      final response = await _httpGet(url);
      _logger.d('Response status: ${response.statusCode}');

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

  // 詳細情報のキャッシュを取得
  Future<Map<String, dynamic>?> _getCachedPlaceDetails(String placeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_placeDetailsCache:$placeId');

      if (cacheString != null) {
        final cacheData = jsonDecode(cacheString);
        final timestamp = DateTime.parse(cacheData['timestamp']);

        // キャッシュが有効期限内か確認
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          _logger.d('キャッシュから詳細情報を取得: $placeId');
          return cacheData['details'];
        }
      }
    } catch (e) {
      _logger.e('キャッシュ取得エラー: $e');
    }
    return null;
  }

  // 詳細情報をキャッシュに保存
  Future<void> _cachePlaceDetails(
      String placeId, Map<String, dynamic> details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'details': details,
      };
      await prefs.setString(
          '$_placeDetailsCache:$placeId', jsonEncode(cacheData));
      _logger.d('詳細情報をキャッシュに保存: $placeId');
    } catch (e) {
      _logger.e('キャッシュ保存エラー: $e');
    }
  }

  // 最寄り駅情報のキャッシュを取得
  Future<Map<String, dynamic>?> _getCachedNearestStation(
      String locationKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_nearbyStationsCache:$locationKey');

      if (cacheString != null) {
        final cacheData = jsonDecode(cacheString);
        final timestamp = DateTime.parse(cacheData['timestamp']);

        // キャッシュが有効期限内か確認
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          _logger.d('キャッシュから最寄り駅情報を取得: $locationKey');
          return cacheData['station'];
        }
      }
    } catch (e) {
      _logger.e('駅情報キャッシュ取得エラー: $e');
    }
    return null;
  }

  // 最寄り駅情報をキャッシュに保存
  Future<void> _cacheNearestStation(
      String locationKey, Map<String, dynamic> station) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'station': station,
      };
      await prefs.setString(
          '$_nearbyStationsCache:$locationKey', jsonEncode(cacheData));
      _logger.d('最寄り駅情報をキャッシュに保存: $locationKey');
    } catch (e) {
      _logger.e('駅情報キャッシュ保存エラー: $e');
    }
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

    try {
      final searchResponse = await _httpGet(searchUrl);
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
        final fallbackResponse = await _httpGet(fallbackUrl);

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

      // リクエスト数削減のため、バッチでPlace Detailsを処理する
      final results = <PlaceResult>[];
      for (var place in filteredResults) {
        try {
          // キャッシュから詳細情報をチェック
          final placeId = place['place_id'];
          Map<String, dynamic>? detailsData =
              await _getCachedPlaceDetails(placeId);

          // キャッシュになければAPI呼び出し
          if (detailsData == null) {
            final detailsUrl = Uri.parse(
              '$_baseUrl/details/json?place_id=$placeId&language=ja&fields=formatted_phone_number,website,opening_hours,photos&key=$_apiKey',
            );

            final detailsResponse = await _httpGet(detailsUrl);
            if (detailsResponse.statusCode == 200) {
              final detailsJson = jsonDecode(detailsResponse.body);
              if (detailsJson['status'] == 'OK') {
                detailsData = detailsJson['result'] as Map<String, dynamic>;
                // キャッシュに保存
                await _cachePlaceDetails(placeId, detailsData);
              }
            }
          }

          // 詳細情報をマージ
          if (detailsData != null) {
            place.addAll(detailsData);
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
              _logger
                  .d('Station search - Distance: $distance, Station: $query');
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
            // エリア検索の場合は最寄り駅情報を取得
            _logger.d('Area search - Finding nearest station...');

            // 位置情報からキャッシュのキーを生成
            final locationKey =
                '${placeLocation.latitude.toStringAsFixed(5)},${placeLocation.longitude.toStringAsFixed(5)}';

            // キャッシュから最寄り駅をチェック
            final nearestStation = await _getCachedNearestStation(locationKey);

            // キャッシュになければAPI呼び出し
            final stationInfo =
                nearestStation ?? await _findNearestStation(placeLocation);

            // stationInfoがnullでない場合のみ処理
            if (stationInfo != null) {
              // キャッシュがなかった場合のみ保存
              if (nearestStation == null) {
                await _cacheNearestStation(locationKey, stationInfo);
              }

              // 最寄り駅情報と距離を設定
              place['nearest_station'] = stationInfo;
              distance = stationInfo['distance'];
              place['distance'] = distance;
              place['distance_type'] = 'nearest';
              _logger.d(
                  'Found nearest station: ${stationInfo['name']} - Distance: ${distance}m');
            }
          }

          // 距離情報をログに出力（デバッグ用）
          _logger.d(
              'Place: ${place['name']}, Distance: $distance, Radius: $radius');

          // 指定された半径内かどうかをチェック
          if (distance != null && distance <= radius) {
            results.add(PlaceResult.fromJson(place));
          }
        } catch (e) {
          _logger.e('Error processing place ${place['name']}: $e');
        }
      }

      _logger.d('Final results count (within ${radius}m): ${results.length}');
      return results;
    } catch (e) {
      _logger.e('検索中にエラーが発生しました: $e');
      // エラーハンドリングを改善してユーザーにわかりやすいメッセージを表示できるようにする
      return [];
    }
  }

  Future<Map<String, dynamic>?> _findNearestStation(LatLng location) async {
    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json?location=${location.latitude},${location.longitude}'
      '&radius=1000&type=train_station&language=ja&key=$_apiKey',
    );

    try {
      final response = await _httpGet(url);
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
    } catch (e) {
      _logger.e('最寄り駅検索中にエラーが発生しました: $e');
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

    try {
      final response = await _httpGet(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && json['candidates'].isNotEmpty) {
          final location = json['candidates'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      _logger.e('場所の座標取得中にエラーが発生しました: $e');
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
      final response = await _httpGet(url);
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
