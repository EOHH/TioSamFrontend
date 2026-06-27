import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/collection_item.dart';
import '../../data/collection_repository.dart';
import '../controllers/collection_controller.dart';

class _RarityInfo {
  final String cleanName;
  final String badge;
  final Color color;

  _RarityInfo(this.cleanName, this.badge, this.color);
}

_RarityInfo _parseRarity(String fullName) {
  String name = fullName;
  String badge = 'C';
  Color color = const Color(0xFF4CAF50); // Verde - Común

  final upper = fullName.toUpperCase();

  if (upper.contains('(LEG)') || upper.contains('(LR)') || upper.contains('(LEGENDARY)')) {
    badge = upper.contains('(LR)') ? 'LR' : 'LEG';
    color = const Color(0xFFFFD700); // Oro - Legendaria
    name = fullName.replaceAll(RegExp(r'\((LEG|LR|Legendary)\)', caseSensitive: false), '').trim();
  } else if (upper.contains('(UR)') || upper.contains('(SSR)')) {
    badge = upper.contains('(UR)') ? 'UR' : 'SSR';
    color = const Color(0xFFFF4B8B); // Rosa/Rojo - Épica
    name = fullName.replaceAll(RegExp(r'\((UR|SSR)\)', caseSensitive: false), '').trim();
  } else if (upper.contains('(SR)') || upper.contains('(R)')) {
    badge = upper.contains('(SR)') ? 'SR' : 'R';
    color = const Color(0xFF00C2FF); // Azul - Rara
    name = fullName.replaceAll(RegExp(r'\((SR|R)\)', caseSensitive: false), '').trim();
  }

  if (name.isEmpty) name = fullName;

  return _RarityInfo(name, badge, color);
}

class CollectionDetailScreen extends ConsumerWidget {
  final CollectionItem item;

  const CollectionDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = _parseRarity(item.cardName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void confirmDelete() {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.trash2, color: Colors.redAccent)),
              const SizedBox(width: 12),
              Expanded(child: Text('¿Eliminar carta?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text('Estás a punto de borrar "${info.cleanName}". Esta acción no se puede deshacer.', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), const SizedBox(width: 12), Text('Eliminando...', style: GoogleFonts.poppins())]),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 1),
                ));

                await ref.read(collectionRepositoryProvider).deleteFromCollection(item.id);

                if (context.mounted) {
                  ref.invalidate(myCollectionProvider);
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Carta eliminada de tu vitrina', style: GoogleFonts.poppins()), backgroundColor: Colors.black87));
                }
              },
              child: Text('Eliminar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. IMAGEN DE FONDO HERO
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Hero(
              tag: 'card_${item.id}',
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(item.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4) // Oscurecer un poco arriba para la barra
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. CONTENIDO DESLIZABLE
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Espacio transparente para ver la imagen
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.45),
                ),

                // Tarjeta de detalles
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      boxShadow: [BoxShadow(color: info.color.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, -10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Línea de arrastre
                        Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 24),

                        // Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: info.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: info.color.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(info.badge == 'C' ? LucideIcons.circle : LucideIcons.star, color: info.color, size: 14),
                                  const SizedBox(width: 6),
                                  Text(info.badge, style: GoogleFonts.poppins(color: info.color, fontWeight: FontWeight.w900, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Añadido el ${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}/${item.createdAt.year}",
                              style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Título
                        Text(
                          info.cleanName,
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Detalles
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF5E2BFF).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(LucideIcons.alignLeft, color: Color(0xFF5E2BFF), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text("Detalles de la carta", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (item.description != null && item.description!.isNotEmpty)
                              ? item.description!
                              : "No has añadido ninguna historia o detalle a esta carta. Edítala más tarde si consigues información interesante.",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                        
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3), // Espacio al final
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. APP BAR FLOTANTE (Botones)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2))),
                    child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                  ),
                ),
                GestureDetector(
                  onTap: confirmDelete,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.redAccent.withOpacity(0.5))),
                    child: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}