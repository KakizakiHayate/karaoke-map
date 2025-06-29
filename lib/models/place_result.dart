import 'package:logger/logger.dart';

class PlaceResult {
  static final Logger _logger = Logger();
  final String placeId;
  final String name;
  final String address;
  final String? photoReference;
  final double rating;
  final int userRatingsTotal;
  final double lat;
  final double lng;
  final String? phoneNumber;
  final String? website;
  final Map<String, String>? openingHours;
  final bool? isOpenNow;
  final double? distance; // メートル単位での距離
  final Map<String, dynamic>? nearestStation; // 追加
  final String? distanceType; // 'current', 'station', 'nearest'
  final String? stationName; // 駅名（駅検索の場合）
  final bool hasDetailsLoaded; // 詳細情報が読み込み済みかどうか

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    this.photoReference,
    required this.rating,
    required this.userRatingsTotal,
    required this.lat,
    required this.lng,
    this.phoneNumber,
    this.website,
    this.openingHours,
    this.isOpenNow,
    this.distance,
    this.nearestStation,
    this.distanceType,
    this.stationName,
    this.hasDetailsLoaded = false,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final openingHours = json['opening_hours'];
    Map<String, String>? hours;

    if (openingHours != null && openingHours['periods'] != null) {
      try {
        final periods = openingHours['periods'] as List;

        // 24時間営業の判定
        if (periods.length == 1 &&
            periods[0]['open']?['time'] == '0000' &&
            periods[0]['close'] == null) {
          hours = {
            'open': '0000',
            'close': '0000',
          };
        } else {
          hours = {
            'open': periods[0]?['open']?['time'] ?? '',
            'close': periods[0]?['close']?['time'] ?? '',
          };
        }
      } catch (e) {
        _logger.e('Error parsing opening hours: $e');
        hours = null;
      }
    }

    return PlaceResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'] ?? '',
      photoReference: json['photos']?[0]?['photo_reference'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      lat: json['geometry']['location']['lat'] ?? 0.0,
      lng: json['geometry']['location']['lng'] ?? 0.0,
      phoneNumber: json['formatted_phone_number'],
      website: json['website'],
      openingHours: hours,
      isOpenNow: openingHours?['open_now'],
      distance: json['distance']?.toDouble(),
      nearestStation: json['nearest_station'],
      distanceType: json['distance_type'],
      stationName: json['station_name'],
      hasDetailsLoaded: json['formatted_phone_number'] != null || 
                       json['website'] != null || 
                       json['opening_hours'] != null,
    );
  }

  // 詳細情報を追加したPlaceResultを作成
  PlaceResult withDetails({
    String? phoneNumber,
    String? website,
    Map<String, String>? openingHours,
    bool? isOpenNow,
    String? photoReference,
  }) {
    return PlaceResult(
      placeId: placeId,
      name: name,
      address: address,
      photoReference: photoReference ?? this.photoReference,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      lat: lat,
      lng: lng,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      distance: distance,
      nearestStation: nearestStation,
      distanceType: distanceType,
      stationName: stationName,
      hasDetailsLoaded: true,
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters.round()}m';
  }

  String getDistanceText() {
    if (distance == null) {
      _logger.d('Distance is null');
      return '';
    }

    _logger.d('Distance type: $distanceType');
    _logger.d('Station name: $stationName');
    _logger.d('Nearest station: $nearestStation');

    switch (distanceType) {
      case 'current':
        return '現在地から${_formatDistance(distance!)}';
      case 'station':
        return '$stationNameから${_formatDistance(distance!)}';
      case 'nearest':
        if (nearestStation != null) {
          return '${nearestStation!['name']}から${_formatDistance(nearestStation!['distance'])}';
        }
        break;
    }
    return _formatDistance(distance!);
  }

  String getOpeningHoursText() {
    if (openingHours == null) return '';

    final open = openingHours!['open'];
    final close = openingHours!['close'];

    if (open == null || close == null) return '';

    // 24時間営業の判定
    if (open == '0000' && close == '0000') {
      return '24時間営業';
    }

    // 通常の営業時間表示
    final openTime = _formatTime(open);
    final closeTime = _formatTime(close);

    return '$openTime ~ $closeTime';
  }

  String _formatTime(String time) {
    if (time.length != 4) return time;
    final hour = int.parse(time.substring(0, 2));
    final minute = time.substring(2);
    return '$hour:$minute';
  }
}
