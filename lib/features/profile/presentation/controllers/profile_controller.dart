import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/user_profile.dart';

// FutureProvider ejecuta la petición asíncrona y guarda el resultado
final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getCurrentUserProfile();
});

// NUEVO: Controlador para Editar Perfil
class EditProfileController extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;

  EditProfileController(this._repository) : super(const AsyncData(null));

  Future<bool> updateProfileData(String newUsername, File? newImage) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      String? newAvatarUrl;

      // 1. Si el usuario seleccionó una foto, la subimos primero
      if (newImage != null) {
        newAvatarUrl = await _repository.uploadAvatar(newImage);
        if (newAvatarUrl == null) throw Exception("Error al subir el avatar");
      }

      // 2. Actualizamos el nombre (y la URL de la foto si hay una nueva)
      await _repository.updateProfile(username: newUsername, avatarUrl: newAvatarUrl);
    });

    state = result;
    return !result.hasError;
  }
}

// Su respectivo Provider con autoDispose
final editProfileProvider = StateNotifierProvider.autoDispose<EditProfileController, AsyncValue<void>>((ref) {
  return EditProfileController(ref.watch(profileRepositoryProvider));
});