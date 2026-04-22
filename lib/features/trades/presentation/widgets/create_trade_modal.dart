import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/custom_input.dart';
import '../../../market/data/market_repository.dart';
import '../../../profile/presentation/controllers/my_posts_controller.dart';
import '../controllers/create_trade_controller.dart';

class CreateTradeModal extends HookConsumerWidget {
  const CreateTradeModal({super.key});

  // ✨ DIÁLOGO PREMIUM PARA MANDARLOS A LA TIENDA
  void _showLimitReachedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.lock, size: 48, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Vitrina Llena!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Aquí el usuario irá a la tienda
                },
                icon: const Icon(LucideIcons.store, color: Colors.white),
                label: const Text(
                  'Visitar la Tienda',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Quizás más tarde',
                style: TextStyle(color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerController = useTextEditingController();
    final requestController = useTextEditingController();
    final descriptionController = useTextEditingController();

    final selectedCategory = useState<String?>(null);
    final selectedImage = useState<File?>(null);
    final picker = useMemoized(() => ImagePicker());

    final categoriesState = ref.watch(categoriesProvider);
    final controllerState = ref.watch(createTradeControllerProvider);

    // 🔥 TU SOLUCIÓN LÓGICA IMPLEMENTADA AQUÍ
    ref.listen<AsyncValue<void>>(
      createTradeControllerProvider,
          (previous, next) {
        if (next is AsyncError) {
          final rawError = next.error.toString().replaceAll('Exception: ', '');

          if (rawError.startsWith('LIMIT_REACHED|')) {
            final List<String> errorParts = rawError.split('|');

            final String cleanMessage =
            errorParts.length > 1
                ? errorParts.sublist(1).join('|')
                : 'Has alcanzado tu límite de publicaciones. Expande tu vitrina en la tienda.';

            Navigator.pop(context);
            _showLimitReachedDialog(context, cleanMessage);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.alertOctagon, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rawError,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      },
    );

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Nueva Publicación",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 160, width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey?.withOpacity(0.5) : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                ),
                child: selectedImage.value != null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(selectedImage.value!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: GestureDetector(
                        onTap: () => selectedImage.value = null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                          child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.imagePlus, size: 32, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 12),
                    const Text('Añadir foto de la carta', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('(Opcional pero recomendado)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔥 CAMPOS CON DISEÑO RESTAURADO
            CustomInput(controller: offerController, label: "¿Qué ofreces? (Ej: Pikachu Holográfico)", icon: LucideIcons.gift),
            const SizedBox(height: 16),
            CustomInput(controller: requestController, label: "¿Qué buscas? (Ej: Charizard 1ra Edición)", icon: LucideIcons.search),
            const SizedBox(height: 16),

            categoriesState.when(
              data: (categories) {
                final validCats = categories.where((c) => c != 'Todas').toList();
                if (validCats.isEmpty) validCats.add('General');

                final currentValue = (selectedCategory.value != null && validCats.contains(selectedCategory.value))
                    ? selectedCategory.value : validCats.first;

                return DropdownButtonFormField<String>(
                  value: currentValue,
                  icon: const Icon(LucideIcons.chevronDown, color: Colors.grey),
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: const Icon(LucideIcons.tag, size: 20, color: Colors.blueAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: validCats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                  onChanged: (val) { if (val != null) selectedCategory.value = val; },
                );
              },
              loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => Container(
                width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('Error cargando categorías: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción (Estado de la carta, detalles...)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: controllerState.isLoading ? null : () async {
                  if (offerController.text.trim().isEmpty || requestController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor llena qué ofreces y qué buscas.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  FocusScope.of(context).unfocus();

                  final success = await ref.read(createTradeControllerProvider.notifier)
                      .createTrade(
                    offer: offerController.text.trim(),
                    request: requestController.text.trim(),
                    category: selectedCategory.value ?? 'General',
                    description: descriptionController.text.trim(),
                    imagePath: selectedImage.value?.path,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Publicación creada exitosamente! 🚀'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    ref.refresh(marketFeedProvider);
                    ref.refresh(myHistoryFeedProvider);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: controllerState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Publicar Carta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}