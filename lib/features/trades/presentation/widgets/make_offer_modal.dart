import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/create_offer_controller.dart';
import '../../../../core/widgets/custom_input.dart';

class MakeOfferModal extends HookConsumerWidget {
  // Ahora pide datos universales en vez del modelo completo
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

    ref.listen<AsyncValue<void>>(
      createOfferControllerProvider,
          (previous, next) {
        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar oferta: ${next.error}'), backgroundColor: Colors.red),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))
                )
            ),
            const SizedBox(height: 24),

            const Text("Proponer Intercambio", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Estás a punto de hacer una oferta a $ownerUsername por su $offerItemName.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),

            CustomInput(
              controller: messageController,
              label: "Mensaje de tu oferta (Ej: Te ofrezco mi carta X...)",
              icon: LucideIcons.messageSquare,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
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
                          content: Text('¡Oferta enviada con éxito!'),
                          backgroundColor: Colors.green
                      ),
                    );
                  }
                },
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Enviar Propuesta", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}