import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/create_offer_modal.dart';
import '../../data/shop_repository.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(shopFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado Global', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.search), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buscador próximamente...')));
          }),
        ],
      ),
      // RefreshIndicator para "Jalar hacia abajo y recargar"
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shopFeedProvider);
        },
        child: feedState.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        // CORRECCIÓN 1: Usamos Icons.explore nativo
                        Icon(Icons.explore, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hay intercambios disponibles aún.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera del usuario
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(item.ownerAvatar),
                        ),
                        title: Text(item.ownerUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Publicado hace un momento', style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
                      ),

                      // Imagen de la carta (Optimizada con caché)
                      CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey, child: const Center(child: CircularProgressIndicator())),
                      ),

                      // Info de la publicación
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ofrece:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(item.offerItemName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.arrowRightLeft, size: 16, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Busca: ${item.lookingFor}',
                                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Botón de Oferta
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // AQUÍ ABRIMOS EL MODAL PROFESIONAL
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => CreateOfferModal(item: item),
                                  );
                                },
                                icon: const Icon(Icons.handshake),
                                label: const Text('Hacer Oferta', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error al cargar: $e')),
        ),
      ),
    );
  }
}