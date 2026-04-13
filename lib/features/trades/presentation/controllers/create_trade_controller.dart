import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../profile/presentation/controllers/my_posts_controller.dart';
import '../../data/storage_repository.dart';
import '../../data/trade_repository.dart';

class CreateTradeController extends StateNotifier<AsyncValue<void>> {
  final TradeRepository _tradeRepo;
  final StorageRepository _storageRepo;

  CreateTradeController(this._tradeRepo, this._storageRepo) : super(const AsyncData(null));

  Future<bool> createPost({
    required String offer,
    required String request,
    required String description,
    File? image,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      String? imageUrl;

      // 1. Si hay imagen, la subimos primero
      if (image != null) {
        imageUrl = await _storageRepo.uploadTradeImage(image);
      }

      // 2. Creamos el registro en la tabla 'trades'
      await _tradeRepo.createTrade(
        offer: offer,
        request: request,
        description: description,
        imageUrl: imageUrl,
      );
    });

    state = result;
    return !result.hasError;
  }
}

final createTradeControllerProvider = StateNotifierProvider<CreateTradeController, AsyncValue<void>>((ref) {
  return CreateTradeController(
    ref.watch(tradeRepositoryProvider),
    ref.watch(storageRepositoryProvider),
  );
});