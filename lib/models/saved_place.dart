class SavedPlace {
  final int? id;
  final int userId;
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
  final DateTime createdAt;

  SavedPlace({
    this.id,
    required this.userId,
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'place_id': placeId,
      'name': name,
      'address': address,
      'photo_reference': photoReference,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'lat': lat,
      'lng': lng,
      'phone_number': phoneNumber,
      'website': website,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedPlace.fromMap(Map<String, dynamic> map) {
    return SavedPlace(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      placeId: map['place_id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      photoReference: map['photo_reference'] as String?,
      rating: map['rating'] as double,
      userRatingsTotal: map['user_ratings_total'] as int,
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      phoneNumber: map['phone_number'] as String?,
      website: map['website'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SavedPlace copyWith({
    int? id,
    int? userId,
    String? placeId,
    String? name,
    String? address,
    String? photoReference,
    double? rating,
    int? userRatingsTotal,
    double? lat,
    double? lng,
    String? phoneNumber,
    String? website,
    DateTime? createdAt,
  }) {
    return SavedPlace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      photoReference: photoReference ?? this.photoReference,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
