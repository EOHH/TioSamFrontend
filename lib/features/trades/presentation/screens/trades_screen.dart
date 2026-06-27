import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/offer_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/widgets/trade_card.dart';
import '../../../shop/presentation/controllers/shop_controller.dart';

// 🔥 VIGILANTE DE SESIÓN
final authStateProvider = StreamProvider.autoDispose((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// 👇 PROVEEDOR DE OFERTAS RECIBIDAS
final receivedOffersProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(authStateProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  ref.keepAlive();

  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:trade_offers_received_$userId')
      .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'trade_offers',
      callback: (payload) {
        ref.invalidateSelf();
      })
      .subscribe();

  ref.onDispose(() => supabase.removeChannel(channel));
  return ref.watch(offerRepositoryProvider).getReceivedOffers();
});

// 👇 PROVEEDOR DE OFERTAS ENVIADAS
final sentOffersProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(authStateProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  ref.keepAlive();

  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:trade_offers_sent_$userId')
      .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'trade_offers',
      callback: (payload) {
        ref.invalidateSelf();
      })
      .subscribe();

  ref.onDispose(() => supabase.removeChannel(channel));
  return ref.watch(offerRepositoryProvider).getSentOffers();
});

bool _isRareItem(String name) {
  final lower = name.toLowerCase();
  return lower.contains('(lr)') || 
         lower.contains('(legendary)') || 
         lower.contains('(ur)') || 
         lower.contains('(ssr)') ||
         lower.contains('(sr)');
}

class TradesScreen extends HookConsumerWidget {
  const TradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLifecycleState = useAppLifecycleState();
    final wasPaused = useRef(false);

    useEffect(() {
      if (appLifecycleState == AppLifecycleState.paused) {
        wasPaused.value = true;
      } else if (appLifecycleState == AppLifecycleState.resumed && wasPaused.value) {
        wasPaused.value = false;
        Future.microtask(() {
          ref.invalidate(receivedOffersProvider);
          ref.invalidate(sentOffersProvider);
        });
      }
      return null;
    }, [appLifecycleState]);

    final receivedState = ref.watch(receivedOffersProvider);
    final sentState = ref.watch(sentOffersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletState = ref.watch(shopControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FF),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(190),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), Color(0xFF00C2FF)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: back button + title + subtitle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Intercambios',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            Text(
                              'Gestiona tus intercambios',
                              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        
                        // Right side: Gems
                        walletState.when(
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
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 4,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.5),
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [Tab(text: 'Recibidos'), Tab(text: 'Enviados')],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB RECIBIDOS ---
            receivedState.when(
              data: (offers) {
                if (offers == null || offers.isEmpty) return _buildEmptyState(context, "No tienes ofertas recibidas.", LucideIcons.inbox);

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(receivedOffersProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          _OfferTile(offer: offers[index], isReceived: true),
                          if (index == offers.length - 1)
                            _buildSecurityBanner(),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),

            // --- TAB ENVIADOS ---
            sentState.when(
              data: (offers) {
                if (offers == null || offers.isEmpty) return _buildEmptyState(context, "No has enviado ninguna oferta.", LucideIcons.send);

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(sentOffersProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          _OfferTile(offer: offers[index], isReceived: false),
                          if (index == offers.length - 1)
                            _buildSecurityBanner(),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5), // Soft pink/purple bg
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB6C1).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFFF9A9E).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(LucideIcons.lock, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Intercambio 100% Seguro',
                  style: GoogleFonts.poppins(color: const Color(0xFF9D4EDD), fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nuestro sistema protege tus cartas y garantiza un intercambio justo.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.shieldCheck, color: Color(0xFF9D4EDD), size: 32),
        ],
      ),
    );
  }
}

class _OfferTile extends ConsumerWidget {
  final dynamic offer;
  final bool isReceived;

