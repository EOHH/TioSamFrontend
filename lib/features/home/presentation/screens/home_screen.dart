import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../controllers/home_feed_controller.dart';
import '../../../../core/widgets/trade_card.dart';
import '../widgets/create_trade_modal.dart';
import '../widgets/make_offer_modal.dart';
import '../../../../core/services/notification_service.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    useEffect(() {
      NotificationService().initNotifications();

      NotificationService().setupInteractedMessage((tradeId) {
        debugPrint("¡Redirigiendo a la oferta con ID: $tradeId!");

        // 🔥 EL GATILLO DESCOMENTADO 🔥
        // GoRouter tomará el control y te llevará a la pantalla de la oferta
        context.push('/offer/$tradeId');
      });

      return null;
    }, []);

    final feedState = ref.watch(homeFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descubrir',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.search), onPressed: () {}),
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
        ],
      ),
      body: feedState.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text("Aún no hay publicaciones. ¡Sé el primero!"));
          }

          return RefreshIndicator(
            color: Theme.of(context).primaryColor,
            onRefresh: () => ref.read(homeFeedProvider.notifier).fetchFeed(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildCollectorsStories(context),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text('Tendencias de Intercambio',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final post = posts[index];
                      return TradeCard(
                        post: post,
                        onTradeTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => MakeOfferModal(post: post),
                          );
                        },
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error al cargar el feed: $error',
              style: const TextStyle(color: Colors.red)),
        ),
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
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Publicar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCollectorsStories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Coleccionistas Activos',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 8,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 2),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(
                            'https://ui-avatars.com/api/?name=User+$index&background=random'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('User $index', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}