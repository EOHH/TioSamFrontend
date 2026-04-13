import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final presenceProvider =
StateNotifierProvider<PresenceNotifier, Set<String>>((ref) {
  return PresenceNotifier();
});

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

    _channel!
        .onPresenceSync((_) {
      final newState = _channel!.presenceState();
      final onlineUsers = <String>{};

      for (final presence in newState) {
        final data = presence as dynamic;

        // 👇 intenta leer diferentes estructuras posibles
        final metas = data.metas ?? data['metas'] ?? [];

        for (final meta in metas) {
          final id = meta['user_id'];

          if (id != null) {
            onlineUsers.add(id.toString());
          }
        }
      }

      state = onlineUsers;
    })
        .subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({
          'user_id': myUserId,
        });
      }
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}