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

  Future<List<TradeOffer>> getReceivedOffers() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('trade_offers')
        .select('*, users!offerer_id(username, avatar_url), trades!inner(*, users(username, avatar_url))')
        .eq('trades.user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradeOffer.fromJson(json)).toList();
  }

  Future<List<TradeOffer>> getSentOffers() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('trade_offers')
        .select('*, users!offerer_id(username, avatar_url), trades!inner(*, users(username, avatar_url))')
        .eq('offerer_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradeOffer.fromJson(json)).toList();
  }

  // Mantenemos el Stream en vivo para que el Chat reaccione al instante
  Stream<Map<String, dynamic>> watchOfferStatus(String offerId) {
    return _client
        .from('trade_offers')
        .stream(primaryKey: ['id'])
        .eq('id', offerId)
        .map((event) => event.isNotEmpty ? event.first : {});
  }

  // 👇 RESTAURAMOS TU RPC (Ahora funcionará con poderes absolutos)
  Future<void> completeTrade(String offerId) async {
    try {
      await _client.rpc('complete_trade', params: {'offer_id_param': offerId});
    } catch (e) {
      throw Exception('Error al cerrar el trato en el servidor: $e');
    }
  }

  Future<void> updateOfferStatus(String offerId, String newStatus) async {
    await _client
        .from('trade_offers')
        .update({'status': newStatus})
        .eq('id', offerId);
  }

  // NUEVA FUNCIÓN: Eliminar una oferta de la base de datos
  Future<void> deleteOffer(String offerId) async {
    try {
      await _client.from('trade_offers').delete().eq('id', offerId);
    } catch (e) {
      throw Exception('Error al eliminar la oferta: $e');
    }
  }

  // NUEVA FUNCIÓN: Enviar una calificación y reseña
  Future<void> submitReview({
    required String offerId, // Usamos el offerId para buscar el trade original
    required String revieweeId, // A quién estamos calificando
    required int rating,
    required String comment,
  }) async {
    try {
      final reviewerId = _client.auth.currentUser!.id;

      // 1. Primero averiguamos el trade_id a partir de la oferta
      final offerData = await _client
          .from('trade_offers')
          .select('post_id')
          .eq('id', offerId)
          .single();

      final tradeId = offerData['post_id'];

      // 2. Insertamos la reseña en la nueva tabla
      await _client.from('reviews').insert({
        'trade_id': tradeId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'rating': rating,
        'comment': comment,
      });

    } catch (e) {
      throw Exception('Error al enviar la reseña: $e');
    }
  }
}

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(ref.watch(supabaseClientProvider));
});