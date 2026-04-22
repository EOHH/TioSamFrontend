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
        .select('*, users(username, avatar_url)')
        .eq('status', 'open') // Solo traemos lo disponible
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradePost.fromJson(json)).toList();
  }

  // --- 2. CREAR PUBLICACIÓN (CON EL GUARDIÁN DE LÍMITES) ---
  Future<void> createTrade({
    required String offer,
    required String request,
    required String category,
    String? description,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;

    // 🛡️ EL GUARDIÁN: Paso A - Obtenemos el límite del usuario
    final userRes = await _client
        .from('users')
        .select('max_active_posts')
        .eq('id', userId)
        .single();

    final maxPosts = userRes['max_active_posts'] as int? ?? 15;

    // 🛡️ EL GUARDIÁN: Paso B - Contamos sus publicaciones activas ('open')
    // Pedimos solo el 'id' para que la consulta sea súper ligera y rápida
    final activeTrades = await _client
        .from('trades')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'open');

    final currentActiveCount = List.from(activeTrades).length;

    // 🛡️ EL GUARDIÁN: Paso C - Comparamos y bloqueamos si es necesario
    if (currentActiveCount >= maxPosts) {
      throw Exception("¡Límite alcanzado! 🚫 Elimina publicaciones antiguas para crear nuevas, o expande tu vitrina en la Tienda.");
    }

    // ✅ Si pasó el guardián, guardamos la publicación en la base de datos
    await _client.from('trades').insert({
      'user_id': userId,
      'offer_item': offer,
      'request_item': request,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'status': 'open', // Forzamos estado inicial
    });
  }
}

// Proveedor del repositorio
final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return TradeRepository(ref.watch(supabaseClientProvider));
});