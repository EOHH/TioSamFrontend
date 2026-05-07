import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- 1. PROVEEDOR DE PRESENCIA (EN LÍNEA) ---
final presenceProvider = StateNotifierProvider<PresenceNotifier, Set<String>>((ref) {
  return PresenceNotifier();
});

// --- 2. PROVEEDOR DE "ESCRIBIENDO..." ---
final typingProvider = StateNotifierProvider.family<TypingNotifier, bool, String>((ref, offerId) {
  return TypingNotifier(offerId);
});

// --- NOTIFIER DE PRESENCIA (INTACTO, SOLO OPTIMIZADO) ---
class PresenceNotifier extends StateNotifier<Set<String>> {
  RealtimeChannel? _channel;

  PresenceNotifier() : super({}) {
    _initPresence();
  }

  void _initPresence() {
    final supabase = Supabase.instance.client;
    final myUserId = supabase.auth.currentUser?.id;

    if (myUserId == null) return;

    _channel = supabase.channel('global_presence');

    _channel!.onPresenceSync((_) {
      final newState = _channel!.presenceState();
      final onlineUsers = <String>{};

      for (final presence in newState) {
        final data = presence as dynamic;
        final metas = data.metas ?? data['metas'] ?? [];

        for (final meta in metas) {
          final id = meta['user_id'];
          if (id != null) {
            onlineUsers.add(id.toString());
          }
        }
      }
      state = onlineUsers;
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({'user_id': myUserId});
      }
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// --- NOTIFIER DE "ESCRIBIENDO..." (¡LA MAGIA DEL BROADCAST!) ---
class TypingNotifier extends StateNotifier<bool> {
  final String offerId;
  RealtimeChannel? _channel;
  Timer? _typingTimer;

  TypingNotifier(this.offerId) : super(false) {
    _initTypingListener();
  }

  void _initTypingListener() {
    final supabase = Supabase.instance.client;
    final myUserId = supabase.auth.currentUser?.id;
    if (myUserId == null) return;

    // Creamos un canal específico para este chat
    _channel = supabase.channel('chat_$offerId');

    // Escuchamos los eventos de broadcast llamados "typing"
    _channel!.onBroadcast(
        event: 'typing',
        callback: (payload) {
          final senderId = payload['user_id'];
          final isTyping = payload['is_typing'] ?? false;

          // Si el que escribe NO soy yo, actualizo la pantalla
          if (senderId != myUserId) {
            state = isTyping;
          }
        }).subscribe();
  }

  // Función que llamaremos desde la UI cuando el usuario teclee
  void sendTypingEvent(bool isTyping) async {
    final myUserId = Supabase.instance.client.auth.currentUser?.id;
    if (myUserId == null || _channel == null) return;

    try {
      await _channel!.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'user_id': myUserId,
          'is_typing': isTyping,
        },
      );
    } catch (e) {
      // Ignorar errores menores de conexión en broadcast
    }

    // Si dice que está escribiendo, ponemos un timer de seguridad de 3 segundos
    // Por si la app se cierra de golpe o se va el internet, se quite el "escribiendo..."
    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        sendTypingEvent(false);
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}