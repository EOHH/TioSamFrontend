class ShopItem {
  final String id;
  final String userId;
  final String offerItemName;
  final String lookingFor;
  final String imageUrl;
  final DateTime createdAt;
  final String ownerUsername;
  final String ownerAvatar;

  ShopItem({
    required this.id,
    required this.userId,
    required this.offerItemName,
    required this.lookingFor,
    required this.imageUrl,
    required this.createdAt,
    required this.ownerUsername,
    required this.ownerAvatar,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    String dateStr = json['created_at'] ?? DateTime.now().toIso8601String();
    DateTime parsedDate = DateTime.parse(dateStr);
    if (!parsedDate.isUtc) {
      parsedDate = DateTime.utc(
          parsedDate.year, parsedDate.month, parsedDate.day,
          parsedDate.hour, parsedDate.minute, parsedDate.second, parsedDate.millisecond
      );
    }

    final userData = (json['users'] is Map) ? json['users'] : {};

    return ShopItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',

      // AHORA SÍ: Usamos los nombres exactos de TU base de datos
      offerItemName: json['offer_item'] ?? 'Artículo sin nombre',
      lookingFor: json['request_item'] ?? 'Ofertas abiertas',

      imageUrl: json['image_url'] ?? 'https://via.placeholder.com/400x300?text=Sin+Imagen',
      createdAt: parsedDate.toLocal(),
      ownerUsername: userData['username'] ?? 'Usuario Desconocido',
      ownerAvatar: userData['avatar_url'] ?? 'https://ui-avatars.com/api/?name=U',
    );
  }
}