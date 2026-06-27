import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../profile/presentation/controllers/my_posts_controller.dart';
import '../controllers/shop_controller.dart';

class ShopScreen extends HookConsumerWidget {
  const ShopScreen({super.key});

  final bool isDesignMode = false; // Cambiado a false para usar datos reales por defecto

  String _cleanTitle(String rawTitle) {
    final parts = rawTitle.split('(');
    if (parts.isNotEmpty) return parts.first.trim();
    return rawTitle;
  }

  void _showNotEnoughGemsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(LucideIcons.diamond, size: 48, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            Text('¡Gemas Insuficientes!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('No tienes el saldo necesario para realizar esta acción. Adquiere un paquete de gemas más abajo en la tienda.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('Ver Paquetes', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmModal(BuildContext context, WidgetRef ref, {
    required String itemName, required int gemCost, required Color color, required IconData icon, required Future<bool> Function() onConfirm
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 20),
            Text('Confirmar Activación', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text('¿Deseas activar "$itemName" por $gemCost Gemas?', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final success = await onConfirm();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [const Icon(LucideIcons.checkCircle2, color: Colors.white), const SizedBox(width: 12), Text('¡Activado con éxito! 🎉', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))]),
                            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    child: Text('Activar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showSelectPostModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.65,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(LucideIcons.rocket, color: Color(0xFF9D4EDD), size: 28),
                  const SizedBox(width: 12),
                  Text('Destacar Carta', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Selecciona una de tus publicaciones disponibles para anclarla en lo más alto del mercado.', style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 24),

              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final myPostsState = ref.watch(myHistoryFeedProvider);

                    return myPostsState.when(
                      data: (posts) {
                        final eligiblePosts = posts.where((p) => p['status'] == 'open' && p['is_boosted'] != true).toList();

                        if (eligiblePosts.isEmpty) {
                          return Center(
                            child: Text('No tienes publicaciones disponibles para destacar.\n(O ya están todas destacadas)', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey)),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: eligiblePosts.length,
                          itemBuilder: (context, index) {
                            final post = eligiblePosts[index];
                            final imageUrl = post['image_url'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imageUrl != null && imageUrl.toString().isNotEmpty
                                      ? CachedNetworkImage(imageUrl: imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                                      : Container(width: 60, height: 60, color: const Color(0xFF9D4EDD).withOpacity(0.1), child: const Icon(LucideIcons.image, color: Color(0xFF9D4EDD))),
                                ),
                                title: Text(post['offer_item'] ?? 'Sin nombre', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: Text('Busca: ${post['request_item'] ?? 'Cualquiera'}', style: GoogleFonts.poppins(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showConfirmModal(
                                        context, ref,
                                        itemName: 'Boost: ${post['offer_item']}',
                                        gemCost: 50,
                                        color: const Color(0xFF9D4EDD),
                                        icon: LucideIcons.rocket,
                                        onConfirm: () async {
                                          final success = await ref.read(shopControllerProvider.notifier).boostPost(post['id']);
                                          if (success) {
                                            ref.refresh(myHistoryFeedProvider);
                                          }
                                          return success;
                                        }
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: Text('Elegir', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error al cargar publicaciones.', style: GoogleFonts.poppins())),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shopState = ref.watch(shopControllerProvider);

    ref.listen<AsyncValue>(shopControllerProvider, (previous, next) {
      if (next is AsyncError) {
        final errorMsg = next.error.toString();
        if (errorMsg.contains('suficientes Gemas') || errorMsg.contains('suficiente')) {
          _showNotEnoughGemsDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Row(
                    children: [
                      const Icon(LucideIcons.alertOctagon, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(errorMsg.replaceAll("Exception: ", ""), style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating
              )
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Fondo Header Gradient
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

          // Contenido Scrollable
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.refresh(shopControllerProvider);
                if (!isDesignMode) ref.refresh(storePackagesProvider);
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER TEXT & GEMS ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tienda Exclusiva',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mejora tu experiencia y colecciona más ✨',
                                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          // Etiqueta de Gemas
                          shopState.when(
                            data: (wallet) {
                              final gems = wallet?.gems ?? 0;
                              return Container(
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
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      ),
                    ),

                    // --- 1. SECCIÓN VIP ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: _buildVIPCard(context, ref),
                    ),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Servicios para Coleccionistas', 'Ver todos >'),

                    // --- 2. SECCIÓN DE SERVICIOS ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildServiceCard(
                              context,
                              title: 'Destacar\nPublicación',
                              subtitle: 'Tu publicación\naparecerá en\nprimer lugar',
                              icon: LucideIcons.rocket,
                              price: '50',
                              gradientColors: const [Color(0xFFB57BFF), Color(0xFF8B3DFF)],
                              onTap: () => _showSelectPostModal(context, ref),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildServiceCard(
                              context,
                              title: 'Expandir\nVitrina (+10)',
                              subtitle: 'Añade 10 espacios\nmás a tu vitrina\n ', // Espacio extra para alinear
                              icon: LucideIcons.packageOpen,
                              price: '100',
                              gradientColors: const [Color(0xFF4AC4FF), Color(0xFF0088FF)],
                              onTap: () => _showConfirmModal(context, ref, itemName: 'Expandir Vitrina', gemCost: 100, color: const Color(0xFF0088FF), icon: LucideIcons.packageOpen, onConfirm: () async => await ref.read(shopControllerProvider.notifier).purchaseExtraSlots()),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Comprar Gemas', 'Ver paquetes >'),

                    // --- 3. SECCIÓN DE REVENUECAT ---
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0), // Solo izq para que fluya hacia la derecha
                      child: SizedBox(
                        height: 240, // Altura fija para el carrusel horizontal
                        child: isDesignMode ? _buildMockPackages(context, isDark, ref) : _buildRealPackages(context, isDark, ref),
                      ),
                    ),

                    const SizedBox(height: 32),
                    
                    // --- 4. GANA GEMAS GRATIS ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9D4EDD), Color(0xFF00C2FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(LucideIcons.gift, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('¡Gana Gemas Gratis!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 2),
                                  Text('Completa misiones y gana recompensas', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  Text('Ir a Misiones', style: GoogleFonts.poppins(color: const Color(0xFF5E2BFF), fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Icon(LucideIcons.chevronRight, color: Color(0xFF5E2BFF), size: 14),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE UI ---
  Widget _buildSectionTitle(String title, String actionText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(width: 12, height: 3, decoration: BoxDecoration(color: const Color(0xFFFFD93D), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: const Color(0xFF1E293B))),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 12, height: 3, decoration: BoxDecoration(color: const Color(0xFFFFD93D), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(actionText, style: GoogleFonts.poppins(color: const Color(0xFF5E2BFF), fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // 👑 CARTA VIP MEJORADA CON PRECIO DINÁMICO DE REVENUECAT
  Widget _buildVIPCard(BuildContext context, WidgetRef ref) {
    final packagesState = ref.watch(storePackagesProvider);

    String priceText = 'Cargando...';

    packagesState.whenData((packages) {
      final vipPkgs = packages.where((p) => p.storeProduct.identifier.contains('vip') || p.packageType == PackageType.monthly);
      if (vipPkgs.isNotEmpty) {
        priceText = '${vipPkgs.first.storeProduct.priceString} / mes';
      } else {
        priceText = 'Suscribirse';
      }
    });

    return _AnimatedScaleButton(
      onTap: () async {
        final success = await ref.read(shopControllerProvider.notifier).purchaseVip();
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Bienvenido al club PRO! 👑'), backgroundColor: Colors.amber)
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFFFB200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0xFFFFB200).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Corona gigante
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(LucideIcons.crown, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.crown, color: Color(0xFFB45309), size: 18),
                          const SizedBox(width: 6),
                          Text('Coleccionista PRO', style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ],
                      ),
                      Text('Suscripción Mensual', style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A).withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildVIPPerk('Publicaciones ilimitadas'),
                      _buildVIPPerk('Insignia VIP dorada en perfil'),
                      _buildVIPPerk('Chat seguro prioritario'),
                      _buildVIPPerk('Acceso anticipado a nuevas funciones'),
                      _buildVIPPerk('Soporte VIP exclusivo'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(color: const Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(16)),
                  child: Text(priceText, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.crown, color: Color(0xFFFFB200), size: 16),
                        const SizedBox(width: 6),
                        Text('Obtener PRO', style: GoogleFonts.poppins(color: const Color(0xFFFFB200), fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVIPPerk(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Color(0xFF7C4DFF), shape: BoxShape.circle),
            child: const Icon(LucideIcons.check, color: Colors.white, size: 10),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required String price, required List<Color> gradientColors, required VoidCallback onTap}) {
    return _AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: gradientColors[1].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, height: 1.2)),
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.3)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.gem, color: Color(0xFF00C2FF), size: 16),
                  const SizedBox(width: 6),
                  Text(price, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMockPackages(BuildContext context, bool isDark, WidgetRef ref) {
    final mockData = [
      {'title': '100', 'desc': 'Gemas', 'price': 'S/ 7.90', 'gems': 100, 'badge': null},
      {'title': '550', 'desc': 'Gemas', 'price': 'S/ 29.90', 'gems': 550, 'badge': 'Popular'},
      {'title': '1200', 'desc': 'Gemas', 'price': 'S/ 59.90', 'gems': 1200, 'badge': 'Mejor valor'},
      {'title': '2500', 'desc': 'Gemas', 'price': 'S/ 99.90', 'gems': 2500, 'badge': null},
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: mockData.length,
      itemBuilder: (context, index) {
        final data = mockData[index];
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: _AnimatedScaleButton(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo Diseño: Compra simulada.'))),
            child: _GemPackageUI(
              title: data['title'] as String, subtitle: data['desc'] as String, priceStr: data['price'] as String, badge: data['badge'] as String?,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealPackages(BuildContext context, bool isDark, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final packagesState = ref.watch(storePackagesProvider);
        return packagesState.when(
          data: (packages) {
            final gemPackages = packages.where((p) => !p.storeProduct.identifier.contains('vip') && p.packageType != PackageType.monthly).toList();

            if (gemPackages.isEmpty) return const Center(child: Text('La tienda está vacía.'));
            
            // Si quieres ordenar por precio, podrías hacerlo aquí
            // gemPackages.sort((a, b) => a.storeProduct.price.compareTo(b.storeProduct.price));

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gemPackages.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final package = gemPackages[index];
                
                int gemsReward = 100;
                String? badgeStr;
                
                if (package.storeProduct.identifier.contains('500') || package.storeProduct.identifier.contains('550')) { gemsReward = 550; badgeStr = 'Popular'; }
                else if (package.storeProduct.identifier.contains('1200')) { gemsReward = 1200; badgeStr = 'Mejor valor'; }
                else if (package.storeProduct.identifier.contains('2500')) { gemsReward = 2500; }

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _AnimatedScaleButton(
                    onTap: () async {
                      final success = await ref.read(shopControllerProvider.notifier).buyRealGemsPack(package, gemsReward);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡+$gemsReward Gemas compradas con éxito!'), backgroundColor: Colors.green));
                      }
                    },
                    child: _GemPackageUI(
                      title: gemsReward.toString(),
                      subtitle: 'Gemas', 
                      priceStr: package.storeProduct.priceString,
                      badge: badgeStr,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: No se pudo conectar a Google Play.\n\n$err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))),
        );
      },
    );
  }
}

class _GemPackageUI extends StatelessWidget {
  final String title; final String subtitle; final String priceStr; final String? badge;
  const _GemPackageUI({required this.title, required this.subtitle, required this.priceStr, this.badge});

  @override
  Widget build(BuildContext context) {
    final bool isPopular = badge == 'Popular';
    final bool isBestValue = badge == 'Mejor valor';

    return Container(
      width: 140, // Ancho fijo para las tarjetas horizontales
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF00C2FF).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(title, style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5, height: 1.1)),
                    Text(subtitle, style: GoogleFonts.poppins(color: const Color(0xFF1E293B).withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                
                // Icono grande de gema
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Icon(LucideIcons.gem, color: Color(0xFF00C2FF), size: 48), // Alternativa porque no tenemos el PNG del cofre
                ),

                // Precio Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: Text(priceStr, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                )
              ],
            ),
          ),
          
          if (badge != null)
            Positioned(
              bottom: 60, // Posicionado justo arriba del botón de precio
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isPopular ? [const Color(0xFFFF4B8B), const Color(0xFFFF719A)] : [const Color(0xFFFFB200), const Color(0xFFFFD700)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: (isPopular ? const Color(0xFFFF4B8B) : const Color(0xFFFFB200)).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPopular) const Icon(LucideIcons.flame, color: Colors.white, size: 10) else const Icon(LucideIcons.star, color: Colors.white, size: 10),
                    const SizedBox(width: 4),
                    Text(badge!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedScaleButton extends HookWidget {
  final Widget child; final VoidCallback onTap;
  const _AnimatedScaleButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);
    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) { isPressed.value = false; onTap(); },
      onTapCancel: () => isPressed.value = false,
      child: AnimatedScale(
        scale: isPressed.value ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}