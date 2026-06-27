import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/collection_controller.dart';
import '../../domain/models/collection_item.dart';
import '../widgets/add_collection_modal.dart';
import '../../../shop/presentation/controllers/shop_controller.dart';

class _RarityInfo {
  final String cleanName;
  final String badge;
  final Color color;
  final String category;

  _RarityInfo(this.cleanName, this.badge, this.color, this.category);
}

_RarityInfo _parseRarity(String fullName) {
  String name = fullName;
  String badge = 'C';
  Color color = const Color(0xFF4CAF50); // Verde - Común
  String category = 'Comunes';

  final upper = fullName.toUpperCase();

  if (upper.contains('(LEG)') || upper.contains('(LR)') || upper.contains('(LEGENDARY)')) {
    badge = upper.contains('(LR)') ? 'LR' : 'LEG';
    color = const Color(0xFFFFD700); // Oro - Legendaria
    category = 'Legendarias';
    name = fullName.replaceAll(RegExp(r'\((LEG|LR|Legendary)\)', caseSensitive: false), '').trim();
  } else if (upper.contains('(UR)') || upper.contains('(SSR)')) {
    badge = upper.contains('(UR)') ? 'UR' : 'SSR';
    color = const Color(0xFFFF4B8B); // Rosa/Rojo - Épica
    category = 'Épicas';
    name = fullName.replaceAll(RegExp(r'\((UR|SSR)\)', caseSensitive: false), '').trim();
  } else if (upper.contains('(SR)') || upper.contains('(R)')) {
    badge = upper.contains('(SR)') ? 'SR' : 'R';
    color = const Color(0xFF00C2FF); // Azul - Rara
    category = 'Raras';
    name = fullName.replaceAll(RegExp(r'\((SR|R)\)', caseSensitive: false), '').trim();
  }

  // Fallback si no había etiqueta en el nombre pero queremos conservar el nombre original
  if (name.isEmpty) name = fullName;

  return _RarityInfo(name, badge, color, category);
}

