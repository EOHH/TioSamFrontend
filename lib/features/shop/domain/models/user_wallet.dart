class UserWallet {
  final String id;
  final String userId;
  final int gems;

  UserWallet({
    required this.id,
    required this.userId,
    required this.gems,
  });

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gems: json['gems'] as int? ?? 0,
    );
  }

  // Las buenas prácticas dictan usar copyWith para inmutabilidad
  UserWallet copyWith({
    String? id,
    String? userId,
    int? gems,
  }) {
    return UserWallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gems: gems ?? this.gems,
    );
  }
}