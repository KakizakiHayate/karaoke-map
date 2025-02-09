import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_suggestion.dart';
import '../models/place_result.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  Future<List<PlaceResult>> searchKaraoke(
    String query, {
    LatLng? userLocation,
    LatLng? searchLocation,
    bool isStation = false,
  }) async {
    print('Search params - Query: $query, IsStation: $isStation'); // デバッグ用

    final searchUrl = Uri.parse(
      '$_baseUrl/textsearch/json?query=カラオケ $query&language=ja&region=jp&key=$_apiKey',
    );

    final searchResponse = await http.get(searchUrl);
    if (searchResponse.statusCode != 200) return [];

    final searchJson = jsonDecode(searchResponse.body);
    if (searchJson['status'] != 'OK') return [];

    final futures = (searchJson['results'] as List).map((place) async {
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
      if (query.contains('駅')) {
        // 駅検索の場合
        if (searchLocation != null) {
          final distance = _calculateDistance(
            searchLocation.latitude,
            searchLocation.longitude,
            placeLocation.latitude,
            placeLocation.longitude,
          );
          place['distance'] = distance;
          place['distance_type'] = 'station';
          place['station_name'] = query;
          print(
              'Station search - Distance: $distance, Station: $query'); // デバッグ用
        }
      } else if (query.isEmpty && userLocation != null) {
        // 現在地検索の場合
        final distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          placeLocation.latitude,
          placeLocation.longitude,
        );
        place['distance'] = distance;
        place['distance_type'] = 'current';
        print('Current location search - Distance: $distance'); // デバッグ用
      } else {
        // エリア検索の場合
        print('Area search - Finding nearest station...'); // デバッグ用
        final nearestStation = await _findNearestStation(placeLocation);
        if (nearestStation != null) {
          // 最寄り駅情報と距離を設定
          place['nearest_station'] = nearestStation;
          place['distance'] = nearestStation['distance'];
          place['distance_type'] = 'nearest';
          print(
              'Found nearest station: ${nearestStation['name']} - Distance: ${nearestStation['distance']}m'); // デバッグ用
        }
      }

      return PlaceResult.fromJson(place);
    });

    return await Future.wait(futures);
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
}
