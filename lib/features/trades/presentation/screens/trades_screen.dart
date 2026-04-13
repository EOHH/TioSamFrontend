import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/offer_repository.dart';

// 👇 1. PROVEEDOR REACTIVO EN TIEMPO REAL (Recibidos)
final receivedOffersProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;

  final channel = supabase.channel('public:trade_offers_received')
      .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'trade_offers',
      callback: (payload) {
        debugPrint("¡Cambio detectado en BD (Recibidos)! Recargando...");
        ref.invalidateSelf();
      })
      .subscribe();

  ref.onDispose(() => supabase.removeChannel(channel));

  return ref.watch(offerRepositoryProvider).getReceivedOffers();
});

// 👇 2. PROVEEDOR REACTIVO EN TIEMPO REAL (Enviados)
final sentOffersProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;

  final channel = supabase.channel('public:trade_offers_sent')
      .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'trade_offers',
      callback: (payload) {
        debugPrint("¡Cambio detectado en BD (Enviados)! Recargando...");
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
        debugPrint("App volvió al primer plano. Refrescando intercambios...");

        Future.microtask(() {
          ref.invalidate(receivedOffersProvider);
          ref.invalidate(sentOffersProvider);
        });
      }
      return null;
    }, [appLifecycleState]);

    final receivedState = ref.watch(receivedOffersProvider);
    final sentState = ref.watch(sentOffersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Intercambios', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(tabs: [Tab(text: 'Recibidos'), Tab(text: 'Enviados')]),
        ),
        body: TabBarView(
          children: [
            receivedState.when(
              data: (offers) {
                if (offers.isEmpty) return const Center(child: Text("No tienes ofertas recibidas."));

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(receivedOffersProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) => _OfferTile(offer: offers[index], isReceived: true),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
            sentState.when(
              data: (offers) {
                if (offers.isEmpty) return const Center(child: Text("No has enviado ninguna oferta."));

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(sentOffersProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
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
}

class _OfferTile extends ConsumerWidget {
  final dynamic offer;
  final bool isReceived;

  const _OfferTile({required this.offer, required this.isReceived});

  // 👇 FUNCIÓN PARA CONFIRMAR Y ELIMINAR LA OFERTA
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Row(
            children: [
              Icon(LucideIcons.trash2, color: Colors.red),
              SizedBox(width: 10),
              Text('¿Eliminar oferta?')
            ]
        ),
        content: const Text('Esta acción eliminará la oferta de tu lista permanentemente. ¿Estás seguro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogContext); // Cerramos el diálogo
              try {
                // Llamamos al repositorio para borrar
                await ref.read(offerRepositoryProvider).deleteOffer(offer.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Oferta eliminada correctamente.'), backgroundColor: Colors.red)
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'))
                  );
                }
              }
            },
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: offer.offererAvatar != null
                      ? NetworkImage(offer.offererAvatar)
                      : const NetworkImage('https://ui-avatars.com/api/?name=User'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.offererUsername ?? 'Coleccionista', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        isReceived ? 'Quiere tu: ${offer.post?.offerItemName ?? 'Carta'}' : 'Tú quieres su: ${offer.post?.offerItemName ?? 'Carta'}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: offer.status),

                // 👇 NUEVO: LOS 3 PUNTITOS PARA ELIMINAR
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  color: Theme.of(context).colorScheme.surface,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text('Eliminar Oferta', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Text('"${offer.message}"', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            ),

            if (isReceived && offer.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _update(ref, 'rejected'),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                      child: const Text('Rechazar', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _update(ref, 'accepted'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              )
            ],

            if (offer.status == 'accepted' || offer.status == 'completed') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
                    final isMeOfferer = offer.offererId == currentUserId;

                    final contactName = isMeOfferer ? offer.post?.username : offer.offererUsername;
                    final contactAvatar = isMeOfferer ? offer.post?.userAvatar : offer.offererAvatar;
                    final contactId = isMeOfferer ? offer.post?.userId : offer.offererId;

                    context.push('/chat/${offer.id}?name=${Uri.encodeComponent(contactName ?? 'Coleccionista')}&avatar=${Uri.encodeComponent(contactAvatar ?? 'https://ui-avatars.com/api/?name=C')}&contactId=$contactId');
                  },
                  icon: const Icon(LucideIcons.messageCircle),
                  label: Text(offer.status == 'completed' ? 'Ver Chat (Completado)' : 'Abrir Chat Seguro'),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  void _update(WidgetRef ref, String status) async {
    await ref.read(offerRepositoryProvider).updateOfferStatus(offer.id, status);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.orange;
    String text = 'Pendiente';
    if (status == 'accepted') { color = Colors.green; text = 'Aceptado'; }
    if (status == 'rejected') { color = Colors.red; text = 'Rechazado'; }
    if (status == 'completed') { color = Colors.blue; text = 'Completado'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}