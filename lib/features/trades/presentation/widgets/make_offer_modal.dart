import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/create_offer_controller.dart';
import '../../../../core/widgets/custom_input.dart';
// 👇 IMPORTANTE: Importamos la pantalla de Trades para poder invalidar su caché
import '../screens/trades_screen.dart';

class MakeOfferModal extends HookConsumerWidget {
  final String tradeId;
  final String ownerUsername;
  final String offerItemName;

  const MakeOfferModal({
    super.key,
    required this.tradeId,
    required this.ownerUsername,
    required this.offerItemName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final isLoading = ref.watch(createOfferControllerProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<void>>(
      createOfferControllerProvider,
          (previous, next) {
        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar oferta: ${next.error}'), backgroundColor: Colors.redAccent),
          );
        }
      },
    );

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // Bordes más redondeados
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5)),
          ]
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea indicadora de arrastre (Grabber)
            Center(
                child: Container(
                    width: 48, height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10)
                    )
                )
            ),
            const SizedBox(height: 24),

            // Título con Ícono moderno
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.arrowRightLeft, color: Colors.blueAccent, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text("Proponer Intercambio", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Caja de contexto enriquecida
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey?.withOpacity(0.5) : Colors.grey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1))
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.info, size: 20, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.4),
                        children: [
                          const TextSpan(text: "Estás a punto de hacerle una oferta a "),
                          TextSpan(text: ownerUsername, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          const TextSpan(text: " por su "),
                          TextSpan(text: offerItemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: messageController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Mensaje de tu oferta (Ej: Te ofrezco mi carta X...)",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(LucideIcons.messageSquare, color: Colors.blueAccent),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : const Color(0xFFF6F8FF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón de acción Premium
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () async {
                  if (messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor escribe un mensaje para tu oferta')),
                    );
                    return;
                  }

                  FocusScope.of(context).unfocus();

                  final success = await ref.read(createOfferControllerProvider.notifier).sendOffer(
                      tradeId,
                      messageController.text.trim()
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(LucideIcons.checkCircle2, color: Colors.white),
                            SizedBox(width: 8),
                            Text('¡Oferta enviada con éxito!', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating, // Estilo de notificación moderno
                      ),
                    );

                    // 🔥 LA MAGIA DEL CACHÉ: Le avisamos a la pestaña de "Enviados" que se actualice de inmediato
                    ref.invalidate(sentOffersProvider);
                  }
                },
                icon: isLoading
                    ? const SizedBox.shrink()
                    : const Icon(LucideIcons.send, color: Colors.white, size: 20),
                label: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Enviar Propuesta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    elevation: 4,
                    shadowColor: Colors.blueAccent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}