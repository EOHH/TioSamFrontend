import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/shop_item.dart';

class ShopRepository {
  final SupabaseClient _client;
  ShopRepository(this._client);

  Future<List<ShopItem>> getGlobalFeed() async {
    final currentUserId = _client.auth.currentUser!.id;
    final response = await _client
        .from('trades')
        .select('*, users!inner(username, avatar_url)')
        .neq('user_id', currentUserId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => ShopItem.fromJson(json)).toList();
  }

  // NUEVO: Función para insertar la oferta en la base de datos
  Future<void> sendOffer(String postId, String message) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('trade_offers').insert({
      'post_id': postId,
      'offerer_id': userId,
      'message': message,
      // status es 'pending' por defecto en tu BD
    });
  }
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(supabaseClientProvider));
});

final shopFeedProvider = FutureProvider.autoDispose<List<ShopItem>>((ref) async {
  return ref.watch(shopRepositoryProvider).getGlobalFeed();
});

// NUEVO: Controlador para el botón de "Enviar Oferta" (maneja el estado de carga)
class MakeOfferController extends StateNotifier<AsyncValue<void>> {
  final ShopRepository _repository;
  MakeOfferController(this._repository) : super(const AsyncData(null));

  Future<bool> makeOffer(String postId, String message) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repository.sendOffer(postId, message));
    state = result;
    return !result.hasError;
  }
}

final makeOfferProvider = StateNotifierProvider.autoDispose<MakeOfferController, AsyncValue<void>>((ref) {
  return MakeOfferController(ref.watch(shopRepositoryProvider));
});