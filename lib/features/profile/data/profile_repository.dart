import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/user_profile.dart';
import '../../../core/utils/image_compressor.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client.from('users').select().eq('id', user.id).single();
    return UserProfile.fromJson(response);
  }

  // NUEVO 1: Subir imagen de Avatar al Storage
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final userId = _client.auth.currentUser!.id;

      // 🔥 LA MAGIA OCURRE AQUÍ: Aplastamos la imagen antes de subirla
      final compressedFile = await ImageCompressor.compressImage(imageFile, quality: 60);

      // Le forzamos la extensión .jpg porque nuestro compresor la convierte a ese formato
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$fileName';

      // Subimos el archivo comprimido en vez del original
      await _client.storage.from('avatars').upload(path, compressedFile);
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  // 🔥 NUEVO 2: Actualizar datos en la tabla Users
  Future<void> updateProfile({required String username, String? email, String? avatarUrl}) async {
    final userId = _client.auth.currentUser!.id;
    
    // Si el usuario proporcionó un correo, actualizar de forma segura mediante Supabase Auth
    if (email != null && email.isNotEmpty) {
      try {
        await _client.auth.updateUser(UserAttributes(email: email));
      } on AuthException catch (e) {
        print('AuthException al actualizar el correo: ${e.message}');
      } catch (e) {
        print('Error inesperado al actualizar el correo: $e');
      }
    }

    final updates = <String, dynamic>{'username': username};

    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    // Se actualizan los demás campos en la tabla pública users sin el email
    await _client.from('users').update(updates).eq('id', userId);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});