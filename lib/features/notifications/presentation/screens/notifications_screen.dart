import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago; // Mantenemos esta para usar la función .format()

import '../../data/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsStreamProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Marcar todas como leídas',
            icon: const Icon(LucideIcons.checkCheck, color: Colors.blueAccent),
            onPressed: () {
              ref.read(notificationRepositoryProvider).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todas marcadas como leídas'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isUnread = !notif.isRead;

              // 🎨 Configuración visual según el tipo de notificación
              IconData iconData = LucideIcons.bell;
              Color iconColor = Colors.grey;
              Color bgColor = Colors.grey.withValues(alpha: 0.1);

              if (notif.type == 'new_offer') {
                iconData = LucideIcons.arrowRightLeft;
                iconColor = Colors.blueAccent;
                bgColor = Colors.blueAccent.withValues(alpha: 0.1);
              } else if (notif.type == 'offer_accepted') {
                iconData = LucideIcons.partyPopper;
                iconColor = Colors.green;
                bgColor = Colors.green.withValues(alpha: 0.1);
              } else if (notif.type == 'new_chat_message') {
                iconData = LucideIcons.messageCircle;
                iconColor = Colors.purpleAccent;
                bgColor = Colors.purpleAccent.withValues(alpha: 0.1);
              }

              return Card(
                elevation: isUnread ? 2 : 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isUnread ? iconColor.withValues(alpha: 0.5) : Colors.transparent),
                ),
                color: isUnread
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                    child: Icon(iconData, color: iconColor, size: 24),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notif.body, style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700)),
                      const SizedBox(height: 6),
                      Text(
                        // 🔥 AQUÍ SE APLICA LA MAGIA DEL TIEMPO EN ESPAÑOL
                        timeago.format(notif.createdAt, locale: 'es'),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: isUnread
                      ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))
                      : null,
                  onTap: () {
                    // 1. Marcar como leída en Supabase
                    if (isUnread) {
                      ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                    }

                    // 2. Redirigir según el tipo
                    final data = notif.data ?? {};
                    if (notif.type == 'new_offer') {
                      final tradeId = data['trade_id'];
                      if (tradeId != null) context.push('/offer/$tradeId');
                    } else if (notif.type == 'offer_accepted') {
                      context.push('/trades');
                    } else if (notif.type == 'new_chat_message') {
                      final offerId = data['offer_id'];
                      final contactId = data['contact_id'] ?? '';
                      final contactName = data['contact_name'] ?? 'Coleccionista';
                      final contactAvatar = data['contact_avatar'] ?? 'https://ui-avatars.com/api/?name=C';

                      if (offerId != null) {
                        context.push(
                          '/chat/$offerId?name=${Uri.encodeComponent(contactName)}'
                              '&avatar=${Uri.encodeComponent(contactAvatar)}'
                              '&contactId=$contactId',
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            "Todo está tranquilo por aquí",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Aún no tienes notificaciones.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}