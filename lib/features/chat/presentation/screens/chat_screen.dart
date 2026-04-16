import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../trades/data/offer_repository.dart';
import '../../data/chat_repository.dart';
import '../controllers/chat_controller.dart';
import '../controllers/presence_controller.dart';

// 👇 NUEVO PROVIDER PARA ESCUCHAR EL ESTADO DE LA OFERTA EN VIVO
final offerStatusProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, offerId) {
  final repository = ref.read(offerRepositoryProvider);
  return repository.watchOfferStatus(offerId);
});

// Colores exactos de WhatsApp
class WAColors {
  static const bubbleMeLight = Color(0xFFDCF8C6);
  static const bubbleMeDark = Color(0xFF056162);
  static const bubbleOtherLight = Colors.white;
  static const bubbleOtherDark = Color(0xFF262D31);
  static const micSeen = Color(0xFF34B7F1);
  static const micUnseen = Colors.grey;
  static const playBtn = Color(0xFF4FC3F7);
}

class ChatScreen extends HookConsumerWidget {
  final String offerId;
  final String contactName;
  final String contactAvatar;
  final String contactId;

  const ChatScreen({
    super.key,
    required this.offerId,
    required this.contactName,
    required this.contactAvatar,
    required this.contactId,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final isUploading = useState(false);

    final hasText = useState(false);
    final isRecording = useState(false);
    final audioRecorder = useMemoized(() => AudioRecorder());

    final chatState = ref.watch(chatMessagesProvider(offerId));
    final chatAction = ref.read(chatActionProvider);
    final myUserId = chatAction.currentUserId;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // MAGIA DE PRESENCIA: Escuchamos si está en línea
    final onlineUsers = ref.watch(presenceProvider);
    final isOnline = onlineUsers.contains(contactId);

    // 👇 ESCUCHAMOS LOS ESTADOS EN VIVO DESDE SUPABASE
    final offerData = ref.watch(offerStatusProvider(offerId)).asData?.value;
    final isCompleted = offerData?['status'] == 'completed';
    final isCancelled = offerData?['status'] == 'cancelled' || offerData?['status'] == 'rejected';

    // 🔥 LA MAGIA DE LOS PERMISOS: Solo el dueño de la publicación puede cerrar el trato
    // Comparamos el ID del ofertante con tu ID. Si NO eres el ofertante, significa que eres el dueño.
    final isOfferer = offerData?['offerer_id'] == myUserId;
    final isPostOwner = !isOfferer && offerData != null;

    final currentMessages = chatState.asData?.value ?? [];
    useEffect(() {
      if (currentMessages.isNotEmpty) {
        final unreadExist = currentMessages.any((m) => m.senderId != myUserId && !m.isRead);
        if (unreadExist) {
          ref.read(chatRepositoryProvider).markMessagesAsRead(offerId);
        }
      }
      return null;
    }, [currentMessages.length]);

    useEffect(() {
      void listener() {
        hasText.value = messageController.text.trim().isNotEmpty;
      }
      messageController.addListener(listener);
      return () {
        messageController.removeListener(listener);
        audioRecorder.dispose();
      };
    }, [messageController, audioRecorder]);

    Future<void> startRecording() async {
      try {
        if (await audioRecorder.hasPermission()) {
          final tempPath = '${Directory.systemTemp.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await audioRecorder.start(const RecordConfig(), path: tempPath);
          isRecording.value = true;
        }
      } catch (e) {
        debugPrint("Error al iniciar grabación: $e");
      }
    }

    Future<void> stopRecordingAndSend() async {
      try {
        final path = await audioRecorder.stop();
        isRecording.value = false;

        if (path != null) {
          isUploading.value = true;
          await chatAction.sendMessage(offerId: offerId, audioFile: File(path));
          isUploading.value = false;
        }
      } catch (e) {
        debugPrint("Error al detener grabación: $e");
        isUploading.value = false;
      }
    }

    void sendTextMessage() {
      final text = messageController.text.trim();
      if (text.isNotEmpty) {
        chatAction.sendMessage(offerId: offerId, message: text);
        messageController.clear();
      }
    }

    Future<void> sendImageMessage(ImageSource source) async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: source);

        if (pickedFile != null) {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Recortar imagen',
                toolbarColor: isDarkMode ? const Color(0xFF2A2F32) : const Color(0xFF00897B),
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false,
                hideBottomControls: false,
                aspectRatioPresets: [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9
                ],
              ),
              IOSUiSettings(
                title: 'Recortar',
                cancelButtonTitle: 'Cancelar',
                doneButtonTitle: 'Listo',
                aspectRatioPresets: [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9
                ],
              ),
            ],
          );

          if (croppedFile != null) {
            isUploading.value = true;
            await chatAction.sendMessage(offerId: offerId, imageFile: File(croppedFile.path));
          }
        }
      } catch (e) {
        debugPrint("Error subiendo imagen: $e");
      } finally {
        isUploading.value = false;
      }
    }

    void _showAttachmentOptions() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera, color: Colors.blue),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  sendImageMessage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: Colors.purple),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  sendImageMessage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    }

    void _confirmCompletion() {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Row(children: [Icon(Icons.handshake, color: Colors.blue), SizedBox(width: 10), Text('¿Cerrar el Trato?')]),
          content: Text('¿Ya realizaste el intercambio con $contactName? Esto cerrará la oferta de forma permanente.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Aún no', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                Navigator.pop(dialogContext); // Cerramos el primer diálogo
                try {
                  // 🔥 LLAMAMOS A LA NUEVA FUNCIÓN QUE CIERRA EL TRATO
                  await ref.read(offerRepositoryProvider).completeTrade(offerId);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Intercambio completado exitosamente! 🎉'), backgroundColor: Colors.blue));

                    // ¡MAGIA! Abrimos el modal para calificar al usuario
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true, // Para que el teclado no lo tape
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (bottomSheetContext) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom, // Evita el teclado
                          left: 20, right: 20, top: 20,
                        ),
                        child: HookBuilder( // Usamos HookBuilder para manejar las estrellas en vivo
                          builder: (hookContext) {
                            final rating = useState<int>(5); // 5 estrellas por defecto
                            final commentController = useTextEditingController();
                            final isSubmitting = useState(false);

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(radius: 30, backgroundImage: CachedNetworkImageProvider(contactAvatar)),
                                const SizedBox(height: 10),
                                Text('Califica a $contactName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),

                                // Estrellas interactivas
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return IconButton(
                                      icon: Icon(
                                        index < rating.value ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 40,
                                      ),
                                      onPressed: () => rating.value = index + 1,
                                    );
                                  }),
                                ),

                                const SizedBox(height: 10),
                                TextField(
                                  controller: commentController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: '¿Cómo fue tu experiencia?',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 15)),
                                    onPressed: isSubmitting.value ? null : () async {
                                      isSubmitting.value = true;
                                      try {
                                        // Enviamos la reseña a Supabase
                                        await ref.read(offerRepositoryProvider).submitReview(
                                          offerId: offerId,
                                          revieweeId: contactId,
                                          rating: rating.value,
                                          comment: commentController.text.trim(),
                                        );
                                        if (hookContext.mounted) {
                                          Navigator.pop(hookContext);
                                          ScaffoldMessenger.of(hookContext).showSnackBar(const SnackBar(content: Text('¡Gracias por tu reseña! ⭐'), backgroundColor: Colors.green));
                                        }
                                      } catch (e) {
                                        if (hookContext.mounted) {
                                          ScaffoldMessenger.of(hookContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                                        }
                                      } finally {
                                        isSubmitting.value = false;
                                      }
                                    },
                                    child: isSubmitting.value
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Enviar Calificación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Sí, completado'),
            ),
          ],
        ),
      );
    }

    void _cancelTrade() {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Row(children: [Icon(LucideIcons.xCircle, color: Colors.red), SizedBox(width: 10), Text('¿Cancelar Trato?')]),
          content: const Text('Si no llegaron a un acuerdo, puedes cancelar este trato. Tu carta volverá al mercado para recibir otras ofertas.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Volver', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  // 🔥 LLAMAMOS A LA NUEVA FUNCIÓN QUE CANCELA Y LIBERA LA CARTA
                  await ref.read(offerRepositoryProvider).cancelTrade(offerId);

                  if (context.mounted) {
                    context.pop(); // Sacamos al usuario de la pantalla de chat si la canceló
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intercambio cancelado. Tu carta está de vuelta en el mercado.'), backgroundColor: Colors.red));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Sí, cancelar'),
            ),
          ],
        ),
      );
    }

    Color getBubbleColor(bool isMe) {
      if (isMe) {
        return isDarkMode ? WAColors.bubbleMeDark : WAColors.bubbleMeLight;
      } else {
        return isDarkMode ? WAColors.bubbleOtherDark : WAColors.bubbleOtherLight;
      }
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF131C21) : const Color(0xFFE5DDD5),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop(); // Si estaba navegando normal, solo regresa
            } else {
              context.go('/trades'); // Si viene de la notificación, lo manda a la lista principal
            }
          },
        ),
        titleSpacing: 0,
        backgroundColor: isDarkMode ? const Color(0xFF2A2F32) : const Color(0xFFEDEDED),
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: CachedNetworkImageProvider(contactAvatar)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contactName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                if (isOnline)
                  const Text('en línea', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        elevation: 1,
        actions: [
          // 👇 LOS INDICADORES DE ESTADO EN LA BARRA SUPERIOR
          // 🔥 Solo mostramos el botón de completar SI eres el dueño del post
          if (!isCompleted && !isCancelled && isPostOwner)
            IconButton(
              icon: const Icon(LucideIcons.checkCircle2, color: Colors.blueAccent),
              tooltip: 'Marcar como Completado',
              onPressed: _confirmCompletion,
            )
          else if (isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: Row(
                  children: [
                    Icon(LucideIcons.award, color: Colors.amber, size: 20),
                    SizedBox(width: 4),
                    Text('Trato Cerrado', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),

          if (isCancelled)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: Row(
                  children: [
                    Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 20),
                    SizedBox(width: 4),
                    Text('Cancelado', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),

          if (!isCompleted && !isCancelled)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              color: Theme.of(context).colorScheme.surface,
              onSelected: (value) {
                if (value == 'cancel') {
                  _cancelTrade();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text('Cancelar Trato', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text("Envía un mensaje para comenzar el intercambio.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onLongPress: isMe ? () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    title: const Text('¿Eliminar mensaje?'),
                                    content: const Text('Esta acción eliminará el mensaje para ambos.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          try {
                                            await ref.read(chatRepositoryProvider).deleteMessage(msg.id, msg.imageUrl);
                                            ref.invalidate(chatMessagesProvider(offerId));
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                            }
                                          }
                                        },
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              } : null,
                              child: Container(
                                padding: msg.imageUrl != null ? const EdgeInsets.all(2) : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: getBubbleColor(isMe),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: Radius.circular(isMe ? 12 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 1,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (msg.imageUrl != null)
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => FullScreenImageViewer(
                                                    imageUrl: msg.imageUrl!,
                                                    heroTag: msg.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Hero(
                                              tag: msg.id,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: CachedNetworkImage(
                                                  imageUrl: msg.imageUrl!,
                                                  width: 250,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => const SizedBox(height: 150, width: 250, child: Center(child: CircularProgressIndicator())),
                                                ),
                                              ),
                                            ),
                                          ),

                                        if (msg.audioUrl != null)
                                          WAAudioPlayer(
                                            audioUrl: msg.audioUrl!,
                                            isMe: isMe,
                                            isRead: msg.isRead,
                                          ),

                                        if (msg.message != null && msg.message!.isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: 5,
                                              right: msg.audioUrl != null ? 5 : 65,
                                              top: msg.imageUrl != null ? 5 : 2,
                                              bottom: 2,
                                            ),
                                            child: Text(
                                              msg.message!,
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white : Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),

                                        if (msg.audioUrl == null)
                                          const SizedBox(height: 14),
                                      ],
                                    ),

                                    Positioned(
                                      bottom: msg.imageUrl != null ? 5 : 0,
                                      right: msg.imageUrl != null ? 8 : 0,
                                      child: Container(
                                        padding: msg.imageUrl != null ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2) : null,
                                        decoration: msg.imageUrl != null ? BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(8),
                                        ) : null,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatTime(msg.createdAt),
                                              style: TextStyle(
                                                color: msg.imageUrl != null
                                                    ? Colors.white
                                                    : (isDarkMode ? Colors.white60 : Colors.black54),
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                LucideIcons.checkCheck,
                                                size: 15,
                                                color: msg.isRead ? WAColors.micSeen : WAColors.micUnseen,
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

          if (isUploading.value)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Enviando...', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),

          // 👇 OCULTAMOS EL INPUT SI EL TRATO YA SE CERRÓ O CANCELÓ
          if (isCompleted || isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: isDarkMode ? const Color(0xFF1E2428) : Colors.white,
              child: Text(
                isCompleted ? 'Este intercambio ha sido completado. 🎉' : 'Este trato fue cancelado.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              color: isDarkMode ? const Color(0xFF1E2428) : Colors.transparent,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF2A2F32) : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(LucideIcons.smile, color: isDarkMode ? Colors.grey : Colors.black45),
                              onPressed: () {},
                            ),
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                textCapitalization: TextCapitalization.sentences,
                                minLines: 1, maxLines: 5,
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: "Mensaje",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(LucideIcons.paperclip, color: isDarkMode ? Colors.grey : Colors.black45),
                              onPressed: isUploading.value || isRecording.value ? null : _showAttachmentOptions,
                            ),
                            if (!hasText.value)
                              IconButton(
                                icon: Icon(LucideIcons.camera, color: isDarkMode ? Colors.grey : Colors.black45),
                                onPressed: () => sendImageMessage(ImageSource.camera),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: hasText.value ? sendTextMessage : null,
                      onLongPressStart: hasText.value ? null : (_) => startRecording(),
                      onLongPressEnd: hasText.value ? null : (_) => stopRecordingAndSend(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isRecording.value ? Colors.red : const Color(0xFF00897B),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(hasText.value ? LucideIcons.send : LucideIcons.mic, color: Colors.white, size: 22),
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

class WAAudioPlayer extends HookWidget {
  final String audioUrl;
  final bool isMe;
  final bool isRead;

  const WAAudioPlayer({super.key, required this.audioUrl, required this.isMe, required this.isRead});

  @override
  Widget build(BuildContext context) {
    final playerController = useMemoized(() => PlayerController());
    final isPlaying = useState(false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    useEffect(() {
      Future<void> preparePlayer() async {
        await playerController.preparePlayer(
          path: audioUrl,
          shouldExtractWaveform: true,
        );
      }
      preparePlayer();

      final stateSub = playerController.onPlayerStateChanged.listen((state) {
        isPlaying.value = state == PlayerState.playing;
      });

      final completionSub = playerController.onCompletion.listen((_) async {
        isPlaying.value = false;
        await playerController.seekTo(0);
      });

      return () {
        stateSub.cancel();
        completionSub.cancel();
        playerController.dispose();
      };
    }, [audioUrl, playerController]);

    Color getWaveColor() {
      if (isMe) {
        return isDarkMode ? Colors.white70 : Colors.black38;
      } else {
        return isRead ? WAColors.micSeen : Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 2, left: 0, right: 5),
      width: 280,
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () async {
                  if (isPlaying.value) {
                    await playerController.pausePlayer();
                  } else {
                    if (playerController.playerState == PlayerState.stopped) {
                      await playerController.preparePlayer(
                        path: audioUrl,
                        shouldExtractWaveform: false,
                      );
                    }
                    await playerController.startPlayer();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying.value ? LucideIcons.pause : LucideIcons.play,
                    color: WAColors.playBtn,
                    size: 32,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 5, bottom: 5),
                child: Icon(
                    LucideIcons.mic,
                    size: 14,
                    color: isMe ? (isRead ? WAColors.micSeen : WAColors.micUnseen) : (isRead ? WAColors.micSeen : Colors.grey)
                ),
              ),
            ],
          ),

          const SizedBox(width: 5),

          Expanded(
            child: AudioFileWaveforms(
              size: const Size(double.infinity, 35),
              playerController: playerController,
              enableSeekGesture: true,
              waveformType: WaveformType.fitWidth,
              playerWaveStyle: PlayerWaveStyle(
                fixedWaveColor: getWaveColor(),
                liveWaveColor: isDarkMode ? Colors.white : Colors.black54,
                waveThickness: 2.5,
                spacing: 4,
                seekLineColor: Colors.red,
                seekLineThickness: 2,
                showSeekLine: false,
              ),
            ),
          ),

          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImageViewer({super.key, required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}