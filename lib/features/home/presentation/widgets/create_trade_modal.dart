import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/create_trade_controller.dart';
import '../controllers/home_feed_controller.dart';
import '../../../../core/widgets/custom_input.dart';

class CreateTradeModal extends HookConsumerWidget {
  const CreateTradeModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerController = useTextEditingController();
    final requestController = useTextEditingController();
    final descController = useTextEditingController();
    final imageFile = useState<File?>(null);
    final isLoading = ref.watch(createTradeControllerProvider).isLoading;

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) imageFile.value = File(picked.path);
    }

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
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Nueva Publicación", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Selector de Imagen
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), style: BorderStyle.solid),
                ),
                child: imageFile.value != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(imageFile.value!, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.camera, color: Theme.of(context).primaryColor), const Text("Añadir foto de la carta")]),
              ),
            ),
            const SizedBox(height: 20),
            CustomInput(controller: offerController, label: "¿Qué ofreces? (Ej: Goku Ultra Instinct)", icon: LucideIcons.package),
            const SizedBox(height: 15),
            CustomInput(controller: requestController, label: "¿Qué buscas? (Ej: Vegeta Blue)", icon: LucideIcons.search),
            const SizedBox(height: 15),
            CustomInput(controller: descController, label: "Descripción adicional", icon: LucideIcons.text),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final success = await ref.read(createTradeControllerProvider.notifier).createPost(
                    offer: offerController.text,
                    request: requestController.text,
                    description: descController.text,
                    image: imageFile.value,
                  );
                  if (success) {
                    ref.invalidate(homeFeedProvider); // Recarga el feed automáticamente
                    Navigator.pop(context);
                  }
                },
                child: isLoading ? const CircularProgressIndicator() : const Text("Publicar Intercambio"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}