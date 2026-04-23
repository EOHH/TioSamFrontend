import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/trade_offer.dart';

class OfferRepository {
  final SupabaseClient _client;

  OfferRepository(this._client);

  // --- 1. ENVIAR OFERTA ---
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

  // --- 2. OBTENER OFERTAS RECIBIDAS ---
  Future<List<TradeOffer>> getReceivedOffers() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('trade_offers')
        .select('*, users!offerer_id(username, avatar_url), trades!inner(*, users(username, avatar_url, is_vip))')
        .eq('trades.user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradeOffer.fromJson(json)).toList();
  }

  // --- 3. OBTENER OFERTAS ENVIADAS ---
  Future<List<TradeOffer>> getSentOffers() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('trade_offers')
        .select('*, users!offerer_id(username, avatar_url, is_vip), trades!inner(*, users(username, avatar_url))')
        .eq('offerer_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => TradeOffer.fromJson(json)).toList();
  }

  // --- 4. ESCUCHAR CAMBIOS EN TIEMPO REAL (STREAM) ---
  Stream<Map<String, dynamic>> watchOfferStatus(String offerId) {
    return _client
        .from('trade_offers')
        .stream(primaryKey: ['id'])
        .eq('id', offerId)
        .map((event) => event.isNotEmpty ? event.first : {});
  }

  // ======================================================================
  // 🔥 LA MÁQUINA DE ESTADOS (STATE MACHINE - ATÓMICA VÍA RPC) 🔥
  // ======================================================================

  // 1. ACEPTAR OFERTA (El Efecto Dominó)
  Future<void> acceptOffer(String offerId) async {
    try {
      await _client.rpc('accept_trade_offer', params: {'p_offer_id': offerId});
    } on PostgrestException catch (e) {
      throw Exception('Rechazado por el servidor: ${e.message}');
    } catch (e) {
      throw Exception('Error de conexión al aceptar la oferta.');
    }
  }

  // 2. CANCELAR TRATO (El plan falló, la carta vuelve al mercado)
  Future<void> cancelTrade(String offerId) async {
    try {
      await _client.rpc('cancel_trade_offer', params: {'p_offer_id': offerId});
    } on PostgrestException catch (e) {
      throw Exception('Rechazado por el servidor: ${e.message}');
    } catch (e) {
      throw Exception('Error de conexión al cancelar el trato.');
    }
  }

  // 3. COMPLETAR TRATO (Éxito Total)
  Future<void> completeTrade(String offerId) async {
    try {
      await _client.rpc('complete_trade_offer', params: {'p_offer_id': offerId});
    } on PostgrestException catch (e) {
      throw Exception('Rechazado por el servidor: ${e.message}');
    } catch (e) {
      throw Exception('Error de conexión al completar el trato.');
    }
  }

  // ======================================================================

  // --- ACTUALIZACIÓN MANUAL (Opcional, si la usas en otro lado) ---
  Future<void> updateOfferStatus(String offerId, String newStatus) async {
    await _client
        .from('trade_offers')
        .update({'status': newStatus})
        .eq('id', offerId);
  }

  // --- ELIMINAR OFERTA ---
  Future<void> deleteOffer(String offerId) async {
    try {
      await _client.from('trade_offers').delete().eq('id', offerId);
    } catch (e) {
      throw Exception('Error al eliminar la oferta: $e');
    }
  }

  // --- ENVIAR RESEÑA ---
  Future<void> submitReview({
    required String offerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    try {
      final reviewerId = _client.auth.currentUser!.id;

      // Leemos a qué publicación pertenece esta oferta
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

// Proveedor
final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(ref.watch(supabaseClientProvider));
});