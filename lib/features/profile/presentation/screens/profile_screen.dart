import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/trade_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../trades/presentation/widgets/create_trade_modal.dart';
import '../controllers/my_posts_controller.dart';
import '../controllers/profile_controller.dart';
import '../../../trades/domain/models/trade_post.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _confirmDeletePost(BuildContext context, WidgetRef ref, String postId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Row(
            children: [
              Icon(LucideIcons.trash2, color: Colors.red),
              SizedBox(width: 10),
              Text('¿Eliminar publicación?')
            ]
        ),
        content: const Text('Se eliminará esta publicación de forma permanente y se cancelarán las ofertas pendientes. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await Supabase.instance.client.from('trades').delete().eq('id', postId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Publicación eliminada correctamente.'), backgroundColor: Colors.red)
                  );
                  ref.invalidate(myHistoryFeedProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentProfileProvider);
    final authState = ref.watch(authControllerProvider);
    final collectionState = ref.watch(myCollectionProvider);

    final myPostsState = ref.watch(myHistoryFeedProvider);

    final cardsCount = collectionState.value?.length ?? 0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey,
        actions: [
          if (authState.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.settings),
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) {
                if (value == 'logout') {
                  ref.read(authControllerProvider.notifier).logout();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateTradeModal(),
          );
        },
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Publicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(currentProfileProvider);
          ref.refresh(myHistoryFeedProvider);
        },
        child: profileState.when(
          data: (user) {
            if (user == null) {
              return ListView(children: const [Center(child: Text('Usuario no encontrado'))]);
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // --- CABECERA DEL PERFIL ---
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.only(top: 10, bottom: 30, left: 24, right: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: CachedNetworkImageProvider(user.avatarUrl),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(user.username, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(user.email, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 20),

                        OutlinedButton.icon(
                          onPressed: () => context.push('/edit-profile', extra: user),
                          icon: const Icon(LucideIcons.pencil, size: 16),
                          label: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Estadísticas
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.withOpacity(0.1))
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCol(context, user.completedTrades.toString(), "Tratos", icon: Icons.handshake, iconColor: Colors.blueAccent),
                              Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2)),
                              _buildStatCol(context, cardsCount.toString(), "Cartas", icon: LucideIcons.layers, iconColor: Colors.purpleAccent),
                              Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2)),
                              _buildStatCol(context, user.reputation.toStringAsFixed(1), "Reputación", icon: Icons.star_rounded, iconColor: Colors.amber),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: const Text(
                      'Tus Últimas Publicaciones',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                  ),

                  // --- LISTA DE PUBLICACIONES ---
                  myPostsState.when(
                    data: (myOwnPosts) {
                      if (myOwnPosts.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(LucideIcons.layoutTemplate, size: 60, color: Colors.grey.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                const Text(
                                  "No tienes publicaciones activas.\n¡Anímate a subir tu primera carta!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final recentPosts = myOwnPosts.take(5).toList();

                      return Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Margen ajustado para el TradeCard
                            itemCount: recentPosts.length,
                            itemBuilder: (context, index) {
                              final rawData = recentPosts[index];

                              final userMap = rawData['users'] ?? {};
                              final post = TradePost(
                                id: rawData['id'],
                                userId: rawData['user_id'],
                                username: userMap['username'] ?? user.username,
                                userAvatar: userMap['avatar_url'] ?? user.avatarUrl,
                                offerItemName: rawData['offer_item'] ?? 'Sin nombre',
                                offerItemImage: rawData['image_url'],
                                requestItemName: rawData['request_item'] ?? 'Cualquiera',
                                description: rawData['description'],
                                category: rawData['category'] ?? 'General',
                                createdAt: DateTime.parse(rawData['created_at']),
                                status: rawData['status'] ?? 'open',
                              );

                              final isClosed = post.status == 'closed' || post.status == 'completed';

                              return Stack(
                                children: [
                                  TradeCard(
                                    post: post,
                                    showOfferButton: false,
                                    onTradeTap: () => context.push('/offer/${post.id}'),
                                    trailingWidget: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                      color: Theme.of(context).colorScheme.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _confirmDeletePost(context, ref, post.id);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                                              SizedBox(width: 10),
                                              Text('Eliminar Publicación', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (isClosed)
                                    Positioned(
                                      top: 26,
                                      left: 32,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.95),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(LucideIcons.checkCircle2, color: Colors.white, size: 16),
                                            SizedBox(width: 6),
                                            Text('Completado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (myOwnPosts.length > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0, bottom: 40.0),
                              child: Text(
                                '+ ${myOwnPosts.length - 5} publicaciones más ocultas',
                                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          const SizedBox(height: 80), // Espacio para el FAB
                        ],
                      );
                    },
                    loading: () => const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator())),
                    error: (error, stack) => Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)))),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildStatCol(BuildContext context, String value, String label, {IconData? icon, Color? iconColor}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
            ],
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}