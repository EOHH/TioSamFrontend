import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/models/shop_item.dart';
import '../../data/shop_repository.dart';
import '../../../../core/widgets/custom_input.dart';

class CreateOfferModal extends HookConsumerWidget {
  final ShopItem item;

  const CreateOfferModal({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final isLoading = ref.watch(makeOfferProvider).isLoading;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),

            Text("Hacer una oferta a ${item.ownerUsername}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Por: ${item.offerItemName}", style: TextStyle(color: Theme.of(context).primaryColor)),
            const SizedBox(height: 24),

            CustomInput(
              controller: messageController,
              label: "¿Qué carta ofreces a cambio y por qué?",
              icon: LucideIcons.messageSquare,
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final text = messageController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe un mensaje para tu oferta')));
                    return;
                  }

                  final success = await ref.read(makeOfferProvider.notifier).makeOffer(item.id, text);

                  if (success && context.mounted) {
                    Navigator.pop(context); // Cierra el modal
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Oferta enviada con éxito! 🚀'), backgroundColor: Colors.green)
                    );
                  }
                },
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Enviar Oferta", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}