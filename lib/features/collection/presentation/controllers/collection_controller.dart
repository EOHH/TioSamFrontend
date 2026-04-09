import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/collection_repository.dart';
import '../../domain/models/collection_item.dart';

// 1. Aplicado .autoDispose para limpiar datos al salir de la pestaña
final myCollectionProvider = FutureProvider.autoDispose<List<CollectionItem>>((ref) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final currentUserId = Supabase.instance.client.auth.currentUser!.id;
  return repository.getUserCollection(currentUserId);
});

class AddCollectionController extends StateNotifier<AsyncValue<void>> {
  final CollectionRepository _repository;

  AddCollectionController(this._repository) : super(const AsyncData(null));

  Future<bool> addCard({
    required String cardName,
    String? description,
    required File imageFile,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() =>
        _repository.addToCollection(
          cardName: cardName,
          description: description,
          imageFile: imageFile,
        )
    );

    state = result;
    return !result.hasError;
  }
}

// 2. Aplicado .autoDispose al estado del modal
final addCollectionProvider = StateNotifierProvider.autoDispose<AddCollectionController, AsyncValue<void>>((ref) {
  return AddCollectionController(ref.watch(collectionRepositoryProvider));
});