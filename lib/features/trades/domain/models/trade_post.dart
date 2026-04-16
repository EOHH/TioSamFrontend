class TradePost {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String offerItemName;
  final String? offerItemImage;
  final String requestItemName;
  final String? description;
  final String category; // Nueva
  final String status;   // Nueva
  final DateTime createdAt;

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
  });

  factory TradePost.fromJson(Map<String, dynamic> json) {
    final profile = json['users'] as Map<String, dynamic>;

    return TradePost(
      id: json['id'],
      userId: json['user_id'],
      username: profile['username'],
      userAvatar: profile['avatar_url'],
      offerItemName: json['offer_item'],
      offerItemImage: json['image_url'],
      requestItemName: json['request_item'],
      description: json['description'],
      category: json['category'] ?? 'General',
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}