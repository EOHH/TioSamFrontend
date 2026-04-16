import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/trade_post.dart';

class TradeRepository {
  final SupabaseClient _client;
  TradeRepository(this._client);

  Future<List<TradePost>> getTrades() async {
    final response = await _client
        .from('trades')
        .select('*, users(username, avatar_url)')
        .eq('status', 'open') // Solo traemos lo disponible
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradePost.fromJson(json)).toList();
  }

  Future<void> createTrade({
    required String offer,
    required String request,
    required String category, // Nuevo parámetro
    String? description,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('trades').insert({
      'user_id': userId,
      'offer_item': offer,
      'request_item': request,
      'category': category,    // Guardamos categoría
      'description': description,
      'image_url': imageUrl,
      'status': 'open',        // Forzamos estado inicial
    });
  }
}

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return TradeRepository(ref.watch(supabaseClientProvider));
});