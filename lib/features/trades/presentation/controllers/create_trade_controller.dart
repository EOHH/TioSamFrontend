import 'dart:io'; // 👇 Importamos para manejar File
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/trade_repository.dart';
import '../../data/storage_repository.dart'; // 👇 Importamos tu Storage
import '../../../../core/services/analytics_service.dart';

class CreateTradeController extends StateNotifier<AsyncValue<void>> {
  final TradeRepository _tradeRepository;
  final StorageRepository _storageRepository;
  final AnalyticsService _analyticsService;

  // Recibimos AMBOS repositorios
  CreateTradeController(this._tradeRepository, this._storageRepository, this._analyticsService) : super(const AsyncData(null));

  Future<bool> createTrade({
    required String offer,
    required String request,
    required String category,
    String? description,
    String? imagePath, // La ruta local de la foto en el celular
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      String? finalImageUrl;

      // 🔥 1. PROCESAMOS LA IMAGEN (Si el usuario seleccionó una)
      if (imagePath != null && imagePath.isNotEmpty) {
        final imageFile = File(imagePath); // Convertimos el String a File
        finalImageUrl = await _storageRepository.uploadTradeImage(imageFile);

        // Si finalImageUrl sigue siendo null aquí, hubo un error en Storage
        if (finalImageUrl == null) {
          throw Exception("Error al subir la imagen al servidor.");
        }
      }

      // 🔥 2. GUARDAMOS EN BASE DE DATOS
      final tradeId = await _tradeRepository.createTrade(
        offer: offer,
        request: request,
        category: category,
        description: description,
        imageUrl: finalImageUrl, // ¡Le pasamos la URL real a la BD!
      );
      
      // 🔥 3. REGISTRAMOS ANALYTICS
      await _analyticsService.logTradeCreated(tradeId: tradeId);
    });

    state = result;
    return !result.hasError;
  }
}

// Actualizamos el Provider para inyectar ambos repositorios
final createTradeControllerProvider = StateNotifierProvider<CreateTradeController, AsyncValue<void>>((ref) {
  return CreateTradeController(
    ref.watch(tradeRepositoryProvider),
    ref.watch(storageRepositoryProvider),
    ref.watch(analyticsServiceProvider),
  );
});