import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import '../domain/models/user_wallet.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(Supabase.instance.client);
});

class ShopRepository {
  final SupabaseClient _supabase;
  ShopRepository(this._supabase);

  // --- 1. OBTENER SALDO INTERNO ---
  Future<UserWallet?> getMyWallet() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await _supabase.from('user_wallets').select().eq('user_id', userId).maybeSingle();
    if (response == null) return null;
    return UserWallet.fromJson(response);
  }

  // --- 2. OBTENER PAQUETES DE TIENDA REALES (Google/Apple) ---
  Future<List<Package>> getRealOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
      return [];
    } on PlatformException catch (e) {
      throw Exception("Error conectando con la tienda: ${e.message}");
    }
  }

  // --- 3. PROCESAR PAGO REAL DE GEMAS (RevenueCat) ---
  // 💡 Nota Senior: Por ahora hacemos la recarga de gemas aquí en el cliente.
  // Para máxima seguridad en producción a gran escala, esto se debe hacer con "Webhooks"
  // de RevenueCat avisándole a Supabase de forma secreta en el backend.
  Future<UserWallet> buyGemsWithRealMoney(Package package, int gemsReward) async {
    try {
      await Purchases.purchasePackage(package); // RevenueCat valida con Google/Apple

      final userId = _supabase.auth.currentUser!.id;
      final currentWallet = await getMyWallet();
      final newBalance = (currentWallet?.gems ?? 0) + gemsReward;

      final response = await _supabase.from('user_wallets').update({'gems': newBalance}).eq('user_id', userId).select().single();
      return UserWallet.fromJson(response);

    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        throw Exception("Error en el pago: ${e.message}");
      } else {
        throw Exception("Pago cancelado por el usuario.");
      }
    }
  }

  // ======================================================================
  // 🔥 SEGURIDAD ATÓMICA (LÓGICA MOVIDA AL SERVIDOR CON RPC)
  // ======================================================================

  // --- 4. COMPRAR EXPANSIÓN (Gasto Interno) ---
  Future<UserWallet> buyExtraSlots() async {
    try {
      final response = await _supabase.rpc('buy_extra_slots');
      return UserWallet.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message); // El mensaje viene de la DB ("No tienes suficientes Gemas.")
    } catch (e) {
      throw Exception("Error de conexión al procesar la compra.");
    }
  }

  // --- 5. COMPRAR VIP (Gasto Interno) ---
  Future<UserWallet> buyVipStatus() async {
    try {
      final response = await _supabase.rpc('buy_vip_status');
      return UserWallet.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Error de conexión al activar VIP.");
    }
  }

  // --- 6. DESTACAR PUBLICACIÓN (Gasto Interno) ---
  Future<UserWallet> boostPost(String postId) async {
    try {
      final response = await _supabase.rpc('buy_boost_pack', params: {
        'p_post_id': postId
      });
      return UserWallet.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // 💡 Esta excepción será capturada por la UI para levantar el modal de Gemas Insuficientes
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Error de conexión al destacar la publicación.");
    }
  }
}