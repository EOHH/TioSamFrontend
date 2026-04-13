import 'dart:io'; // IMPORTANTE: Usamos dart:io para File
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../trades/data/storage_repository.dart';
import '../domain/models/collection_item.dart';

class CollectionRepository {
  final SupabaseClient _client;
  final StorageRepository _storageRepo;

  CollectionRepository(this._client, this._storageRepo);

  Future<List<CollectionItem>> getUserCollection(String userId) async {
    final response = await _client
        .from('collections')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => CollectionItem.fromJson(json)).toList();
  }

  // Ahora recibe un File nativo
  Future<void> addToCollection({
    required String cardName,
    String? description,
    required File imageFile,
  }) async {
    final userId = _client.auth.currentUser!.id;

    // Pasamos el File directo a tu función existente
    final imageUrl = await _storageRepo.uploadTradeImage(imageFile);

    if (imageUrl == null) throw Exception("Error al subir la imagen");

    await _client.from('collections').insert({
      'user_id': userId,
      'card_name': cardName,
      'description': description,
      'image_url': imageUrl,
    });
  }

  // NUEVO: Eliminar carta de la vitrina
  Future<void> deleteFromCollection(String itemId) async {
    // Solo borramos el registro donde el ID coincida y pertenezca al usuario actual (seguridad)
    final userId = _client.auth.currentUser!.id;
    await _client.from('collections').delete().match({'id': itemId, 'user_id': userId});
  }
}

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(storageRepositoryProvider),
  );
});