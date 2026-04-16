import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../trades/data/trade_repository.dart';
import '../../../trades/domain/models/trade_post.dart';

// 🔥 Escuchamos los cambios de sesión (Login/Logout)
final authStateProvider = StreamProvider.autoDispose((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// =====================================================================
// 1. EL PROVEEDOR ORIGINAL (Mercado / Publicaciones Abiertas)
// =====================================================================
class HomeFeedController extends StateNotifier<AsyncValue<List<TradePost>>> {
  final TradeRepository _repository;

  HomeFeedController(this._repository) : super(const AsyncLoading()) {
    fetchFeed();
  }

  Future<void> fetchFeed() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getTrades());
  }
}

final homeFeedProvider = StateNotifierProvider.autoDispose<HomeFeedController, AsyncValue<List<TradePost>>>((ref) {
  return HomeFeedController(ref.watch(tradeRepositoryProvider));
});


// =====================================================================
// 2. EL NUEVO PROVEEDOR (Exclusivo para el Perfil)
// =====================================================================
final myHistoryFeedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // 🔥 Si el usuario cambia de cuenta, esta línea borra la caché automáticamente
  ref.watch(authStateProvider);

  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return [];

  // Solo mantenemos en caché si hay una sesión válida activa
  ref.keepAlive();

  // Traemos TODAS las cartas de ESTE usuario
  final response = await supabase
      .from('trades')
      .select('*, users(*)')
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});