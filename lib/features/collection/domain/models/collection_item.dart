class CollectionItem {
  final String id;
  final String userId;
  final String cardName;
  final String imageUrl;
  final String? description;
  final DateTime createdAt;

  CollectionItem({
    required this.id,
    required this.userId,
    required this.cardName,
    required this.imageUrl,
    this.description,
    required this.createdAt,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    String dateStr = json['created_at'];

    // 1. Parseamos la fecha tal cual llega
    DateTime parsedDate = DateTime.parse(dateStr);

    // 2. Si por alguna razón no se registró como UTC, la forzamos
    if (!parsedDate.isUtc) {
      parsedDate = DateTime.utc(
          parsedDate.year, parsedDate.month, parsedDate.day,
          parsedDate.hour, parsedDate.minute, parsedDate.second, parsedDate.millisecond
      );
    }

    return CollectionItem(
      id: json['id'],
      userId: json['user_id'],
      cardName: json['card_name'],
      imageUrl: json['image_url'],
      description: json['description'],
      // 3. Convertimos a hora local de forma segura
      createdAt: parsedDate.toLocal(),
    );
  }
}