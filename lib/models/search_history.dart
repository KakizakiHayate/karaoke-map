class SearchHistory {
  final int? id;
  final int userId;
  final String searchQuery;
  final String searchType; // 'current_location', 'area', 'station'
  final DateTime createdAt;

  SearchHistory({
    this.id,
    required this.userId,
    required this.searchQuery,
    required this.searchType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'search_query': searchQuery,
      'search_type': searchType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      searchQuery: map['search_query'] as String,
      searchType: map['search_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SearchHistory copyWith({
    int? id,
    int? userId,
    String? searchQuery,
    String? searchType,
    DateTime? createdAt,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      searchQuery: searchQuery ?? this.searchQuery,
      searchType: searchType ?? this.searchType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
