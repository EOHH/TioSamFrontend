import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

// Importamos el controlador del Home (ruta relativa dentro del mismo feature)
import '../controllers/home_feed_controller.dart';
// Importamos la pantalla de Trades para acceder a sus providers (cruzando features)
import '../../../trades/presentation/screens/trades_screen.dart';

// 1. EL PROVEEDOR DE DATOS
final offerDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, tradeId) async {
  final supabase = Supabase.instance.client;

  final tradeData = await supabase.from('trades').select('*').eq('id', tradeId).single();

  final offersData = await supabase
      .from('trade_offers')
      .select('*, users(username, avatar_url)')
      .eq('post_id', tradeId)
      .eq('status', 'pending')
      .limit(1)
      .maybeSingle();

  if (offersData == null) {
    throw Exception("La oferta ya no está disponible o fue cancelada.");
  }

  return {'trade': tradeData, 'offer': offersData};
});

// 2. LA PANTALLA
class OfferDetailsScreen extends ConsumerWidget {
  final String tradeId;

  const OfferDetailsScreen({super.key, required this.tradeId});

  // 👇 LA LÓGICA DE NEGOCIO CERRANDO EL CICLO
  Future<void> _responderOferta(BuildContext context, WidgetRef ref, String offerId, String status) async {
    try {
      // 1. Modal de carga
      showDialog(
        context: context, barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final supabase = Supabase.instance.client;

      // 2. Actualizamos el estado de la oferta seleccionada
      await supabase.from('trade_offers').update({'status': status}).eq('id', offerId);

      // 3. Lógica de negocio si el trato es ACEPTADO
      if (status == 'accepted') {
        // Marcamos la publicación original como completada
        await supabase.from('trades').update({'status': 'completed'}).eq('id', tradeId);

        // Rechazamos automáticamente a los demás postulantes para esa carta
        await supabase.from('trade_offers')
            .update({'status': 'rejected'})
            .eq('post_id', tradeId)
            .neq('id', offerId);
      }

      // 4. Quitamos el loading
      if (context.mounted) Navigator.pop(context);

      // 5. Refrescamos caché y Redirigimos
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? '¡Trato cerrado con éxito! 🎉' : 'Oferta rechazada.'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );

        // 🔥 Refrescamos el Feed Principal
        ref.invalidate(homeFeedProvider);

        // 🔥 Refrescamos la lista de intercambios recibidos
        ref.invalidate(receivedOffersProvider);

        // 🔥 REDIRECCIÓN a tu StatefulShellRoute de intercambios
        context.go('/trades');
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Quitamos loading si hay error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerState = ref.watch(offerDetailsProvider(tradeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Trato', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: offerState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
        data: (data) => _buildDataState(context, ref, data['trade'], data['offer']),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            // Regresamos seguros al Home definido en tu app_router.dart
            ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Volver al inicio'))
          ],
        ),
      ),
    );
  }

  Widget _buildDataState(BuildContext context, WidgetRef ref, Map<String, dynamic> trade, Map<String, dynamic> offer) {
    final ofertante = offer['users']?['username'] ?? 'Un coleccionista';
    final mensaje = offer['message'] ?? 'Sin mensaje adicional.';
    final offerId = offer['id'].toString();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(LucideIcons.arrowRightLeft, size: 48, color: Colors.purpleAccent),
                  const SizedBox(height: 16),
                  Text('¡$ofertante quiere hacer un trato!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildItemColumn('Tu Carta', trade['offer_item'] ?? 'Desconocida', Colors.blueGrey),
                      const Icon(LucideIcons.arrowRight, color: Colors.grey),
                      _buildItemColumn('Te Ofrecen', 'Ver Mensaje', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Mensaje de la oferta:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2))
            ),
            child: Text('"$mensaje"', style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _responderOferta(context, ref, offerId, 'rejected'),
                  icon: const Icon(LucideIcons.x, color: Colors.red),
                  label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _responderOferta(context, ref, offerId, 'accepted'),
                  icon: const Icon(LucideIcons.check),
                  label: const Text('¡Aceptar Trato!'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItemColumn(String title, String itemName, Color badgeColor) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeColor.withOpacity(0.5))),
          child: Text(itemName, style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor)),
        ),
      ],
    );
  }
}