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

  // ==========================================
  // 🔥 LA MÁQUINA DE ESTADOS (STATE MACHINE) 🔥
  // ==========================================

  // 1. ACEPTAR OFERTA (El Efecto Dominó)
  Future<void> acceptOffer(String offerId) async {
    try {
      // a. Obtenemos de qué publicación es esta oferta
      final offerData = await _client.from('trade_offers').select('post_id').eq('id', offerId).single();
      final postId = offerData['post_id'];

      // b. Aceptamos esta oferta en específico
      await _client.from('trade_offers').update({'status': 'accepted'}).eq('id', offerId);

      // c. Rechazamos automáticamente todas las demás ofertas PENDIENTES de esta misma carta
      await _client.from('trade_offers').update({'status': 'rejected'})
          .eq('post_id', postId)
          .eq('status', 'pending') // Solo rechazamos las pendientes
          .neq('id', offerId);

      // d. 🔥 FIX: Cambiamos a 'in_progress'. Esto la oculta del Mercado (porque no es 'open'),
      // pero avisa al Perfil que aún no está 'closed' (terminada).
      await _client.from('trades').update({'status': 'in_progress'}).eq('id', postId);
    } catch (e) {
      throw Exception('Error al aceptar la oferta: $e');
    }
  }

  // 2. CANCELAR TRATO (El plan falló, la carta vuelve al mercado)
  Future<void> cancelTrade(String offerId) async {
    try {
      final offerData = await _client.from('trade_offers').select('post_id').eq('id', offerId).single();
      final postId = offerData['post_id'];

      // a. Cancelamos la oferta (o la rechazamos)
      await _client.from('trade_offers').update({'status': 'cancelled'}).eq('id', offerId);

      // b. ¡La carta vuelve a estar disponible en el Mercado! ('open')
      await _client.from('trades').update({'status': 'open'}).eq('id', postId);
    } catch (e) {
      throw Exception('Error al cancelar el trato: $e');
    }
  }

  // 3. COMPLETAR TRATO (Éxito Total)
  Future<void> completeTrade(String offerId) async {
    try {
      final offerData = await _client.from('trade_offers').select('post_id').eq('id', offerId).single();
      final postId = offerData['post_id'];

      // a. Marcamos la oferta como completada
      await _client.from('trade_offers').update({'status': 'completed'}).eq('id', offerId);

      // b. 🔥 FIX: Ahora sí, la carta se marca como 'closed' (Completada totalmente)
      await _client.from('trades').update({'status': 'closed'}).eq('id', postId);
    } catch (e) {
      throw Exception('Error al completar el trato: $e');
    }
  }

  // ==========================================

  Future<void> updateOfferStatus(String offerId, String newStatus) async {
    await _client
        .from('trade_offers')
        .update({'status': newStatus})
        .eq('id', offerId);
  }

  Future<void> deleteOffer(String offerId) async {
    try {
      await _client.from('trade_offers').delete().eq('id', offerId);
    } catch (e) {
      throw Exception('Error al eliminar la oferta: $e');
    }
  }

  Future<void> submitReview({
    required String offerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    try {
      final reviewerId = _client.auth.currentUser!.id;

      final offerData = await _client
          .from('trade_offers')
          .select('post_id')
          .eq('id', offerId)
          .single();

      final tradeId = offerData['post_id'];

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