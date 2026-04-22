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

  // --- 3. PROCESAR PAGO REAL DE GEMAS ---
  Future<UserWallet> buyGemsWithRealMoney(Package package, int gemsReward) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
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

  // --- 4. COMPRAR EXPANSIÓN (Gasto Interno de Gemas) ---
  Future<UserWallet> buyExtraSlots() async {
    final userId = _supabase.auth.currentUser!.id;
    const cost = 100;
    final currentWallet = await getMyWallet();
    if ((currentWallet?.gems ?? 0) < cost) throw Exception("💎 No tienes suficientes Gemas.");

    final response = await _supabase.from('user_wallets').update({'gems': currentWallet!.gems - cost}).eq('user_id', userId).select().single();
    final userRes = await _supabase.from('users').select('max_active_posts').eq('id', userId).single();

    // 🔥 CAMBIO: Fallback a 5 para usuarios nuevos
    final currentMax = userRes['max_active_posts'] as int? ?? 5;

    await _supabase.from('users').update({'max_active_posts': currentMax + 10}).eq('id', userId);
    return UserWallet.fromJson(response);
  }

  // --- 5. COMPRAR VIP (Gasto Interno de Gemas) ---
  Future<UserWallet> buyVipStatus() async {
    final userId = _supabase.auth.currentUser!.id;
    const cost = 300;
    final currentWallet = await getMyWallet();
    if ((currentWallet?.gems ?? 0) < cost) throw Exception("💎 No tienes suficientes Gemas.");

    final response = await _supabase.from('user_wallets').update({'gems': currentWallet!.gems - cost}).eq('user_id', userId).select().single();
    await _supabase.from('users').update({'is_vip': true, 'max_active_posts': 9999}).eq('id', userId);
    return UserWallet.fromJson(response);
  }

  // --- 6. DESTACAR PUBLICACIÓN (Gasto Interno de Gemas) ---
  Future<UserWallet> boostPost(String postId) async {
    final userId = _supabase.auth.currentUser!.id;
    const cost = 50;

    // 1. Verificamos si tiene saldo suficiente
    final currentWallet = await getMyWallet();
    if ((currentWallet?.gems ?? 0) < cost) {
      // Usamos nuestro formato de error secreto para que la UI lo detecte si quieres
      throw Exception("💎 No tienes suficientes Gemas para destacar esta carta.");
    }

    // 2. Cobramos las 50 gemas
    final response = await _supabase
        .from('user_wallets')
        .update({'gems': currentWallet!.gems - cost})
        .eq('user_id', userId)
        .select()
        .single();

    // 3. Encendemos el propulsor (is_boosted = true) en la carta elegida
    await _supabase
        .from('trades')
        .update({'is_boosted': true})
        .eq('id', postId);

    return UserWallet.fromJson(response);
  }
}