class ChatMessage {
  final String id;
  final String offerId;
  final String senderId;
  final String? message;
  final String? imageUrl;
  final String? audioUrl;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.offerId,
    required this.senderId,
    this.message,
    this.imageUrl,
    this.audioUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String dateStr = json['created_at'];
    if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains('-')) {
      dateStr += 'Z';
    }

    return ChatMessage(
      id: json['id'],
      offerId: json['offer_id'],
      senderId: json['sender_id'],
      message: json['message'],
      imageUrl: json['image_url'],
      audioUrl: json['audio_url'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(dateStr).toLocal(),
    );
  }
}