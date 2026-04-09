import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../trades/data/offer_repository.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends HookConsumerWidget {
  final String offerId;
  final String contactName;
  final String contactAvatar;

  const ChatScreen({
    super.key,
    required this.offerId,
    required this.contactName,
    required this.contactAvatar,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final chatState = ref.watch(chatMessagesProvider(offerId));
    final chatAction = ref.read(chatActionProvider);
    final myUserId = chatAction.currentUserId;

    void sendMessage() {
      final text = messageController.text.trim();
      if (text.isNotEmpty) {
        chatAction.sendMessage(offerId, text);
        messageController.clear();
      }
    }

    // Función para mostrar el modal de confirmación
    void _confirmCompletion() {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Row(
            children: [
              // Usamos Icons nativos de Flutter para evitar errores con librerías externas
              Icon(Icons.handshake, color: Colors.blue),
              SizedBox(width: 10),
              Text('¿Cerrar el Trato?')
            ],
          ),
          content: Text('¿Ya realizaste el intercambio con $contactName? Esto sumará +1 a la reputación de ambos y cerrará esta oferta.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aún no', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                Navigator.pop(dialogContext); // Cierra el modal

                // Llamamos a nuestra función RPC
                await ref.read(offerRepositoryProvider).completeTrade(offerId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Intercambio completado exitosamente! 🎉'), backgroundColor: Colors.blue),
                  );
                  context.pop(); // Saca al usuario del chat y lo devuelve a la lista
                }
              },
              child: const Text('Sí, completado'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: CachedNetworkImageProvider(contactAvatar),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            const SizedBox(width: 12),
            Text(contactName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        elevation: 1,
        shadowColor: Colors.black26,
        // Botón de apretón de manos en el AppBar
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCircle2, color: Colors.blueAccent),
            tooltip: 'Marcar como Completado',
            onPressed: _confirmCompletion,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                      child: Text(
                          "¡Di hola para comenzar el intercambio!\nTraten de acordar un lugar seguro.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)
                      )
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(radius: 14, backgroundImage: CachedNetworkImageProvider(contactAvatar)),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                              decoration: BoxDecoration(
                                color: isMe ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 20),
                                ),
                                border: isMe ? null : Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.message,
                                    style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(msg.createdAt),
                                        style: TextStyle(color: isMe ? Colors.white70 : Colors.white54, fontSize: 10),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        const Icon(LucideIcons.checkCheck, size: 12, color: Colors.white70),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: "Escribe un mensaje...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}