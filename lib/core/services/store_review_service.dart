import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StoreReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Llama a esta función cuando el usuario hace algo positivo (ej. cerrar un trato)
  static Future<void> askForReviewIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Contamos cuántos tratos exitosos ha tenido en esta instalación
      final tradesCompleted = prefs.getInt('trades_completed_count') ?? 0;
      final newCount = tradesCompleted + 1;

      await prefs.setInt('trades_completed_count', newCount);

      // 🔥 LÓGICA ESTRATÉGICA:
      // Pedimos la reseña en su primer trato exitoso, y luego cada 5 tratos.
      if (newCount == 1 || newCount % 5 == 0) {
        // Verificamos si el dispositivo soporta las reseñas in-app
        if (await _inAppReview.isAvailable()) {
          // Congelamos 1 segundo para que la alerta no se solape bruscamente con otras animaciones
          await Future.delayed(const Duration(seconds: 1));
          await _inAppReview.requestReview();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al solicitar reseña de la tienda: $e");
      }
      // Si falla, lo ignoramos silenciosamente para no arruinar la experiencia del usuario
    }
  }
}