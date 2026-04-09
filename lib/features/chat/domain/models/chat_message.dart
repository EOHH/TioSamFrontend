class ChatMessage {
  final String id;
  final String offerId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.offerId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // 1. Extraemos el texto de la fecha que manda Supabase
    String dateStr = json['created_at'];

    // 2. Si no trae indicador de zona horaria ('Z' o '+'), le agregamos 'Z' (Zulú/UTC)
    // Esto obliga a Flutter a entender que la hora viene de Londres.
    if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains('-')) {
      dateStr += 'Z';
    }

    return ChatMessage(
      id: json['id'],
      offerId: json['offer_id'],
      senderId: json['sender_id'],
      message: json['message'],
      // 3. Parseamos como UTC y lo convertimos INMEDIATAMENTE a la hora local de tu país
      createdAt: DateTime.parse(dateStr).toLocal(),
    );
  }
}