class CollectionScreen extends HookConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionState = ref.watch(myCollectionProvider);
    final walletState = ref.watch(shopControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedCategory = useState('Todas');
    final isGridView = useState(true);
    final sortBy = useState('Más recientes');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE),
      body: collectionState.when(
        data: (items) {
          // 1. Calcular Estadísticas
          int total = items.length;
          int legendarias = 0;
          int epicas = 0;
          int raras = 0;
          int comunes = 0;

          for (var item in items) {
            final info = _parseRarity(item.cardName);
            if (info.category == 'Legendarias') legendarias++;
            if (info.category == 'Épicas') epicas++;
            if (info.category == 'Raras') raras++;
            if (info.category == 'Comunes') comunes++;
          }

          // 2. Filtrar
          List<CollectionItem> filteredItems = List.from(items);
          if (selectedCategory.value != 'Todas') {
            filteredItems = filteredItems.where((item) => _parseRarity(item.cardName).category == selectedCategory.value).toList();
          }

          // 3. Ordenar
          if (sortBy.value == 'Más recientes') {
            filteredItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } else if (sortBy.value == 'Más antiguas') {
            filteredItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          } else if (sortBy.value == 'A-Z') {
            filteredItems.sort((a, b) => a.cardName.compareTo(b.cardName));
          }

          return Stack(
            children: [
              // --- HEADER GRADIENT ---
              Container(
                height: 280,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5E2BFF), Color(0xFF00C2FF)],
                  ),
                ),
              ),

              // --- CONTENIDO SCROLLABLE ---
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // HEADER ACTIONS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button (si se puede)
                          if (context.canPop())
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                              ),
                            )
                          else
                            const SizedBox(width: 36), // Placeholder para mantener alineación

                          // Gemas
                          walletState.when(
                            data: (wallet) => GestureDetector(
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
                                      (wallet?.gems ?? 0).toString(),
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
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      ),
                    ),

                    // TITULO Y BOTON AGREGAR
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mi Vitrina ✨', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                const SizedBox(height: 4),
                                Text('Tus cartas más increíbles 🌟', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const AddCollectionModal(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.plus, color: Color(0xFF5E2BFF), size: 16),
                                  const SizedBox(width: 6),
                                  Text('Agregar Carta', style: GoogleFonts.poppins(color: const Color(0xFF5E2BFF), fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CUERPO BLANCO REDONDEADO
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Column(
                          children: [
                            // FILTROS
                            Padding(
                              padding: const EdgeInsets.only(top: 20, bottom: 10),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    _buildFilterChip('Todas', selectedCategory.value, (v) => selectedCategory.value = v, icon: LucideIcons.layoutGrid, color: const Color(0xFF7C4DFF)),
                                    _buildFilterChip('Legendarias', selectedCategory.value, (v) => selectedCategory.value = v, icon: LucideIcons.star, color: const Color(0xFFFFD700)),
                                    _buildFilterChip('Épicas', selectedCategory.value, (v) => selectedCategory.value = v, icon: LucideIcons.gem, color: const Color(0xFFFF4B8B)),
                                    _buildFilterChip('Raras', selectedCategory.value, (v) => selectedCategory.value = v, icon: LucideIcons.diamond, color: const Color(0xFF00C2FF)),
                                    _buildFilterChip('Comunes', selectedCategory.value, (v) => selectedCategory.value = v, icon: LucideIcons.circle, color: const Color(0xFF4CAF50)),
                                  ],
                                ),
                              ),
                            ),

                            // BARRA DE HERRAMIENTAS (Ordenar y Vista)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  PopupMenuButton<String>(
                                    onSelected: (val) => sortBy.value = val,
                                    offset: const Offset(0, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(value: 'Más recientes', child: Text('Más recientes', style: GoogleFonts.poppins())),
                                      PopupMenuItem(value: 'Más antiguas', child: Text('Más antiguas', style: GoogleFonts.poppins())),
                                      PopupMenuItem(value: 'A-Z', child: Text('A-Z', style: GoogleFonts.poppins())),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Text('Ordenar por: ', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                                          Text(sortBy.value, style: GoogleFonts.poppins(color: const Color(0xFF5E2BFF), fontWeight: FontWeight.bold, fontSize: 12)),
                                          const SizedBox(width: 4),
                                          const Icon(LucideIcons.chevronDown, color: Color(0xFF5E2BFF), size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => isGridView.value = true,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isGridView.value ? const Color(0xFF7C4DFF) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(LucideIcons.layoutGrid, color: isGridView.value ? Colors.white : Colors.grey, size: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => isGridView.value = false,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: !isGridView.value ? const Color(0xFF7C4DFF) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(LucideIcons.list, color: !isGridView.value ? Colors.white : Colors.grey, size: 18),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            // LISTA DE CARTAS
                            Expanded(
                              child: filteredItems.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.album, size: 64, color: Colors.grey.withOpacity(0.3)),
                                          const SizedBox(height: 16),
                                          Text("No se encontraron cartas", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  : isGridView.value
                                      ? GridView.builder(
                                          padding: const EdgeInsets.all(16).copyWith(bottom: 100), // padding bottom for stats
                                          physics: const BouncingScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.65,
                                          ),
                                          itemCount: filteredItems.length,
                                          itemBuilder: (context, index) {
                                            return _buildCardItem(context, filteredItems[index]);
                                          },
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: filteredItems.length,
                                          itemBuilder: (context, index) {
                                            return _buildListItem(context, filteredItems[index]);
                                          },
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- STATS FOOTER FLOATING ---
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(total.toString(), 'Cartas', const Color(0xFF5E2BFF)),
                      _buildStatColumn(legendarias.toString(), 'Legendarias', const Color(0xFFFFD700)),
                      _buildStatColumn(epicas.toString(), 'Épicas', const Color(0xFFFF4B8B)),
                      _buildStatColumn(raras.toString(), 'Raras', const Color(0xFF00C2FF)),
                      _buildStatColumn(comunes.toString(), 'Comunes', const Color(0xFF4CAF50)),
                    ],
                  ),
                ),
              )
            ],
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }

  Widget _buildFilterChip(String label, String current, Function(String) onSelect, {required IconData icon, required Color color}) {
    final isSelected = label == current;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: GoogleFonts.poppins(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCardItem(BuildContext context, CollectionItem item) {
    final info = _parseRarity(item.cardName);

    return GestureDetector(
      onTap: () => context.push('/collection-detail', extra: item),
      child: Hero(
        tag: 'card_${item.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: info.color.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: info.color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              image: DecorationImage(
                image: CachedNetworkImageProvider(item.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Top Left Badge
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6), border: Border.all(color: info.color, width: 1)),
                    child: Text(info.badge, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
                // Top Right Star
                Positioned(
                  top: 6, right: 6,
                  child: Icon(LucideIcons.star, color: info.color, size: 16),
                ),
                // Bottom Gradient & Text
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(info.cleanName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                        if (info.badge != 'C') ...[
                          const SizedBox(height: 2),
                          Text('(${info.badge})', style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, CollectionItem item) {
    final info = _parseRarity(item.cardName);

    return GestureDetector(
      onTap: () => context.push('/collection-detail', extra: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'card_${item.id}',
              child: Container(
                width: 60, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: info.color.withOpacity(0.5), width: 1),
                  image: DecorationImage(image: CachedNetworkImageProvider(item.imageUrl), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.cleanName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: info.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: info.color.withOpacity(0.5))),
                        child: Text(info.badge, style: GoogleFonts.poppins(color: info.color, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      Text(item.createdAt.toString().split(' ')[0], style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}