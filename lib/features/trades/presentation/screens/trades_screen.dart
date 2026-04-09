import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/offer_repository.dart';

final receivedOffersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(offerRepositoryProvider).getReceivedOffers();
});

final sentOffersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(offerRepositoryProvider).getSentOffers();
});

class TradesScreen extends ConsumerWidget {
  const TradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) => _OfferTile(offer: offers[index], isReceived: true),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
            sentState.when(
              data: (offers) {
                if (offers.isEmpty) return const Center(child: Text("No has enviado ninguna oferta."));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) => _OfferTile(offer: offers[index], isReceived: false),
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
                CircleAvatar(backgroundImage: NetworkImage(offer.offererAvatar)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.offererUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        isReceived ? 'Quiere tu: ${offer.post.offerItemName}' : 'Tú quieres su: ${offer.post.offerItemName}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: offer.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Text('"${offer.message}"', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            ),

            // ACCIONES SEGÚN EL ESTADO
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

            // BOTÓN DE CHAT (Solo si está aceptado)
            if (offer.status == 'accepted') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Lógica para saber quién es "el otro"
                    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
                    final isMeOfferer = offer.offererId == currentUserId;

                    final contactName = isMeOfferer ? offer.post.username : offer.offererUsername;
                    final contactAvatar = isMeOfferer ? offer.post.userAvatar : offer.offererAvatar;

                    // Navegamos pasando los datos de la otra persona
                    context.push('/chat/${offer.id}?name=${Uri.encodeComponent(contactName)}&avatar=${Uri.encodeComponent(contactAvatar)}');
                  },
                  icon: const Icon(LucideIcons.messageCircle),
                  label: const Text('Abrir Chat Seguro'),
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
    ref.invalidate(receivedOffersProvider);
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
    // Añadimos el nuevo estado:
    if (status == 'completed') { color = Colors.blue; text = 'Completado'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}