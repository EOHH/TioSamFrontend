class UserProfile {
  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final int completedTrades; // ¡Dato real!
  final double reputation;   // ¡Dato real!

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.completedTrades,
    required this.reputation,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? 'https://ui-avatars.com/api/?name=${json['username']}',
      // Si por alguna razón es null en la base de datos, ponemos 0 y 5.0 por defecto
      completedTrades: json['completed_trades'] ?? 0,
      reputation: (json['reputation'] ?? 5.0).toDouble(),
    );
  }
}