import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/models/user_profile.dart';
import '../controllers/profile_controller.dart';
import '../../../../core/widgets/custom_input.dart';

class EditProfileScreen extends HookConsumerWidget {
  final UserProfile currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializamos el input con el nombre actual
    final nameController = useTextEditingController(text: currentProfile.username);
    final selectedImage = useState<File?>(null);

    final isLoading = ref.watch(editProfileProvider).isLoading;

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        selectedImage.value = File(picked.path);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // SECTOR DEL AVATAR
            GestureDetector(
              onTap: isLoading ? null : pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).primaryColor, width: 3)),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      // Si seleccionó una foto, muestra el File. Si no, muestra la URL de Supabase.
                      backgroundImage: selectedImage.value != null
                          ? FileImage(selectedImage.value!) as ImageProvider
                          : CachedNetworkImageProvider(currentProfile.avatarUrl),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // FORMULARIO
            CustomInput(controller: nameController, label: "Nombre de Usuario", icon: LucideIcons.user),
            const SizedBox(height: 40),

            // BOTÓN GUARDAR
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre no puede estar vacío')));
                    return;
                  }

                  final success = await ref.read(editProfileProvider.notifier).updateProfileData(
                    nameController.text.trim(),
                    selectedImage.value,
                  );

                  if (success && context.mounted) {
                    ref.invalidate(currentProfileProvider); // Refresca el perfil para que se vean los cambios
                    context.pop(); // Regresa a la pantalla anterior
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Perfil actualizado con éxito! ✨'), backgroundColor: Colors.green));
                  }
                },
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}