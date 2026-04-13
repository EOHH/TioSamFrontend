import 'trade_post.dart';

class TradeOffer {
  final String id;
  final String postId;
  final String offererId;
  final String offererUsername;
  final String offererAvatar;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final TradePost? post; // Información de la publicación original

  TradeOffer({
    required this.id,
    required this.postId,
    required this.offererId,
    required this.offererUsername,
    required this.offererAvatar,
    required this.message,
    required this.status,
    required this.createdAt,
    this.post,
  });

  factory TradeOffer.fromJson(Map<String, dynamic> json) {
    final offererProfile = json['users'] as Map<String, dynamic>;

    return TradeOffer(
      id: json['id'],
      postId: json['post_id'],
      offererId: json['offerer_id'],
      offererUsername: offererProfile['username'],
      offererAvatar: offererProfile['avatar_url'],
      message: json['message'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      post: json['trades'] != null ? TradePost.fromJson(json['trades']) : null,
    );
  }
}