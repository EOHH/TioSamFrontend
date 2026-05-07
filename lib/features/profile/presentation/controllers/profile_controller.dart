import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 👇 Importamos Supabase para escuchar la sesión
import '../../data/profile_repository.dart';
import '../../domain/models/user_profile.dart';

// 🔥 VIGILANTE DE SESIÓN (Login/Logout)
final authStateProvider = StreamProvider.autoDispose((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// =====================================================================
// 1. PROVEEDOR DEL PERFIL ACTUAL
// =====================================================================
final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  // 🔥 1. Si el usuario cambia de cuenta, se borra la caché automáticamente
  ref.watch(authStateProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;

  // Si no hay sesión iniciada, devolvemos null inmediatamente
  if (userId == null) return null;

  // 🔥 2. Mantenemos en memoria para que no parpadee al cambiar de pestaña
  ref.keepAlive();

  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getCurrentUserProfile();
});

// =====================================================================
// 2. CONTROLADOR PARA EDITAR EL PERFIL
// =====================================================================
class EditProfileController extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;

  EditProfileController(this._repository) : super(const AsyncData(null));

  // 🔥 AHORA RECIBE EL CORREO COMO SEGUNDO PARÁMETRO
  Future<bool> updateProfileData(String newUsername, String newEmail, File? newImage) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final supabase = Supabase.instance.client;
      final currentUserEmail = supabase.auth.currentUser?.email;

      String? newAvatarUrl;

      // 1. Si el usuario seleccionó una foto, la subimos primero
      if (newImage != null) {
        newAvatarUrl = await _repository.uploadAvatar(newImage);
        if (newAvatarUrl == null) throw Exception("Error al subir el avatar");
      }

      await _repository.updateProfile(username: newUsername, email: newEmail, avatarUrl: newAvatarUrl);

      // 🔥 3. ACTUALIZAMOS EL CORREO DE AUTENTICACIÓN (SUPER IMPORTANTE)
      // Solo hacemos la llamada si el correo realmente cambió
      if (newEmail != currentUserEmail && newEmail.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(email: newEmail),
        );
        // Supabase enviará automáticamente un correo de confirmación a la nueva dirección.
      }
    });

    state = result;
    return !result.hasError;
  }
}

// Su respectivo Provider con autoDispose
final editProfileProvider = StateNotifierProvider.autoDispose<EditProfileController, AsyncValue<void>>((ref) {
  return EditProfileController(ref.watch(profileRepositoryProvider));
});