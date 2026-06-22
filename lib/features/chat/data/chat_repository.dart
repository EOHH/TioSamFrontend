import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client;
  ChatRepository(this._client);

  String get currentUserId => _client.auth.currentUser!.id;

  Stream<List<ChatMessage>> getMessagesStream(String offerId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('offer_id', offerId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }

  // 👇 Lógica de subida múltiple (Texto, Imagen o Audio)
  Future<void> sendMessage({
    required String offerId,
    String? message,
    File? imageFile,
    File? audioFile,
  }) async {
    String? imageUrl;
    String? audioUrl;

    // 1. Si hay imagen, la subimos al Bucket 'chat_media'
    if (imageFile != null) {
      final ext = imageFile.path.split('.').last;
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '$offerId/$fileName'; // Organizamos por carpetas usando el offerId

      await _client.storage.from('chat_media').upload(path, imageFile);
      imageUrl = _client.storage.from('chat_media').getPublicUrl(path);
    }

    // 2. Si hay audio, lo subimos
    if (audioFile != null) {
      final ext = audioFile.path.split('.').last;
      final fileName = 'aud_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '$offerId/$fileName';

      await _client.storage.from('chat_media').upload(path, audioFile);
      audioUrl = _client.storage.from('chat_media').getPublicUrl(path);
    }

    // 3. Guardamos el registro en la base de datos
    await _client.from('chat_messages').insert({
      'offer_id': offerId,
      'sender_id': currentUserId,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      if (imageUrl != null) 'image_url': imageUrl,
      if (audioUrl != null) 'audio_url': audioUrl,
    });
  }

  // 👇 Función para eliminar mensaje y su imagen (si tiene)
  Future<void> deleteMessage(String messageId, String? imageUrl) async {
    try {
      // 1. Si el mensaje tiene una imagen, la borramos del Bucket primero
      if (imageUrl != null) {
        // Extraemos la ruta exacta del archivo de forma robusta usando Uri
        final uri = Uri.parse(imageUrl);
        final segments = uri.pathSegments;
        final bucketIndex = segments.indexOf('chat_media');
        
        if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
          final path = segments.sublist(bucketIndex + 1).join('/');
          await _client.storage.from('chat_media').remove([path]);
        }
      }

      // 2. Borramos el registro de la tabla chat_messages con filtro de seguridad
      await _client
          .from('chat_messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', currentUserId); // Filtro obligatorio para AppSec

    } catch (e) {
      throw Exception('Error al eliminar el mensaje: $e');
    }
  }

  // 👇 NUEVA FUNCIÓN PARA LOS CHECKS AZULES
  Future<void> markMessagesAsRead(String offerId) async {
    try {
      await _client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('offer_id', offerId)
          .neq('sender_id', currentUserId) // Solo marcamos los que NO envié yo
          .eq('is_read', false); // Solo actualizamos los que están en false para no saturar la BD
    } catch (e) {
      // Ignoramos el error silenciosamente para no interrumpir la UX
      print("Error al marcar como leídos: $e");
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});