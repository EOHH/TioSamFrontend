import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Proveedor del repositorio
final marketRepositoryProvider = Provider((ref) {
  return MarketRepository(Supabase.instance.client);
});

// 2. Proveedor que ejecutará la búsqueda y le dará los datos a la UI
final marketFeedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(marketRepositoryProvider);
  return await repository.getRecentTrades();
});

class MarketRepository {
  final SupabaseClient _supabase;
  MarketRepository(this._supabase);

  // Función para obtener las publicaciones más recientes
  Future<List<Map<String, dynamic>>> getRecentTrades() async {
    try {
      // MAGIA RELACIONAL: Traemos la publicación Y los datos del dueño al mismo tiempo
      final response = await _supabase
          .from('trades')
          .select('''
            *,
            users!trades_user_id_fkey ( 
              username,
              avatar_url,
              reputation
            )
          ''')
      //.eq('status', 'open') // 👈 Descomenta esto si tienes un estatus para ocultar los completados
          .order('created_at', ascending: false) // Los más nuevos primero
          .limit(30); // Solo traemos 30 para no saturar el celular

      if (kDebugMode) {
        print('✅ Mercado cargado: ${response.length} publicaciones encontradas.');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) print('❌ Error en getRecentTrades: $e');
      throw Exception('Error cargando el mercado: $e');
    }
  }
}