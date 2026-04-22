import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../data/shop_repository.dart';
import '../../domain/models/user_wallet.dart';

final storePackagesProvider = FutureProvider.autoDispose<List<Package>>((ref) async {
  return ref.watch(shopRepositoryProvider).getRealOfferings();
});

class ShopController extends StateNotifier<AsyncValue<UserWallet?>> {
  final ShopRepository _repository;

  ShopController(this._repository) : super(const AsyncLoading()) {
    loadWallet();
  }

  Future<void> loadWallet() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getMyWallet());
  }

  // 🔥 COMPRA CON DINERO REAL VÍA REVENUECAT
  Future<bool> buyRealGemsPack(Package package, int gemsReward) async {
    try {
      final updatedWallet = await _repository.buyGemsWithRealMoney(package, gemsReward);
      state = AsyncData(updatedWallet);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      loadWallet();
      return false;
    }
  }

  Future<bool> purchaseExtraSlots() async {
    try {
      final updatedWallet = await _repository.buyExtraSlots();
      state = AsyncData(updatedWallet);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      loadWallet();
      return false;
    }
  }

  Future<bool> purchaseVip() async {
    try {
      final updatedWallet = await _repository.buyVipStatus();
      state = AsyncData(updatedWallet);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      loadWallet();
      return false;
    }
  }
}

final shopControllerProvider = StateNotifierProvider.autoDispose<ShopController, AsyncValue<UserWallet?>>((ref) {
  return ShopController(ref.watch(shopRepositoryProvider));
});