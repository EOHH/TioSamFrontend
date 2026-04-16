import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/offer_repository.dart';
import '../../../auth/data/auth_repository.dart';

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey,
        appBar: AppBar(
          title: const Text('Intercambios', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey,
          bottom: TabBar(
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [Tab(text: 'Recibidos'), Tab(text: 'Enviados')],
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
                    padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) => _OfferTile(offer: offers[index], isReceived: true),
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
                    padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) => _OfferTile(offer: offers[index], isReceived: false),
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
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
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
        title: const Row(children: [Icon(LucideIcons.trash2, color: Colors.red), SizedBox(width: 10), Text('¿Eliminar oferta?')]),
        content: const Text('Esta acción eliminará la oferta de tu lista permanentemente. ¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    // Forzamos actualización local inmediata
    ref.invalidate(receivedOffersProvider);
    ref.invalidate(sentOffersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                      Text(offer.offererUsername ?? 'Coleccionista', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(isReceived ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isReceived ? 'Quiere tu: ${offer.post?.offerItemName ?? 'Carta'}' : 'Tú quieres su: ${offer.post?.offerItemName ?? 'Carta'}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: offer.status),
                const SizedBox(width: 8),

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
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20), SizedBox(width: 10), Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  // 🔥 CORRECCIÓN DEL COLOR AQUÍ
                  color: isDark ? Colors.grey?.withOpacity(0.4) : Colors.grey,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Text('"${offer.message}"', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.4)),
              ),
            ],

            // --- ACCIONES ---
            if (isReceived && offer.status == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _update(ref, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Rechazar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _update(ref, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],

            if (offer.status == 'accepted' || offer.status == 'completed') ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
                    final isMeOfferer = offer.offererId == currentUserId;
                    final contactName = isMeOfferer ? offer.post?.username : offer.offererUsername;
                    final contactAvatar = isMeOfferer ? offer.post?.userAvatar : offer.offererAvatar;
                    final contactId = isMeOfferer ? offer.post?.userId : offer.offererId;

                    context.push('/chat/${offer.id}?name=${Uri.encodeComponent(contactName ?? 'Coleccionista')}&avatar=${Uri.encodeComponent(contactAvatar ?? 'https://ui-avatars.com/api/?name=C')}&contactId=$contactId');
                  },
                  icon: Icon(offer.status == 'completed' ? LucideIcons.checkCircle2 : LucideIcons.messageCircle, color: Colors.white, size: 20),
                  label: Text(offer.status == 'completed' ? 'Ver Trato Finalizado' : 'Abrir Chat Seguro', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    elevation: 4,
                    shadowColor: Colors.blueAccent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )
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

    if (status == 'accepted') { color = Colors.green; bgColor = Colors.green.withOpacity(0.15); text = 'Aceptado'; }
    if (status == 'rejected') { color = Colors.red; bgColor = Colors.red.withOpacity(0.15); text = 'Rechazado'; }
    if (status == 'completed') { color = Colors.blue; bgColor = Colors.blue.withOpacity(0.15); text = 'Completado'; }
    if (status == 'cancelled') { color = Colors.grey; bgColor = Colors.grey.withOpacity(0.15); text = 'Cancelado'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}