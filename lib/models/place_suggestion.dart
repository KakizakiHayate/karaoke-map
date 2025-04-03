class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'];
    return PlaceSuggestion(
      placeId: json['place_id'],
      description: json['description'],
      mainText: structured['main_text'],
      secondaryText: structured['secondary_text'] ?? '',
    );
  }
} 