  const _OfferTile({required this.offer, required this.isReceived});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(children: [const Icon(LucideIcons.trash2, color: Colors.red), const SizedBox(width: 10), Text('¿Eliminar oferta?', style: GoogleFonts.poppins())]),
        content: Text('Esta acción eliminará la oferta de tu lista permanentemente. ¿Estás seguro?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(offerRepositoryProvider).deleteOffer(offer.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta eliminada correctamente.'), backgroundColor: Colors.red));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text('Eliminar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _update(WidgetRef ref, String status) async {
    final repo = ref.read(offerRepositoryProvider);
    if (status == 'accepted') {
      await repo.acceptOffer(offer.id);
    } else {
      await repo.updateOfferStatus(offer.id, status);
    }
    ref.invalidate(receivedOffersProvider);
    ref.invalidate(sentOffersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final String myItemName = offer.post?.offerItemName ?? 'Carta';
    final String theirItemName = offer.post?.requestItemName ?? 'Carta';

    final String leftCardName = isReceived ? theirItemName : myItemName;
    final String rightCardName = isReceived ? myItemName : theirItemName;
    
    // Asumimos que la imagen original del post es la de "myItemName" en ambos casos.
    // the other one we don't have the image in the current db structure usually.
    final String? leftCardImg = isReceived ? null : offer.post?.offerItemImage;
    final String? rightCardImg = isReceived ? offer.post?.offerItemImage : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABECERA ---
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: offer.offererAvatar != null
                        ? CachedNetworkImageProvider(offer.offererAvatar)
                        : const NetworkImage('https://ui-avatars.com/api/?name=User') as ImageProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(offer.offererUsername ?? 'Coleccionista', overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.checkCircle2, color: Color(0xFF7C4DFF), size: 14),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isReceived ? 'Quiere tu: $myItemName' : 'Tú quieres su: $theirItemName',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: offer.status),
                const SizedBox(width: 4),

                // Menú 3 puntitos
                SizedBox(
                  width: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) { if (value == 'delete') _confirmDelete(context, ref); },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20), const SizedBox(width: 10), Text('Eliminar', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- MENSAJE ---
            if (offer.message != null && offer.message.toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF6F8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('"${offer.message}"', style: GoogleFonts.poppins(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
              ),
            ],

            // --- CARTAS HOLOGRÁFICAS ---
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: HolographicItemNode(
                    name: leftCardName,
                    img: leftCardImg,
                    isOffer: isReceived ? false : true,
                    isRare: _isRareItem(leftCardName),
                    topLabel: isReceived ? 'EL OFRECE' : 'TÚ OFRECES',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                    ),
                    child: Icon(LucideIcons.repeat, size: 20, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
                Expanded(
                  child: HolographicItemNode(
                    name: rightCardName,
                    img: rightCardImg,
                    isOffer: isReceived ? true : false,
                    isRare: _isRareItem(rightCardName),
                    topLabel: isReceived ? 'TÚ OFRECES' : 'ÉL OFRECE',
                  ),
                ),
              ],
            ),

            // --- ACCIONES (BOTONES) ---
            const SizedBox(height: 20),
            if (isReceived && offer.status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _update(ref, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Rechazar', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _update(ref, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF00C2FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Aceptar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Acción secundaria, tal vez ver perfil
                      },
                      icon: const Icon(LucideIcons.messageSquare, size: 16, color: Color(0xFF7C4DFF)),
                      label: Text('Mensaje privado', style: GoogleFonts.poppins(color: const Color(0xFF7C4DFF), fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF7C4DFF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final currentUserId = Supabase.instance.client.auth.currentUser!.id;
                        final isMeOfferer = offer.offererId == currentUserId;
                        final contactName = isMeOfferer ? offer.post?.username : offer.offererUsername;
                        final contactAvatar = isMeOfferer ? offer.post?.userAvatar : offer.offererAvatar;
                        final contactId = isMeOfferer ? offer.post?.userId : offer.offererId;

                        context.push('/chat/${offer.id}?name=${Uri.encodeComponent(contactName ?? 'Coleccionista')}&avatar=${Uri.encodeComponent(contactAvatar ?? 'https://ui-avatars.com/api/?name=C')}&contactId=$contactId');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF7C4DFF)]),
                          boxShadow: [BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(offer.status == 'completed' ? LucideIcons.checkCircle2 : LucideIcons.shieldCheck, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(offer.status == 'completed' ? 'Ver Trato' : 'Abrir Chat Seguro', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.orange;
    Color bgColor = Colors.orange.withOpacity(0.15);
    String text = 'Pendiente';
    IconData iconData = LucideIcons.clock;

    if (status == 'accepted') { color = Colors.green; bgColor = Colors.green.withOpacity(0.15); text = 'Aceptado'; iconData = LucideIcons.checkCircle2; }
    if (status == 'rejected') { color = Colors.red; bgColor = Colors.red.withOpacity(0.15); text = 'Rechazado'; iconData = LucideIcons.xCircle; }
    if (status == 'completed') { color = Colors.blue; bgColor = Colors.blue.withOpacity(0.15); text = 'Completado'; iconData = LucideIcons.checkCircle2; }
    if (status == 'cancelled') { color = Colors.grey; bgColor = Colors.grey.withOpacity(0.15); text = 'Cancelado'; iconData = LucideIcons.ban; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}