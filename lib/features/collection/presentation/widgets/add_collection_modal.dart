import 'dart:io'; // Importante para File
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/collection_controller.dart';
import '../../../../core/widgets/custom_input.dart';

class AddCollectionModal extends HookConsumerWidget {
  const AddCollectionModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final descController = useTextEditingController();

    // Ahora guardamos un File
    final selectedImage = useState<File?>(null);
    final isLoading = ref.watch(addCollectionProvider).isLoading;

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (picked != null) {
        selectedImage.value = File(picked.path); // Convertimos XFile a File nativo
      }
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
            const Text("Añadir a mi Vitrina", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                ),
                child: selectedImage.value != null
                    ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(selectedImage.value!, fit: BoxFit.cover) // Mostramos el File
                )
                    : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.imagePlus, size: 40, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 8),
                      const Text("Sube la foto de tu carta")
                    ]
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomInput(controller: nameController, label: "Nombre de la carta (Ej: Pikachu VMAX)", icon: LucideIcons.creditCard),
            const SizedBox(height: 15),
            CustomInput(controller: descController, label: "Historia o detalles (Opcional)", icon: LucideIcons.text),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (nameController.text.isEmpty || selectedImage.value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta el nombre o la imagen')));
                    return;
                  }

                  final success = await ref.read(addCollectionProvider.notifier).addCard(
                    cardName: nameController.text.trim(),
                    description: descController.text.trim(),
                    imageFile: selectedImage.value!,
                  );

                  if (success && context.mounted) {
                    ref.invalidate(myCollectionProvider);
                    Navigator.pop(context);
                  }
                },
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Guardar en Vitrina", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}