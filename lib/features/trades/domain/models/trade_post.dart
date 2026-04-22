class TradePost {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String offerItemName;
  final String? offerItemImage;
  final String requestItemName;
  final String? description;
  final String category;
  final String status;
  final DateTime createdAt;

  // 🔥 NUEVOS CAMPOS DE MONETIZACIÓN
  final bool isVip;
  final bool isBoosted;

  TradePost({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.offerItemName,
    this.offerItemImage,
    required this.requestItemName,
    this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.isVip = false,
    this.isBoosted = false,
  });

  factory TradePost.fromJson(Map<String, dynamic> json) {
    final profile = json['users'] as Map<String, dynamic>? ?? {};

    return TradePost(
      id: json['id'],
      userId: json['user_id'],
      username: profile['username'] ?? 'Usuario',
      userAvatar: profile['avatar_url'] ?? '',
      offerItemName: json['offer_item'],
      offerItemImage: json['image_url'],
      requestItemName: json['request_item'],
      description: json['description'],
      category: json['category'] ?? 'General',
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
      // 🔥 LEEMOS LOS DATOS, SI SON NULOS PONEMOS FALSE POR SEGURIDAD
      isVip: profile['is_vip'] ?? false,
      isBoosted: json['is_boosted'] ?? false,
    );
  }
}