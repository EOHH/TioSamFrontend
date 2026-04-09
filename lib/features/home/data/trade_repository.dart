import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/trade_post.dart';

class TradeRepository {
  final SupabaseClient _client;
  TradeRepository(this._client);

  // Obtener todas las publicaciones con los datos del usuario (JOIN)
  Future<List<TradePost>> getTrades() async {
    final response = await _client
        .from('trades')
        .select('*, users(username, avatar_url)')
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradePost.fromJson(json)).toList();
  }

  // Crear una nueva publicación
  Future<void> createTrade({
    required String offer,
    required String request,
    String? description,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('trades').insert({
      'user_id': userId,
      'offer_item': offer,
      'request_item': request,
      'description': description,
      'image_url': imageUrl,
    });
  }
}

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return TradeRepository(ref.watch(supabaseClientProvider));
});