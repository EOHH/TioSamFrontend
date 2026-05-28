import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/models/app_notification.dart';

class NotificationRepository {
  final SupabaseClient _client;
  NotificationRepository(this._client);

  // Obtener historial de notificaciones
  Stream<List<AppNotification>> watchNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) => data.map((json) => AppNotification.fromJson(json)).toList().reversed.toList());
  }

  // Marcar como leída
  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  // Marcar todas como leídas
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _client.from('notifications').update({'is_read': true}).eq('user_id', userId);
    }
  }
}

final notificationRepositoryProvider = Provider((ref) => NotificationRepository(ref.watch(supabaseClientProvider)));

final notificationsStreamProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchNotifications();
});