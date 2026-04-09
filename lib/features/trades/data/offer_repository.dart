import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/trade_offer.dart';

class OfferRepository {
  final SupabaseClient _client;

  OfferRepository(this._client);

  Future<void> submitOffer({
    required String postId,
    required String message,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('trade_offers').insert({
      'post_id': postId,
      'offerer_id': userId,
      'message': message,
    });
  }

  // 1. OFERTAS RECIBIDAS (Alguien quiere mi carta)
  Future<List<TradeOffer>> getReceivedOffers() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('trade_offers')
        .select('*, users!offerer_id(username, avatar_url), trades!inner(*, users(username, avatar_url))')
        .eq('trades.user_id', userId) // Filtrar por mis publicaciones
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradeOffer.fromJson(json)).toList();
  }

  // 2. NUEVO: OFERTAS ENVIADAS (Yo quiero la carta de alguien más)
  Future<List<TradeOffer>> getSentOffers() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('trade_offers')
        .select('*, users!offerer_id(username, avatar_url), trades!inner(*, users(username, avatar_url))')
        .eq('offerer_id', userId) // Filtrar por mis ofertas
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradeOffer.fromJson(json)).toList();
  }

  // NUEVO: Finalizar el intercambio llamando a la función RPC
  Future<void> completeTrade(String offerId) async {
    await _client.rpc('complete_trade', params: {'offer_id_param': offerId});
  }

  Future<void> updateOfferStatus(String offerId, String newStatus) async {
    await _client
        .from('trade_offers')
        .update({'status': newStatus})
        .eq('id', offerId);
  }
}

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(ref.watch(supabaseClientProvider));
});