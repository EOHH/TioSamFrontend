import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final marketRepositoryProvider = Provider((ref) {
  return MarketRepository(Supabase.instance.client);
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(marketRepositoryProvider);
  return await repository.getCategories();
});

final marketFeedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive();
  final repository = ref.watch(marketRepositoryProvider);
  return await repository.getRecentTrades();
});

class MarketRepository {
  final SupabaseClient _supabase;
  MarketRepository(this._supabase);

  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('name')
          .order('name', ascending: true);

      return (response as List).map((item) => item['name'] as String).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error en getCategories: $e');
      throw Exception('Error cargando categorías: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentTrades() async {
    try {
      final response = await _supabase
          .from('trades')
          .select('''
            *,
            users ( 
              username,
              avatar_url,
              reputation
            )
          ''')
          .eq('status', 'open') // 🔥 FILTRO: Solo traemos los tratos que siguen abiertos
          .order('created_at', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) print('❌ Error en getRecentTrades: $e');
      throw Exception('Error cargando el mercado: $e');
    }
  }
}