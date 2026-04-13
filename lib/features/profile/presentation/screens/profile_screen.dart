import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/widgets/trade_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../trades/presentation/widgets/create_trade_modal.dart';
import '../controllers/my_posts_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentProfileProvider);
    final authState = ref.watch(authControllerProvider);
    final collectionState = ref.watch(myCollectionProvider);

    final myPostsState = ref.watch(homeFeedProvider);

    final cardsCount = collectionState.value?.length ?? 0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          // 👇 1. CERRAR SESIÓN MOVIDO A LA PARTE SUPERIOR DERECHA (MENÚ)
          if (authState.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.settings), // El icono de tuerca
              color: Theme.of(context).colorScheme.surface,
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
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Publicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(currentProfileProvider);
          ref.refresh(homeFeedProvider);
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
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: CachedNetworkImageProvider(user.avatarUrl),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(user.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user.email, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed: () => context.push('/edit-profile', extra: user),
                          icon: const Icon(LucideIcons.pencil, size: 16),
                          label: const Text('Editar Perfil'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCol(context, user.completedTrades.toString(), "Tratos", icon: Icons.handshake, iconColor: Colors.blueAccent),
                            Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3)),
                            _buildStatCol(context, cardsCount.toString(), "Cartas", icon: LucideIcons.layers, iconColor: Colors.purpleAccent),
                            Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3)),
                            _buildStatCol(context, user.reputation.toStringAsFixed(1), "Reputación", icon: Icons.star_rounded, iconColor: Colors.amber),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: const Text(
                      'Tus Últimas Publicaciones',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // --- LISTA DE PUBLICACIONES ---
                  myPostsState.when(
                    data: (allPosts) {
                      // 👇 2. EL FILTRO MÁGICO: Solo dejamos las publicaciones que sean tuyas
                      final myOwnPosts = allPosts.where((post) => post.username == user.username).toList();

                      if (myOwnPosts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              "No tienes publicaciones activas.\n¡Anímate a publicar una carta!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      // 👇 3. EL LÍMITE: Tomamos solo las 5 más recientes
                      final recentPosts = myOwnPosts.take(5).toList();

                      return Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: recentPosts.length,
                            itemBuilder: (context, index) {
                              final post = recentPosts[index];
                              return TradeCard(
                                post: post,
                                showOfferButton: false, // Oculta el botón de ofertar
                                onTradeTap: () => context.push('/offer/${post.id}'),
                              );
                            },
                          ),
                          // Mensaje extra si tienes más de 5 publicaciones
                          if (myOwnPosts.length > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                              child: Text(
                                '+ ${myOwnPosts.length - 5} publicaciones más ocultas',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            )
                        ],
                      );
                    },
                    loading: () => const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator())),
                    error: (error, stack) => Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)))),
                  ),
                  const SizedBox(height: 80),
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
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }
}