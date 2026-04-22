import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

import '../controllers/shop_controller.dart';

class ShopScreen extends HookConsumerWidget {
  const ShopScreen({super.key});

  // 💎 LÓGICA REUTILIZABLE PARA COMPRAS CON GEMAS INTERNAS (VIP / Vitrina / Destacar)
  void _showConfirmModal(BuildContext context, WidgetRef ref, {
    required String itemName,
    required int gemCost,
    required Color color,
    required IconData icon,
    required Future<bool> Function() onConfirm
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            const Text('Confirmar Activación', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('¿Deseas activar "$itemName" por $gemCost Gemas?', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);

                      final success = await onConfirm();

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [const Icon(LucideIcons.checkCircle2, color: Colors.white), const SizedBox(width: 8), Text('¡$itemName activado! 🎉')]),
                            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Activar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escucha de errores (Gemas insuficientes, tarjeta rechazada, etc.)
    ref.listen<AsyncValue>(shopControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    });

    final shopState = ref.watch(shopControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey,
      appBar: AppBar(
        title: const Text('Tienda Exclusiva', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey,
        actions: [
          // INDICADOR DE SALDO DE GEMAS
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                shopState.when(
                  data: (wallet) => Text(
                      wallet?.gems.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)
                  ),
                  loading: () => const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const Text('!', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 6),
                const Icon(LucideIcons.gem, color: Colors.blueAccent, size: 16),
              ],
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(shopControllerProvider);
          ref.refresh(storePackagesProvider); // Refresca los productos de RevenueCat
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- 1. SECCIÓN VIP ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildVIPCard(context, isDark, ref),
              ),

              const SizedBox(height: 8),
              _buildSectionTitle('Servicios para Coleccionistas'),

              // --- 2. SECCIÓN DE SERVICIOS (Gasto Interno) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                          context, isDark, title: 'Destacar\nPublicación', icon: LucideIcons.rocket, price: '50', color: Colors.orange,
                          onTap: () {
                            _showConfirmModal(
                                context, ref,
                                itemName: 'Destacar Publicación (24h)', gemCost: 50, color: Colors.orange, icon: LucideIcons.rocket,
                                onConfirm: () async {
                                  // Pendiente de implementación real del Boost
                                  return true;
                                }
                            );
                          }
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildServiceCard(
                          context, isDark, title: 'Expandir\nVitrina (+10)', icon: LucideIcons.packageOpen, price: '100', color: Colors.purple,
                          onTap: () {
                            _showConfirmModal(
                                context, ref,
                                itemName: 'Expandir Vitrina (+10 espacios)', gemCost: 100, color: Colors.purple, icon: LucideIcons.packageOpen,
                                onConfirm: () async => await ref.read(shopControllerProvider.notifier).purchaseExtraSlots()
                            );
                          }
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Comprar Gemas (Dinero Real)'),

              // --- 3. SECCIÓN DE MONEDA VIRTUAL (REVENUECAT REAL) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Consumer(
                  builder: (context, ref, child) {
                    final packagesState = ref.watch(storePackagesProvider);

                    return packagesState.when(
                      data: (packages) {
                        if (packages.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: isDark ? Colors.grey : Colors.grey, borderRadius: BorderRadius.circular(16)),
                            child: const Center(
                                child: Text('💳 La tienda se activará pronto.\n(Requiere configuración de Google Play / Apple)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                            ),
                          );
                        }

                        // Construye un botón real por cada producto en la consola de Google/Apple
                        return Column(
                          children: packages.map((package) {

                            // Lógica básica para deducir gemas según el ID del producto que configures en la consola.
                            // Ejemplo: si el id es 'com.tiosam.100gems', dará 100 gemas.
                            int gemsReward = 100;
                            if (package.storeProduct.identifier.contains('500')) gemsReward = 500;
                            if (package.storeProduct.identifier.contains('1200')) gemsReward = 1200;

                            bool isPopular = gemsReward == 500;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildRealGemPackage(
                                  context, isDark, ref,
                                  package: package, gems: gemsReward, isPopular: isPopular
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => Center(child: Text('Error de conexión con la Tienda.\nVerifica tu configuración de RevenueCat.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))),
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
    );
  }

  Widget _buildVIPCard(BuildContext context, bool isDark, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        _showConfirmModal(
            context, ref,
            itemName: 'Coleccionista PRO (Mensual)', gemCost: 300, color: Colors.amber, icon: LucideIcons.crown,
            onConfirm: () async => await ref.read(shopControllerProvider.notifier).purchaseVip()
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.crown, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coleccionista PRO', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      Text('Suscripción Mensual', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(children: [Icon(LucideIcons.check, color: Colors.white, size: 16), SizedBox(width: 8), Text('Publicaciones ilimitadas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))]),
            const SizedBox(height: 8),
            const Row(children: [Icon(LucideIcons.check, color: Colors.white, size: 16), SizedBox(width: 8), Text('Insignia VIP dorada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))]),
            const SizedBox(height: 20),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Suscribirse por 300 ', style: TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.w800, fontSize: 16)),
                  Icon(LucideIcons.gem, color: Color(0xFFFF8C00), size: 16),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, bool isDark, {required String title, required IconData icon, required String price, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: isDark ? Colors.grey : Colors.grey, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.gem, size: 14, color: Colors.blueAccent),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // WIDGET PARA PAQUETES REALES DE REVENUECAT
  Widget _buildRealGemPackage(BuildContext context, bool isDark, WidgetRef ref, {required Package package, required int gems, bool isPopular = false}) {
    Color iconColor = isPopular ? Colors.blueAccent : Colors.purpleAccent;

    return GestureDetector(
      onTap: () async {
        // 🔥 ESTE BOTÓN INICIA EL PAGO CON HUELLA DIGITAL / FACE ID
        final success = await ref.read(shopControllerProvider.notifier).buyRealGemsPack(package, gems);

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [const Icon(LucideIcons.gem, color: Colors.white), const SizedBox(width: 8), Text('¡+$gems Gemas compradas con éxito!')]),
              backgroundColor: Colors.blueAccent, behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              border: isPopular ? Border.all(color: Colors.blueAccent, width: 2) : Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(LucideIcons.gem, color: iconColor, size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.storeProduct.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(package.storeProduct.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: isPopular ? Colors.blueAccent : Colors.green, borderRadius: BorderRadius.circular(12)),
                  child: Text(package.storeProduct.priceString, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: -10, left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 4)]),
                child: const Text('MÁS POPULAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
        ],
      ),
    );
  }
}