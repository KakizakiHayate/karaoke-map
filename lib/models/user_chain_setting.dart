class UserChainSetting {
  final int? id;
  final int userId;
  final int chainId;
  final bool isSelected;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserChainSetting({
    this.id,
    required this.userId,
    required this.chainId,
    required this.isSelected,
    required this.displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'chain_id': chainId,
      'is_selected': isSelected ? 1 : 0,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserChainSetting.fromMap(Map<String, dynamic> map) {
    return UserChainSetting(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      chainId: map['chain_id'] as int,
      isSelected: map['is_selected'] == 1,
      displayOrder: map['display_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  UserChainSetting copyWith({
    int? id,
    int? userId,
    int? chainId,
    bool? isSelected,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserChainSetting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chainId: chainId ?? this.chainId,
      isSelected: isSelected ?? this.isSelected,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
