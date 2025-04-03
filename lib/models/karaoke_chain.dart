class KaraokeChain {
  final int? id;
  final String name;
  final bool isDefaultSelected;
  final int defaultOrder;
  final DateTime createdAt;

  KaraokeChain({
    this.id,
    required this.name,
    this.isDefaultSelected = true,
    required this.defaultOrder,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_default_selected': isDefaultSelected ? 1 : 0,
      'default_order': defaultOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory KaraokeChain.fromMap(Map<String, dynamic> map) {
    return KaraokeChain(
      id: map['id'] as int?,
      name: map['name'] as String,
      isDefaultSelected: map['is_default_selected'] == 1,
      defaultOrder: map['default_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  KaraokeChain copyWith({
    int? id,
    String? name,
    bool? isDefaultSelected,
    int? defaultOrder,
    DateTime? createdAt,
  }) {
    return KaraokeChain(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefaultSelected: isDefaultSelected ?? this.isDefaultSelected,
      defaultOrder: defaultOrder ?? this.defaultOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
