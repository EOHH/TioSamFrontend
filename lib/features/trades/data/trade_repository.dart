import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/trade_post.dart';

class TradeRepository {
  final SupabaseClient _client;
  TradeRepository(this._client);

  // Obtener todas las publicaciones activas con los datos del usuario (JOIN)
  Future<List<TradePost>> getTrades() async {
    final response = await _client
        .from('trades')
        .select('*, users(username, avatar_url)')
        .eq('status', 'open') // 🔥 FILTRO: Solo traemos publicaciones abiertas
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradePost.fromJson(json)).toList();
  }

  // Crear una nueva publicación
  Future<void> createTrade({
    required String offer,
    required String request,
    String? description,
    String? imageUrl,
    String category = 'General', // 🔥 SOPORTE PARA CATEGORÍAS (Por defecto 'General')
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('trades').insert({
      'user_id': userId,
      'offer_item': offer,
      'request_item': request,
      'description': description,
      'image_url': imageUrl,
      'category': category, // 🔥 Guardamos la categoría en Supabase
      'status': 'open',     // 🔥 FORZAMOS a que nazca como 'open'
    });
  }
}

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return TradeRepository(ref.watch(supabaseClientProvider));
});