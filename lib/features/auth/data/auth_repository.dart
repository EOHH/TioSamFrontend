import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  // Stream para que la app reaccione a cambios de sesión (Login/Logout)
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Obtener sesión actual
  Session? get currentSession => _client.auth.currentSession;

  // Registro: Crea usuario en Auth y luego inserta en tabla pública 'users'
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.user != null) {
      // Inserción profesional en tu tabla personalizada
      await _client.from('users').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
        'avatar_url': 'https://ui-avatars.com/api/?name=$username',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return response;
  }

  // Inicio de sesión simple
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

// Provider para acceder al repositorio desde cualquier lugar
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});