import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/models/collection_item.dart';
import '../../data/collection_repository.dart';
import '../controllers/collection_controller.dart'; // Para refrescar la galería

class CollectionDetailScreen extends ConsumerWidget {
  final CollectionItem item;

  const CollectionDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Función para confirmar eliminación
    void confirmDelete() {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('¿Eliminar de la vitrina?'),
          content: Text('Estás a punto de borrar "${item.cardName}". Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(dialogContext); // Cierra modal

                // Mostramos un indicador de carga visual rápido
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminando...')));

                // Ejecutamos el borrado
                await ref.read(collectionRepositoryProvider).deleteFromCollection(item.id);

                if (context.mounted) {
                  ref.invalidate(myCollectionProvider); // Refrescamos la cuadrícula
                  context.pop(); // Salimos de la pantalla de detalles
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carta eliminada de tu vitrina')));
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true, // Para que la imagen ocupe toda la pantalla
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
            onPressed: confirmDelete,
            tooltip: 'Eliminar carta',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LA MAGIA: El widget Hero conecta esta imagen con la de la cuadrícula
            Hero(
              tag: 'card_${item.id}',
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.55,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.cardName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Añadido el ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}",
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text("Detalles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    (item.description != null && item.description!.isNotEmpty)
                        ? item.description!
                        : "No se añadieron detalles a esta carta.",
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), height: 1.5),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}