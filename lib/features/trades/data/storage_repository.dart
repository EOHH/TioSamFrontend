import 'dart:io';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

class StorageRepository {
  final SupabaseClient _client;
  StorageRepository(this._client);

  Future<String?> uploadTradeImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'trades/$fileName';

      // Subir el archivo al bucket 'trade_images'
      await _client.storage.from('trade_images').upload(path, imageFile);

      // Obtener la URL pública
      final imageUrl = _client.storage.from('trade_images').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en StorageRepository: $e');
      }
      return null;
    }
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref.watch(supabaseClientProvider));
});