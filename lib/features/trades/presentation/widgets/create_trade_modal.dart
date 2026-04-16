import 'dart:io'; // 👇 Importamos para manejar archivos (File)
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart'; // 👇 Importamos el Image Picker

import '../../../../core/widgets/custom_input.dart';
import '../../../market/data/market_repository.dart';
import '../../../profile/presentation/controllers/my_posts_controller.dart';
import '../controllers/create_trade_controller.dart';

class CreateTradeModal extends HookConsumerWidget {
  const CreateTradeModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerController = useTextEditingController();
    final requestController = useTextEditingController();
    final descriptionController = useTextEditingController();

    final selectedCategory = useState<String?>(null);

    // 👇 ESTADOS PARA LA IMAGEN
    final selectedImage = useState<File?>(null);
    final picker = useMemoized(() => ImagePicker());

    final categoriesState = ref.watch(categoriesProvider);
    final controllerState = ref.watch(createTradeControllerProvider);

    // 👇 FUNCIÓN PARA SELECCIONAR LA IMAGEN
    Future<void> pickImage() async {
      try {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          selectedImage.value = File(pickedFile.path);
        }
      } catch (e) {
        debugPrint("Error al seleccionar imagen: $e");
      }
    }

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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Text("Nueva Publicación", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // 🔥 SELECTOR DE IMAGEN VISUAL
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: selectedImage.value != null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(selectedImage.value!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => selectedImage.value = null, // Botón para quitar foto
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                        ),
                      ),
                    )
                  ],
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.imagePlus, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Añadir foto de la carta (Opcional)', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            CustomInput(controller: offerController, label: "¿Qué ofreces?", icon: LucideIcons.gift),
            const SizedBox(height: 16),
            CustomInput(controller: requestController, label: "¿Qué buscas?", icon: LucideIcons.search),
            const SizedBox(height: 16),

            // SELECTOR DE CATEGORÍA
            categoriesState.when(
              data: (categories) {
                final validCats = categories.where((c) => c != 'Todas').toList();
                if (validCats.isEmpty) validCats.add('General');

                final currentValue = (selectedCategory.value != null && validCats.contains(selectedCategory.value))
                    ? selectedCategory.value
                    : validCats.first;

                return DropdownButtonFormField<String>(
                  value: currentValue,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: const Icon(LucideIcons.tag, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: validCats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) selectedCategory.value = val;
                  },
                );
              },
              loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('Error cargando categorías: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción (Opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controllerState.isLoading ? null : () async {
                  if (offerController.text.trim().isEmpty || requestController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena los campos obligatorios')));
                    return;
                  }

                  final finalCategory = selectedCategory.value ?? 'General';

                  // 🔥 AQUÍ PASAMOS LA IMAGEN (imagePath) AL CONTROLADOR
                  final success = await ref.read(createTradeControllerProvider.notifier).createTrade(
                    offer: offerController.text.trim(),
                    request: requestController.text.trim(),
                    category: finalCategory,
                    description: descriptionController.text.trim(),
                    imagePath: selectedImage.value?.path, // 👇 EL DATO CRUCIAL
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ref.refresh(marketFeedProvider); // Actualizar mercado
                    ref.refresh(homeFeedProvider);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: controllerState.isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Publicar Carta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}