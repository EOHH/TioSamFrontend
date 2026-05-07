import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// 👑 Proveedor Global: Devuelve TRUE si es VIP, FALSE si no lo es.
final isVipProvider = StateNotifierProvider<VipNotifier, bool>((ref) {
  return VipNotifier();
});

class VipNotifier extends StateNotifier<bool> {
  // ✅ AQUÍ ESTÁ LA LLAVE CORRECTA DE TU DASHBOARD
  final String _entitlementId = 'pro_status';

  VipNotifier() : super(false) {
    _initListener();
  }

  Future<void> _initListener() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateState(customerInfo);
    } catch (e) {
      if (kDebugMode) print("Error al obtener info de RevenueCat: $e");
    }

    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateState(customerInfo);
    });
  }

  void _updateState(CustomerInfo customerInfo) {
    // Busca en la billetera de Apple/Google si 'pro_status' está activo
    final isPremium = customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;

    if (state != isPremium) {
      state = isPremium;
      if (kDebugMode) print("👑 ESTADO VIP ACTUALIZADO GLOBALMENTE: $state");
    }
  }
}