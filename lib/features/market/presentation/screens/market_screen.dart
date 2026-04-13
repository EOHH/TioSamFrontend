import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Importa el provider que acabamos de crear
import '../../data/market_repository.dart';

class MarketScreen extends HookConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado de nuestro mercado (Cargando, Error, o Datos)
    final marketState = ref.watch(marketFeedProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey,
      appBar: AppBar(
        title: const Text('Mercado de Intercambio', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {
              // TODO: Implementar la barra de búsqueda en el futuro
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Búsqueda próximamente...')),
              );
            },
          ),
        ],
      ),
      // 👇 MAGIA UX: Pull-to-refresh
      body: RefreshIndicator(
        onRefresh: () async {
          // Esto vuelve a ejecutar la consulta a Supabase
          return ref.refresh(marketFeedProvider.future);
        },
        child: marketState.when(
          data: (trades) {
            if (trades.isEmpty) {
              return ListView( // Usamos ListView para que el RefreshIndicator siga funcionando aunque esté vacío
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No hay publicaciones activas en este momento.', style: TextStyle(color: Colors.grey))),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trades.length,
              itemBuilder: (context, index) {
                final trade = trades[index];
                // Gracias a la "Magia Relacional", Supabase nos anidó los datos del usuario en la llave 'users'
                final user = trade['users'] ?? {};

                final imageUrl = trade['image_url'] as String?;
                final offerItem = trade['offer_item'] ?? 'Carta misteriosa';
                final requestItem = trade['request_item'] ?? 'Ofertas';
                final username = user['username'] ?? 'Coleccionista';
                final avatarUrl = user['avatar_url'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Imagen de la Carta
                      if (imageUrl != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey), // Sombra temporal
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),

                      // 2. Información del Intercambio
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    offerItem,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Busca: $requestItem',
                                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 3. Datos del Usuario y Botón de Oferta
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                                  child: avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
                                ),
                                const SizedBox(width: 8),
                                Text(username, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Navegar a los detalles de la oferta
                                  },
                                  icon: const Icon(LucideIcons.handshake, size: 16),
                                  label: const Text('Ofertar'),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          // Por ahora un simple circulito. ¡En la Fase 3 lo cambiaremos por Skeletons!
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Ocurrió un error: $e')),
        ),
      ),
    );
  }
}