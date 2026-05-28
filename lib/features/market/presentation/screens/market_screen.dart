import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../trades/presentation/widgets/make_offer_modal.dart';
import '../../data/market_repository.dart';
import '../../../../core/widgets/trade_card.dart';
import '../../../trades/domain/models/trade_post.dart';

class MarketScreen extends HookConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketState = ref.watch(marketFeedProvider);
    final marketNotifier = ref.read(marketFeedProvider.notifier);
    final categoriesState = ref.watch(categoriesProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final myUserId = ref.watch(authRepositoryProvider).currentSession?.user.id;

    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedCategory = useState('Todas');

    final scrollController = useScrollController();

    useEffect(() {
      void listener() {
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
          marketNotifier.fetchMore();
        }
      }
      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    useEffect(() {
      void searchListener() => searchQuery.value = searchController.text;
      searchController.addListener(searchListener);
      return () => searchController.removeListener(searchListener);
    }, [searchController]);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Mercado de Intercambio', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // 🔥 LA CAMPANITA MÁGICA
          Consumer(
            builder: (context, ref, child) {
              final notifsAsync = ref.watch(notificationsStreamProvider);
              final hasUnread = notifsAsync.value?.any((n) => !n.isRead) ?? false;

              return IconButton(
                icon: Badge(
                  isLabelVisible: hasUnread,
                  child: const Icon(LucideIcons.bell),
                ),
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cartas, personajes...',
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                  icon: const Icon(LucideIcons.xCircle, color: Colors.grey, size: 20),
                  onPressed: () {
                    searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
                    : null,
                filled: true,
                fillColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // --- FILTROS DE CATEGORÍA ---
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            height: 50,
            child: categoriesState.when(
              data: (categories) => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory.value == category;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent.withOpacity(0.2),
                      side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.transparent),
                      onSelected: (bool selected) {
                        selectedCategory.value = category;
                      },
                    ),
                  );
                },
              ),
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (err, stack) => const Center(child: Text('Error en filtros')),
            ),
          ),

          // --- LISTA DE PUBLICACIONES (SCROLL INFINITO) ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await marketNotifier.fetchInitial();
                ref.invalidate(categoriesProvider);
              },
              child: marketState.when(
                data: (trades) {
                  final filteredTrades = trades.where((trade) {
                    final offerItem = (trade['offer_item'] ?? '').toString().toLowerCase();
                    final requestItem = (trade['request_item'] ?? '').toString().toLowerCase();
                    final query = searchQuery.value.toLowerCase();

                    final matchesSearch = query.isEmpty || offerItem.contains(query) || requestItem.contains(query);
                    final tradeCategory = trade['category'] ?? 'General';
                    final matchesCategory = selectedCategory.value == 'Todas' || tradeCategory == selectedCategory.value;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredTrades.isEmpty && trades.isNotEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              const Icon(LucideIcons.searchX, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.value.isEmpty ? 'No hay cartas en esta categoría.' : 'No encontramos resultados.',
                                style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final itemCount = filteredTrades.length + (marketNotifier.hasReachedMax ? 0 : 1);

                  return ListView.builder(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 40),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index == filteredTrades.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final rawData = filteredTrades[index];
                      final user = rawData['users'] ?? {};

                      String? validImageUrl = rawData['image_url'];
                      if (validImageUrl != null && validImageUrl.trim().isEmpty) validImageUrl = null;

                      final post = TradePost(
                        id: rawData['id'],
                        userId: rawData['user_id'],
                        username: user['username'] ?? 'Usuario',
                        userAvatar: user['avatar_url'] ?? 'https://ui-avatars.com/api/?name=U',
                        offerItemName: rawData['offer_item'] ?? 'Sin nombre',
                        offerItemImage: validImageUrl,
                        requestItemName: rawData['request_item'] ?? 'Cualquiera',
                        description: rawData['description'],
                        category: rawData['category'] ?? 'General',
                        createdAt: DateTime.parse(rawData['created_at']),
                        status: rawData['status'] ?? 'open',
                        isVip: user['is_vip'] ?? false,
                        isBoosted: rawData['is_boosted'] ?? false,
                      );

                      final isMyTrade = myUserId == post.userId;

                      return TradeCard(
                        post: post,
                        showOfferButton: !isMyTrade,
                        onTradeTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => MakeOfferModal(
                              tradeId: post.id,
                              ownerUsername: post.username,
                              offerItemName: post.offerItemName,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}