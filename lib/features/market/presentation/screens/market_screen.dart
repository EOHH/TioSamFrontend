import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../trades/presentation/widgets/make_offer_modal.dart';
import '../../data/market_repository.dart';
import '../../../../core/widgets/trade_card.dart';
import '../../../trades/domain/models/trade_post.dart';

class MarketScreen extends HookConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketState = ref.watch(marketFeedProvider);
    final categoriesState = ref.watch(categoriesProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final myUserId = ref.watch(authRepositoryProvider).currentSession?.user.id;

    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedCategory = useState('Todas');

    useEffect(() {
      void listener() => searchQuery.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey,
      appBar: AppBar(
        title: const Text('Mercado de Intercambio', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
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
                fillColor: isDarkMode ? Colors.grey : Colors.grey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // FILTROS DE CATEGORÍA DINÁMICOS
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
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
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

          // LISTA DE PUBLICACIONES
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.refresh(marketFeedProvider);
                ref.refresh(categoriesProvider);
              },
              child: marketState.when(
                data: (trades) {
                  // FILTRADO CON CATEGORÍA REAL Y BÚSQUEDA
                  final filteredTrades = trades.where((trade) {
                    final offerItem = (trade['offer_item'] ?? '').toString().toLowerCase();
                    final requestItem = (trade['request_item'] ?? '').toString().toLowerCase();
                    final query = searchQuery.value.toLowerCase();

                    final matchesSearch = query.isEmpty || offerItem.contains(query) || requestItem.contains(query);

                    final tradeCategory = trade['category'] ?? 'General';
                    final matchesCategory = selectedCategory.value == 'Todas' || tradeCategory == selectedCategory.value;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredTrades.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(LucideIcons.searchX, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.value.isEmpty
                                    ? 'No hay publicaciones activas.'
                                    : 'No encontramos resultados.',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: filteredTrades.length,
                    itemBuilder: (context, index) {
                      final rawData = filteredTrades[index];
                      final user = rawData['users'] ?? {};

                      // 🔥 CREAMOS EL OBJETO CON EL STATUS RESTAURADO
                      final post = TradePost(
                        id: rawData['id'],
                        userId: rawData['user_id'],
                        username: user['username'] ?? 'Usuario',
                        userAvatar: user['avatar_url'] ?? 'https://ui-avatars.com/api/?name=U',
                        offerItemName: rawData['offer_item'] ?? 'Sin nombre',
                        offerItemImage: rawData['image_url'],
                        requestItemName: rawData['request_item'] ?? 'Cualquiera',
                        createdAt: DateTime.parse(rawData['created_at']),
                        status: rawData['status'] ?? 'open', // <- El status ya está aquí
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