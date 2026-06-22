import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../data/shop_repository.dart';
import '../../domain/models/user_wallet.dart';

// Proveedor para obtener los paquetes reales de la tienda (Google Play / Apple Store)
final storePackagesProvider = FutureProvider.autoDispose<List<Package>>((ref) async {
  return ref.watch(shopRepositoryProvider).getRealOfferings();
});

class ShopController extends StateNotifier<AsyncValue<UserWallet?>> {
  final ShopRepository _repository;

  ShopController(this._repository) : super(const AsyncLoading()) {
    loadWallet();
  }

  // --- 1. CARGAR SALDO ---
  Future<void> loadWallet() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getMyWallet());
  }

  // --- 2. COMPRA REAL (REVENUECAT) ---
  Future<bool> buyRealGemsPack(Package package, int gemsReward) async {
    state = const AsyncLoading();
    try {
      await _repository.buyGemsWithRealMoney(package);
      // Recargamos el estado (aunque el webhook puede tardar unos segundos)
      await loadWallet();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      // Recargamos el wallet por si el error fue de red pero el pago sí pasó
      await loadWallet();
      return false;
    }
  }

  // --- 3. COMPRAR EXPANSIÓN (+10 ESPACIOS) ---
  Future<bool> purchaseExtraSlots() async {
    state = const AsyncLoading();
    try {
      final updatedWallet = await _repository.buyExtraSlots();
      state = AsyncData(updatedWallet);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // --- 4. COMPRAR STATUS VIP (REVENUECAT REAL) ---
  Future<bool> purchaseVip() async {
    state = const AsyncLoading();
    try {
      Offerings offerings = await Purchases.getOfferings();

      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {

        Package vipPackage = offerings.current!.availablePackages.firstWhere(
              (pkg) =>
          pkg.storeProduct.identifier.contains('vip') ||
              pkg.packageType == PackageType.monthly,
          orElse: () => offerings.current!.availablePackages.first,
        );

        final purchaseResult = await Purchases.purchase(
          PurchaseParams.package(vipPackage),
        );

        final isPremium = purchaseResult.customerInfo.entitlements
            .all['pro_status']?.isActive ?? false;

        await loadWallet();

        return isPremium;
      } else {
        throw Exception("No se encontraron paquetes VIP configurados en la tienda.");
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      await loadWallet();
      return false;
    }
  }

  // --- 5. DESTACAR PUBLICACIÓN (BOOST) ---
  Future<bool> boostPost(String postId) async {
    state = const AsyncLoading();
    try {
      final updatedWallet = await _repository.boostPost(postId);
      state = AsyncData(updatedWallet);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// Proveedor global del controlador
final shopControllerProvider = StateNotifierProvider.autoDispose<ShopController, AsyncValue<UserWallet?>>((ref) {
  return ShopController(ref.watch(shopRepositoryProvider));
});