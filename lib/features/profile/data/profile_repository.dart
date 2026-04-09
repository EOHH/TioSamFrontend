import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/user_profile.dart';

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
      final extension = imageFile.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = '$userId/$fileName'; // Guarda en una subcarpeta con el ID del usuario

      await _client.storage.from('avatars').upload(path, imageFile);
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  // NUEVO 2: Actualizar datos en la tabla Users
  Future<void> updateProfile({required String username, String? avatarUrl}) async {
    final userId = _client.auth.currentUser!.id;
    final updates = <String, dynamic>{'username': username};

    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    await _client.from('users').update(updates).eq('id', userId);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});