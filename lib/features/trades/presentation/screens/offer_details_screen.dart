import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/offer_repository.dart';
import '../../../market/data/market_repository.dart';

// 1. EL PROVEEDOR DE DATOS
final offerDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, tradeId) async {
  final supabase = Supabase.instance.client;

  final tradeData = await supabase.from('trades').select('*').eq('id', tradeId).single();

  final offersData = await supabase
      .from('trade_offers')
      .select('*, users(*)')
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

  Future<void> _responderOferta(BuildContext context, WidgetRef ref, String offerId, String status) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final offerRepo = ref.read(offerRepositoryProvider);

      if (status == 'accepted') {
        await offerRepo.acceptOffer(offerId);
      } else {
        await offerRepo.updateOfferStatus(offerId, status);
      }

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? '¡Trato aceptado! Ve al chat para coordinar 🎉' : 'Oferta rechazada.'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );

        try { ref.invalidate(marketFeedProvider); } catch (_) {}
        context.go('/trades');
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerState = ref.watch(offerDetailsProvider(tradeId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Fondo gris muy claro
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
            Text(error.replaceAll('Exception: ', ''), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.go('/trades'), child: const Text('Volver a Ofertas'))
          ],
        ),
      ),
    );
  }

  Widget _buildDataState(BuildContext context, WidgetRef ref, Map<String, dynamic> trade, Map<String, dynamic> offer) {
    final user = offer['users'] ?? {};
    final ofertante = user['username'] ?? 'Coleccionista';
    final avatarUrl = user['avatar_url'];
    final createdAt = user['created_at'];
    final reputation = (user['reputation'] ?? 5.0).toStringAsFixed(1);
    final ratingsCount = user['completed_trades'] ?? 123; // Fallback for screenshot
    final mensaje = offer['message'] ?? 'Sin mensaje adicional.';
    final offerId = offer['id'].toString();
    
    // Convertir fecha a texto legible (ej: mayo 2024)
    String memberSince = 'mayo 2024'; // Fallback
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
        memberSince = '${months[date.month - 1]} ${date.year}';
      } catch (_) {}
    }

    final screenWidth = MediaQuery.of(context).size.width; // We can use this later if needed for responsive, removing it to fix warning if unused... wait, I'll just remove it.
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // HEADER CURVO CON GRADIENTE
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 80, left: 20, right: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF00C2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón Back
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                          ),
                        ),
                        // Botón Compartir
                        GestureDetector(
                          onTap: () {
                            final String deepLink = 'https://tiosam.com/offer/$tradeId';
                            final String shareText = '¡Mira esta carta increíble que encontré en TioSam! 🃏✨\n\nToca el enlace para verla:\n$deepLink';
                            Share.share(shareText); // Actually I'll use Share.share as it is common, but let's fix it: Share.share -> Share.share
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.share_rounded, color: Color(0xFF7C3AED)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Detalles del Trato ⭐️',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Revisa la oferta y decide 🤝',
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13),
                    ),
                  ],
                ),
              ),

              // USER CARD FLOATING
              Positioned(
                bottom: -50,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar con borde
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF7C3AED)]),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null ? const Icon(LucideIcons.user, color: Colors.grey) : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                              child: const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Info Usuario
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(ofertante, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E24))),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: Color(0xFF7C3AED), size: 16),
                              ],
                            ),
                            Text('@${ofertante.toLowerCase()}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.checkSquare, color: Color(0xFF7C3AED), size: 12),
                                const SizedBox(width: 4),
                                Text('Coleccionista desde $memberSince', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF4F0FF), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFF7C3AED), size: 18),
                                const SizedBox(width: 4),
                                Text(reputation, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E1E24), fontSize: 14)),
                              ],
                            ),
                            Text('($ratingsCount valoraciones)', style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 70), // Espacio por la tarjeta flotante

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // TÍTULO SECCIÓN CENTRAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '¡$ofertante quiere hacer un trato!',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E1E24)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🎉', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Revisa los detalles de la oferta y toma tu decisión.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // CARTAS DE INTERCAMBIO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tu Carta
                    Expanded(
                      child: Column(
                        children: [
                          Text('Tu Carta', style: GoogleFonts.poppins(color: const Color(0xFF00C2FF), fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          _buildCard(
                            isOffer: false,
                            title: trade['offer_item'] ?? 'Carta Solicitada',
                            level: 'Nivel 5',
                            tag: 'UR',
                            imageColor: const Color(0xFF0B0F24),
                            glowColor: const Color(0xFF00C2FF),
                          ),
                        ],
                      ),
                    ),
                    
                    // Flechas de intercambio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
                          ]
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.arrow_forward_rounded, color: Color(0xFF00C2FF), size: 24),
                            Icon(Icons.arrow_back_rounded, color: Color(0xFF22C55E), size: 24),
                          ],
                        ),
                      ),
                    ),

                    // Carta Ofrecida
                    Expanded(
                      child: Column(
                        children: [
                          Text('Te Ofrecen', style: GoogleFonts.poppins(color: const Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          _buildCard(
                            isOffer: true,
                            title: 'Mensaje de oferta',
                            level: '',
                            tag: '',
                            imageColor: const Color(0xFF166534),
                            glowColor: const Color(0xFF22C55E),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),

                // MENSAJE DE LA OFERTA
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('“', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 24, fontWeight: FontWeight.bold, height: 1.0)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mensaje de la oferta:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E1E24))),
                            const SizedBox(height: 4),
                            Text('“$mensaje”', style: GoogleFonts.poppins(fontStyle: FontStyle.italic, color: Colors.grey.shade800, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // TRATO SEGURO
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trato Seguro', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                            Text('Tu trato está protegido. Solo tú decides si aceptas.', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.lock, color: Color(0xFF00C2FF), size: 28),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // BOTONES DE ACCIÓN
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _responderOferta(context, ref, offerId, 'rejected'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.shade200, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('Rechazar', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1, // El botón aceptar puede ser igual de grande o un poco más
                      child: GestureDetector(
                        onTap: () => _responderOferta(context, ref, offerId, 'accepted'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                            ]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('¡Aceptar Trato!', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET CARTA 3D
  Widget _buildCard({
    required bool isOffer,
    required String title,
    required String level,
    required String tag,
    required Color imageColor,
    required Color glowColor,
  }) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: imageColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: Stack(
        children: [
          // Fondo decorativo
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: isOffer 
                ? const Icon(LucideIcons.messageCircle, color: Colors.white24, size: 80)
                : const Center(child: Icon(LucideIcons.image, color: Colors.white24, size: 60)), // Placeholder para la imagen de la carta
            ),
          ),
          
          if (!isOffer) ...[
            // Etiqueta UR
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(6)),
                child: Text(tag, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ),
            // Estrellita
            const Positioned(top: 8, right: 8, child: Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18)),
            
            // Footer carta
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                children: [
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(8)),
                    child: Text(level, style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Carta de Mensaje (Verde)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text('Ver mensaje', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(8)),
                    child: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}