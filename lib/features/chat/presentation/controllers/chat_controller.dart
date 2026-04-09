import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/chat_repository.dart';
import '../../domain/models/chat_message.dart';

// StreamProvider para escuchar datos en vivo
final chatMessagesProvider = StreamProvider.family.autoDispose<List<ChatMessage>, String>((ref, offerId) {
  return ref.watch(chatRepositoryProvider).getMessagesStream(offerId);
});

// Provider para la acción de enviar
final chatActionProvider = Provider.autoDispose((ref) {
  return ref.watch(chatRepositoryProvider);
});