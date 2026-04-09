import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client;
  ChatRepository(this._client);

  String get currentUserId => _client.auth.currentUser!.id;

  // Escucha mensajes en TIEMPO REAL
  Stream<List<ChatMessage>> getMessagesStream(String offerId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('offer_id', offerId)
        .order('created_at', ascending: false) // descendente para que los nuevos salgan abajo
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }

  // Enviar mensaje
  Future<void> sendMessage(String offerId, String message) async {
    await _client.from('chat_messages').insert({
      'offer_id': offerId,
      'sender_id': currentUserId,
      'message': message,
    });
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});