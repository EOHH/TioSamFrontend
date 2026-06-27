import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../trades/presentation/widgets/make_offer_modal.dart';
import '../../data/market_repository.dart';
import '../../../../core/widgets/trade_card.dart';
import '../../../trades/domain/models/trade_post.dart';
import '../../../trades/presentation/widgets/create_trade_modal.dart';

// Import providers for Profile and Wallet
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../shop/presentation/controllers/shop_controller.dart';

class MarketScreen extends HookConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketState = ref.watch(marketFeedProvider);
    final marketNotifier = ref.read(marketFeedProvider.notifier);
    final categoriesState = ref.watch(categoriesProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final myUserId = ref.watch(authRepositoryProvider).currentSession?.user.id;

    // Fetch User Profile and Wallet
    final profileState = ref.watch(currentProfileProvider);
    final walletState = ref.watch(shopControllerProvider);

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
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF6F8FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateTradeModal(),
          );
        },
        backgroundColor: const Color(0xFF5E2BFF),
        elevation: 8,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text('Publicar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // --- CABECERA GAMIFIED CON GRADIENTE ---
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7C4DFF), Color(0xFF00C2FF)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER SUPERIOR (Avatar, Título, Notificaciones)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Avatar con Nivel
                            profileState.when(
                              data: (profile) {
                                final level = profile != null ? (profile.completedTrades ~/ 5) + 1 : 1;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.white24,
                                        backgroundImage: NetworkImage(profile?.avatarUrl ?? 'https://ui-avatars.com/api/?name=U'),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -6,
                                      right: -6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFD93D),
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                        ),
                                        child: Text(
                                          level.toString(),
                                          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const CircleAvatar(radius: 24, backgroundColor: Colors.white24),
                              error: (_, __) => const CircleAvatar(radius: 24, backgroundColor: Colors.white24),
                            ),

                            // Título Central
                            Text(
                              'Mercado',
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
                            ),

                            // Notificaciones
                            Consumer(
                              builder: (context, ref, child) {
                                final notifsAsync = ref.watch(notificationsStreamProvider);
                                final hasUnread = notifsAsync.value?.any((n) => !n.isRead) ?? false;
                                return IconButton(
                                  icon: Badge(
                                    isLabelVisible: hasUnread,
                                    backgroundColor: Colors.redAccent,
                                    child: const Icon(LucideIcons.bell, color: Colors.white, size: 26),
                                  ),
                                  onPressed: () => context.push('/notifications'),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        // ROW 2: Subtítulo y Gemas
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Intercambia tus cartas',
                                style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            // Etiqueta de Gemas
                            Align(
                              alignment: Alignment.centerRight,
                              child: walletState.when(
                                data: (wallet) {
                                  final gems = wallet?.gems ?? 0;
                                  return GestureDetector(
                                    onTap: () => context.push('/shop'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.gem, color: Color(0xFF00C2FF), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            gems.toString(),
                                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                            child: const Icon(LucideIcons.plus, color: Color(0xFF7C4DFF), size: 12),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(height: 30),
                                error: (_, __) => const SizedBox(height: 30),
                              ),
                            ),
                          ],
                        ),

                        
                        const Spacer(),

                        // BARRA DE BÚSQUEDA Y FILTRO
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.search, color: Colors.grey, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar cartas, personajes...',
                                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontWeight: FontWeight.w500, fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              if (searchQuery.value.isNotEmpty)
                                IconButton(
                                  icon: const Icon(LucideIcons.xCircle, color: Colors.grey, size: 18),
                                  onPressed: () {
                                    searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.grey.shade300,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              const Icon(LucideIcons.slidersHorizontal, color: Color(0xFF7C4DFF), size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- FILTROS DE CATEGORÍA ---
          SliverToBoxAdapter(
            child: Container(
              color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF6F8FF),
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              height: 65,
              child: categoriesState.when(
                data: (categories) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory.value == category;
                    
                    // Definir colores según categoría (simulando los iconos del diseño)
                    Color catColor = const Color(0xFF00C2FF); // Cyan por defecto
                    IconData catIcon = LucideIcons.layers;
                    if (category.toLowerCase() == 'anime') { catColor = const Color(0xFF9D4EDD); catIcon = LucideIcons.tv; }
                    if (category.toLowerCase() == 'deportes') { catColor = const Color(0xFF2EC4B6); catIcon = LucideIcons.dribbble; }
                    if (category.toLowerCase() == 'tcg') { catColor = const Color(0xFF3A86FF); catIcon = LucideIcons.bookOpen; }
                    if (category.toLowerCase() == 'general') { catColor = const Color(0xFFFF9F1C); catIcon = LucideIcons.star; }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => selectedCategory.value = category,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? catColor.withOpacity(0.15) : (isDarkMode ? Colors.white10 : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? catColor : catColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: catColor.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(catIcon, size: 16, color: catColor),
                              const SizedBox(width: 6),
                              Text(
                                category,
                                style: GoogleFonts.poppins(
                                  color: catColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (err, stack) => const Center(child: Text('Error en filtros')),
              ),
            ),
          ),

          // --- LISTA DE PUBLICACIONES ---
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            sliver: marketState.when(
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
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(LucideIcons.searchX, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.value.isEmpty ? 'No hay cartas en esta categoría.' : 'No encontramos resultados.',
                              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final itemCount = filteredTrades.length + (marketNotifier.hasReachedMax ? 0 : 1);

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
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
                    childCount: itemCount,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            ),
          ),
        ],
      ),
    );
  }
}