import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../profile/presentation/controllers/my_posts_controller.dart';
import '../controllers/shop_controller.dart';

class ShopScreen extends HookConsumerWidget {
  const ShopScreen({super.key});

  final bool isDesignMode = true;

  String _cleanTitle(String rawTitle) {
    final parts = rawTitle.split('(');
    if (parts.isNotEmpty) return parts.first.trim();
    return rawTitle;
  }

  // ✨ EL NUEVO DIÁLOGO PREMIUM: GEMAS INSUFICIENTES
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
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(LucideIcons.diamond, size: 48, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            const Text('¡Gemas Insuficientes!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text('No tienes el saldo necesario para realizar esta acción. Adquiere un paquete de gemas más abajo en la tienda.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Ver Paquetes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💎 MODAL DE CONFIRMACIÓN REUTILIZABLE (Para compras con gemas)
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
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 20),
            const Text('Confirmar Activación', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text('¿Deseas activar "$itemName" por $gemCost Gemas?', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
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
                            content: const Row(children: [Icon(LucideIcons.checkCircle2, color: Colors.white), SizedBox(width: 12), Text('¡Activado con éxito! 🎉', style: TextStyle(fontWeight: FontWeight.bold))]),
                            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    child: const Text('Activar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // EL MODAL QUE MUESTRA TUS CARTAS PARA DESTACARLAS
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
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(LucideIcons.rocket, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('Destacar Carta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Selecciona una de tus publicaciones disponibles para anclarla en lo más alto del mercado.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final myPostsState = ref.watch(myHistoryFeedProvider);

                    return myPostsState.when(
                      data: (posts) {
                        final eligiblePosts = posts.where((p) => p['status'] == 'open' && p['is_boosted'] != true).toList();

                        if (eligiblePosts.isEmpty) {
                          return const Center(
                            child: Text('No tienes publicaciones disponibles para destacar.\n(O ya están todas destacadas)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
                                      : Container(width: 60, height: 60, color: Colors.blueAccent.withValues(alpha: 0.1), child: const Icon(LucideIcons.image, color: Colors.blueAccent)),
                                ),
                                title: Text(post['offer_item'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: Text('Busca: ${post['request_item'] ?? 'Cualquiera'}', style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showConfirmModal(
                                        context, ref,
                                        itemName: 'Boost: ${post['offer_item']}',
                                        gemCost: 50,
                                        color: Colors.orange,
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
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: const Text('Elegir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => const Center(child: Text('Error al cargar publicaciones.')),
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

    // 🔥 LA ANTENA MEJORADA: Detecta si falta dinero y lanza el Modal Premium
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
                      Expanded(child: Text(errorMsg.replaceAll("Exception: ", ""), style: const TextStyle(fontWeight: FontWeight.bold))),
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
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Tienda Exclusiva', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5, fontSize: 24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          _AnimatedScaleButton(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF00BCD4)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  shopState.when(
                    data: (wallet) => Text(wallet?.gems.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                    loading: () => const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    error: (_, __) => const Text('!', style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.gem, color: Colors.white, size: 16),
                ],
              ),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
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
              // --- 1. SECCIÓN VIP ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildVIPCard(context, ref),
              ),

              const SizedBox(height: 8),
              _buildSectionTitle('Servicios para Coleccionistas'),

              // --- 2. SECCIÓN DE SERVICIOS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                        context, isDark, title: 'Destacar\nPublicación', icon: LucideIcons.rocket, price: '50', color: const Color(0xFFFF3B30),
                        onTap: () => _showSelectPostModal(context, ref),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildServiceCard(
                          context, isDark, title: 'Expandir\nVitrina (+10)', icon: LucideIcons.packageOpen, price: '100', color: const Color(0xFFAF52DE),
                          onTap: () => _showConfirmModal(context, ref, itemName: 'Expandir Vitrina', gemCost: 100, color: const Color(0xFFAF52DE), icon: LucideIcons.packageOpen, onConfirm: () async => await ref.read(shopControllerProvider.notifier).purchaseExtraSlots())
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Comprar Gemas'),

              // --- 3. SECCIÓN DE REVENUECAT ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: isDesignMode ? _buildMockPackages(context, isDark, ref) : _buildRealPackages(context, isDark, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE UI ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.grey)),
    );
  }

  // 👑 CARTA VIP MEJORADA CON PRECIO DINÁMICO DE REVENUECAT
  Widget _buildVIPCard(BuildContext context, WidgetRef ref) {
    final packagesState = ref.watch(storePackagesProvider);

    String priceText = 'Cargando...';

    // Extraemos el precio real de la tienda (Google Play / Apple)
    packagesState.whenData((packages) {
      final vipPkgs = packages.where((p) => p.storeProduct.identifier.contains('vip') || p.packageType == PackageType.monthly);
      if (vipPkgs.isNotEmpty) {
        priceText = '${vipPkgs.first.storeProduct.priceString} / mes';
      } else {
        priceText = 'Suscribirse';
      }
    });

    return _AnimatedScaleButton(
      // Ya no mostramos un modal de gemas. Va directo al pago nativo.
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(LucideIcons.crown, color: Colors.white, size: 32)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coleccionista PRO', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      Text('Suscripción Mensual', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Row(children: [Icon(LucideIcons.check, color: Colors.white, size: 18), SizedBox(width: 12), Text('Publicaciones ilimitadas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))]),
            const SizedBox(height: 12),
            const Row(children: [Icon(LucideIcons.check, color: Colors.white, size: 18), SizedBox(width: 12), Text('Insignia VIP dorada en perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))]),
            const SizedBox(height: 24),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(priceText, style: const TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, bool isDark, {required String title, required IconData icon, required String price, required Color color, required VoidCallback onTap}) {
    return _AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))],
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 32)),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, height: 1.2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.gem, size: 16),
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
      {'title': '100 Gemas', 'desc': 'Un empujón para destacar.', 'price': 'S/ 7.90', 'gems': 100, 'pop': false, 'icon': LucideIcons.gem},
      {'title': '500 Gemas', 'desc': 'Ideal para coleccionistas activos.', 'price': 'S/ 18.90', 'gems': 500, 'pop': true, 'icon': LucideIcons.component},
      {'title': '1200 Gemas', 'desc': 'El tesoro definitivo de TioSam.', 'price': 'S/ 37.90', 'gems': 1200, 'pop': false, 'icon': LucideIcons.crown},
    ];

    return Column(
      children: mockData.map((data) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _AnimatedScaleButton(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo Diseño: Compra simulada.'))),
          child: _GemPackageUI(
            title: data['title'] as String, description: data['desc'] as String, priceStr: data['price'] as String,
            isPopular: data['pop'] as bool, isDark: isDark, icon: data['icon'] as IconData,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRealPackages(BuildContext context, bool isDark, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final packagesState = ref.watch(storePackagesProvider);
        return packagesState.when(
          data: (packages) {
            // Filtramos para que no muestre el paquete VIP en la lista de gemas, ya que tiene su propio botón grande arriba
            final gemPackages = packages.where((p) => !p.storeProduct.identifier.contains('vip') && p.packageType != PackageType.monthly).toList();

            if (gemPackages.isEmpty) return const Center(child: Text('La tienda está vacía.'));
            return Column(
              children: gemPackages.map((package) {
                int gemsReward = 100;
                IconData dynIcon = LucideIcons.gem;
                if (package.storeProduct.identifier.contains('500')) { gemsReward = 500; dynIcon = LucideIcons.component; }
                if (package.storeProduct.identifier.contains('1200')) { gemsReward = 1200; dynIcon = LucideIcons.crown; }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _AnimatedScaleButton(
                    onTap: () async {
                      final success = await ref.read(shopControllerProvider.notifier).buyRealGemsPack(package, gemsReward);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡+$gemsReward Gemas compradas con éxito!'), backgroundColor: Colors.green));
                      }
                    },
                    child: _GemPackageUI(
                      title: _cleanTitle(package.storeProduct.title),
                      description: package.storeProduct.description, priceStr: package.storeProduct.priceString,
                      isPopular: gemsReward == 500, isDark: isDark, icon: dynIcon,
                    ),
                  ),
                );
              }).toList(),
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
  final String title; final String description; final String priceStr; final bool isPopular; final bool isDark; final IconData icon;
  const _GemPackageUI({required this.title, required this.description, required this.priceStr, required this.isPopular, required this.isDark, required this.icon});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = isPopular ? const Color(0xFF007AFF) : const Color(0xFF32ADE6);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: isPopular ? primaryColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 8))],
            border: isPopular ? Border.all(color: primaryColor, width: 2) : Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.1 : 0.2)),
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: primaryColor, size: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: isPopular ? primaryColor : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)), borderRadius: BorderRadius.circular(16)),
                child: Text(priceStr, style: TextStyle(color: isPopular ? Colors.white : (isDark ? Colors.white : Colors.black), fontWeight: FontWeight.w900, fontSize: 16)),
              )
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -12, left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF9500)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))]),
              child: const Text('MÁS POPULAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
      ],
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