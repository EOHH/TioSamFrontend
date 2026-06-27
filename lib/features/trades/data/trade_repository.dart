import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/trade_post.dart';

class TradeRepository {
  final SupabaseClient _client;
  TradeRepository(this._client);

  // --- 1. OBTENER PUBLICACIONES DEL MERCADO ---
  Future<List<TradePost>> getTrades() async {
    final response = await _client
        .from('trades')
        .select('*, users(username, avatar_url, is_vip)')
        .eq('status', 'open')
        .order('is_boosted', ascending: false) // Prioridad a los Boosted
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradePost.fromJson(json)).toList();
  }

  // --- 2. CREAR PUBLICACIÓN (CON INTELIGENCIA VIP) ---
  Future<String> createTrade({
    required String offer,
    required String request,
    required String category,
    String? description,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;

    // 🛡️ EL GUARDIÁN: Paso A - Obtenemos datos de privilegios del usuario
    final userRes = await _client
        .from('users')
        .select('max_active_posts, is_vip')
        .eq('id', userId)
        .single();

    final bool isVip = userRes['is_vip'] ?? false;

    // 🔥 Límite dinámico: Si es VIP tiene barra libre (9999), si no, lo que diga su max_active_posts o 5.
    final maxPosts = isVip ? 9999 : (userRes['max_active_posts'] as int? ?? 5);

    // 🛡️ EL GUARDIÁN: Paso B - Contamos sus publicaciones activas
    final activeTrades = await _client
        .from('trades')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'open');

    final currentActiveCount = List.from(activeTrades).length;

    // 🛡️ EL GUARDIÁN: Paso C - Bloqueo con mensaje codificado para la UI
    if (currentActiveCount >= maxPosts) {
      throw Exception("LIMIT_REACHED|Has alcanzado tu límite de $maxPosts publicaciones activas.");
    }

    // ✅ Inserción limpia
    final response = await _client.from('trades').insert({
      'user_id': userId,
      'offer_item': offer,
      'request_item': request,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'status': 'open',
      'is_boosted': false,
    }).select('id').single();

    return response['id'] as String;
  }
}

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return TradeRepository(ref.watch(supabaseClientProvider));
});