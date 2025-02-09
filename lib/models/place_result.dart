class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final String? photoReference;
  final double rating;
  final int userRatingsTotal;
  final double lat;
  final double lng;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    this.photoReference,
    required this.rating,
    required this.userRatingsTotal,
    required this.lat,
    required this.lng,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      placeId: json['place_id'],
      name: json['name'],
      address: json['formatted_address'] ?? json['vicinity'] ?? '',
      photoReference: json['photos']?[0]?['photo_reference'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      lat: json['geometry']['location']['lat'],
      lng: json['geometry']['location']['lng'],
    );
  }
} 