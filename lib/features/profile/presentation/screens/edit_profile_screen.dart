import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/user_profile.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends HookConsumerWidget {
  final UserProfile currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializamos los inputs con los datos actuales
    final nameController = useTextEditingController(text: currentProfile.username);
    final emailController = useTextEditingController(text: currentProfile.email);
    final selectedImage = useState<File?>(null);

    final isLoading = ref.watch(editProfileProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        selectedImage.value = File(picked.path);
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Editar Perfil', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF5E2BFF))),
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF5E2BFF)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- SECTOR DEL AVATAR PREMIUM ---
            Center(
              child: GestureDetector(
                onTap: isLoading ? null : pickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5E2BFF), Color(0xFF00C2FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF5E2BFF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                        backgroundImage: selectedImage.value != null
                            ? FileImage(selectedImage.value!) as ImageProvider
                            : CachedNetworkImageProvider(currentProfile.avatarUrl),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5E2BFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE), width: 4),
                        ),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Toca para cambiar foto', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
            
            const SizedBox(height: 40),

            // --- FORMULARIO PREMIUM ---
            _buildPremiumTextField(
              controller: nameController,
              label: 'Nombre de Usuario',
              icon: LucideIcons.user,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _buildPremiumTextField(
              controller: emailController,
              label: 'Correo Electrónico',
              icon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
            ),

            const SizedBox(height: 50),

            // --- BOTÓN GUARDAR PREMIUM ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final newName = nameController.text.trim();
                  final newEmail = emailController.text.trim();

                  if (newName.isEmpty || newEmail.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Los campos no pueden estar vacíos'), backgroundColor: Colors.orange));
                    return;
                  }

                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un correo válido'), backgroundColor: Colors.orange));
                    return;
                  }

                  FocusScope.of(context).unfocus();

                  final success = await ref.read(editProfileProvider.notifier).updateProfileData(
                    newName,
                    newEmail,
                    selectedImage.value,
                  );

                  if (success && context.mounted) {
                    ref.invalidate(currentProfileProvider);
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('¡Perfil actualizado con éxito! ✨', style: GoogleFonts.poppins()),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      )
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E2BFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: const Color(0xFF5E2BFF).withOpacity(0.5),
                ),
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Guardar Cambios", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFF5E2BFF), size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF5E2BFF), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }
}