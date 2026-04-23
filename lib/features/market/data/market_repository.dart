import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final marketRepositoryProvider = Provider((ref) {
  return MarketRepository(Supabase.instance.client);
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(marketRepositoryProvider);
  return await repository.getCategories();
});

class MarketRepository {
  final SupabaseClient supabase; // Lo hacemos público para el canal Realtime
  MarketRepository(this.supabase);

  Future<List<String>> getCategories() async {
    try {
      final response = await supabase.from('categories').select('name').order('name', ascending: true);
      return (response as List).map((item) => item['name'] as String).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error en getCategories: $e');
      throw Exception('Error cargando categorías: $e');
    }
  }

  // Búsqueda y Paginación (REST)
  Future<List<Map<String, dynamic>>> getTradesPaginated({required int page, required int limit, String query = ''}) async {
    try {
      final from = page * limit;
      final to = from + limit - 1;

      var request = supabase.from('trades')
          .select('*, users(username, avatar_url, reputation, is_vip)')
          .eq('status', 'open');

      if (query.isNotEmpty) {
        request = request.or('offer_item.ilike.%$query%,request_item.ilike.%$query%');
      }

      final response = await request
          .order('is_boosted', ascending: false)
          .order('created_at', ascending: false)
          .range(from, to);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error cargando el mercado: $e');
    }
  }

  // 💡 NUEVO: Obtener una sola carta con todo su JOIN (Necesario para cuando entra una nueva en Realtime)
  Future<Map<String, dynamic>?> getTradeById(String tradeId) async {
    try {
      return await supabase
          .from('trades')
          .select('*, users(username, avatar_url, reputation, is_vip)')
          .eq('id', tradeId)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }
}

// =====================================================================
// 🔥 STATE NOTIFIER: SCROLL INFINITO + WEBSOCKETS EN TIEMPO REAL 🔥
// =====================================================================
class MarketFeedController extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final MarketRepository _repository;
  RealtimeChannel? _realtimeChannel;

  MarketFeedController(this._repository) : super(const AsyncLoading()) {
    fetchInitial();
    _setupRealtime(); // 🚀 Iniciamos la antena de Tiempo Real
  }

  int _page = 0;
  static const int _limit = 15;
  bool hasReachedMax = false;
  bool isLoadingMore = false;

  Future<void> fetchInitial() async {
    _page = 0;
    hasReachedMax = false;
    isLoadingMore = false;
    state = const AsyncLoading();

    try {
      final data = await _repository.getTradesPaginated(page: _page, limit: _limit);
      if (data.length < _limit) hasReachedMax = true;
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> fetchMore() async {
    if (isLoadingMore || hasReachedMax || state is AsyncLoading || state is AsyncError) return;

    isLoadingMore = true;
    final currentData = state.value ?? [];

    try {
      _page++;
      final newData = await _repository.getTradesPaginated(page: _page, limit: _limit);

      if (newData.isEmpty || newData.length < _limit) {
        hasReachedMax = true;
      }
      state = AsyncData([...currentData, ...newData]);
    } catch (e) {
      _page--;
    } finally {
      isLoadingMore = false;
    }
  }

  // =====================================================================
  // 📡 EL MOTOR DE TIEMPO REAL
  // =====================================================================
  void _setupRealtime() {
    _realtimeChannel = _repository.supabase.channel('public:trades')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'trades',
      callback: _handleRealtimeUpdate,
    )
        .subscribe();
  }

  Future<void> _handleRealtimeUpdate(PostgresChangePayload payload) async {
    // Evitamos interrumpir si la app apenas está cargando
    if (state is! AsyncData) return;

    final currentList = List<Map<String, dynamic>>.from(state.value ?? []);

    // 🟢 CASO 1: ALGUIEN PUBLICÓ UNA CARTA NUEVA
    if (payload.eventType == PostgresChangeEvent.insert) {
      final newRecord = payload.newRecord;
      if (newRecord['status'] == 'open') {
        // Obtenemos los datos completos del usuario que la publicó
        final fullTradeData = await _repository.getTradeById(newRecord['id']);
        if (fullTradeData != null) {
          // La inyectamos de primera (índice 0)
          currentList.insert(0, fullTradeData);
          state = AsyncData(currentList);
        }
      }
    }

    // 🟡 CASO 2: ALGUIEN MODIFICÓ UNA CARTA (Compró un Boost, Aceptó Oferta, etc)
    else if (payload.eventType == PostgresChangeEvent.update) {
      final updatedRecord = payload.newRecord;

      // Si ya NO está "open" (porque aceptaron oferta o la pausaron) -> La borramos de la pantalla
      if (updatedRecord['status'] != 'open') {
        currentList.removeWhere((t) => t['id'] == updatedRecord['id']);
        state = AsyncData(currentList);
      }
      // Si sigue "open" pero cambió algo (ej. Alguien pagó un Boost)
      else {
        final fullTradeData = await _repository.getTradeById(updatedRecord['id']);
        if (fullTradeData != null) {
          final index = currentList.indexWhere((t) => t['id'] == fullTradeData['id']);

          if (index != -1) {
            currentList[index] = fullTradeData; // Actualizamos los datos
          } else {
            currentList.insert(0, fullTradeData); // Por si no la teníamos en memoria
          }

          // 🚀 REORDENAMIENTO MÁGICO: Si alguien pagó un Boost, saltará arriba
          currentList.sort((a, b) {
            if (a['is_boosted'] == true && b['is_boosted'] == false) return -1;
            if (a['is_boosted'] == false && b['is_boosted'] == true) return 1;

            final dateA = DateTime.parse(a['created_at']);
            final dateB = DateTime.parse(b['created_at']);
            return dateB.compareTo(dateA); // Los más recientes primero
          });

          state = AsyncData(currentList);
        }
      }
    }

    // 🔴 CASO 3: ALGUIEN ELIMINÓ SU CARTA
    else if (payload.eventType == PostgresChangeEvent.delete) {
      final oldRecordId = payload.oldRecord['id'];
      currentList.removeWhere((t) => t['id'] == oldRecordId);
      state = AsyncData(currentList);
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe(); // Limpiamos la conexión cuando cerramos la pantalla
    super.dispose();
  }
}

final marketFeedProvider = StateNotifierProvider.autoDispose<MarketFeedController, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return MarketFeedController(ref.watch(marketRepositoryProvider));
});