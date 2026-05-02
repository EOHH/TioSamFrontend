import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/trades/domain/models/trade_post.dart';
import '../utils/image_cache_manager.dart';

class TradeCard extends StatelessWidget {
  final TradePost post;
  final VoidCallback? onTradeTap;
  final bool showOfferButton;
  final Widget? trailingWidget;

  const TradeCard({
    super.key,
    required this.post,
    this.onTradeTap,
    this.showOfferButton = true,
    this.trailingWidget,
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 8) return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    if (difference.inDays >= 1) return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    if (difference.inHours >= 1) return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    if (difference.inMinutes >= 1) return 'Hace ${difference.inMinutes} min';
    return 'Justo ahora';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isBoosted = post.isBoosted;
    final bool isVip = post.isVip;

    // Paleta de colores Premium
    final Color goldColor = isDark ? const Color(0xFFFFD700) : const Color(0xFFD4AF37);
    final Color boostColor = Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // ✨ Aura exterior solo para destacados (Efecto Resplandor)
        boxShadow: [
          if (isBoosted)
            BoxShadow(
              color: boostColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            // ✨ Borde inteligente: Dorado para VIP, Naranja fuego para Boosted
            border: Border.all(
              color: isBoosted
                  ? boostColor
                  : (isVip ? goldColor.withOpacity(0.6) : Colors.grey.withOpacity(0.1)),
              width: (isBoosted || isVip) ? 2.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // 🚀 Banner de Publicación Destacada (Solo si es Boosted)
              if (isBoosted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [boostColor, Colors.deepOrange.shade400],
                    ),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.rocket, color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'DESTACADO POR EL COLECCIONISTA',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- HEADER ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isVip
                                ? LinearGradient(colors: [goldColor, Colors.white, goldColor])
                                : null,
                            color: !isVip ? Colors.blueAccent.withOpacity(0.3) : null,
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: CachedNetworkImageProvider(
                              post.userAvatar,
                              maxHeight: 150, // <-- CRÍTICO
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      post.username,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                        color: isVip ? goldColor : null,
                                      ),
                                    ),
                                  ),
                                  if (isVip) ...[
                                    const SizedBox(width: 6),
                                    Icon(LucideIcons.crown, color: goldColor, size: 18),
                                  ],
                                ],
                              ),
                              Text(_getTimeAgo(post.createdAt), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (trailingWidget != null) trailingWidget!,
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- CARDS VIEW ---
                    Row(
                      children: [
                        Expanded(child: _buildItemNode(context, post.offerItemName, post.offerItemImage, true)),
                        _buildExchangeDivider(isDark),
                        Expanded(child: _buildItemNode(context, post.requestItemName, null, false)),
                      ],
                    ),

                    // --- ACTION BUTTON ---
                    if (showOfferButton) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: onTradeTap,
                          icon: const Icon(LucideIcons.zap, color: Colors.white),
                          label: const Text(
                            'PROPONER TRATO',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemNode(BuildContext context, String name, String? img, bool isOffer) {
    final color = isOffer ? Colors.cyan.shade400 : Colors.purpleAccent.shade100;

    return Column(
      children: [
        Text(
          isOffer ? 'OFRECE' : 'BUSCA',
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.grey.withOpacity(0.05),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (img != null && img.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: img,
                    fit: BoxFit.cover,
                    cacheManager: TioSamCacheManager.instance, // Usamos nuestro manager estricto
                    memCacheHeight: 400, // <-- CRÍTICO: La imagen no se decodificará a más de 400px en RAM
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => const Icon(LucideIcons.imageOff, color: Colors.grey),
                  )
                else
                  Center(child: Icon(isOffer ? LucideIcons.gift : LucideIcons.search, size: 40, color: color.withOpacity(0.2))),

                // Overlay de texto con gradiente cinemático
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(LucideIcons.repeat, size: 18, color: isDark ? Colors.white60 : Colors.black45),
      ),
    );
  }
}