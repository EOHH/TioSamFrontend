import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; 
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/trades/domain/models/trade_post.dart';
import '../utils/image_cache_manager.dart';

class TradeCard extends HookWidget {
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

  bool _isRareItem(String name) {
    final lower = name.toLowerCase();
    return lower.contains('(lr)') || 
           lower.contains('(legendary)') || 
           lower.contains('(ur)') || 
           lower.contains('(ssr)');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isBoosted = post.isBoosted;
    final bool isVip = post.isVip;
    final bool isRare = _isRareItem(post.offerItemName);

    final Color goldColor = isDark ? const Color(0xFFFFD700) : const Color(0xFFFFD93D);
    final Color boostColor = Colors.orangeAccent;

    // Controlador de micro-animación (rebote)
    final animationController = useAnimationController(duration: const Duration(milliseconds: 100));
    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    return GestureDetector(
      onTapDown: (_) => animationController.forward(),
      onTapUp: (_) => animationController.reverse(),
      onTapCancel: () => animationController.reverse(),
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                  if (isBoosted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [boostColor, Colors.deepOrange.shade400],
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.rocket, color: Colors.white, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'DESTACADO POR EL COLECCIONISTA',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
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
                                gradient: isVip || isRare
                                    ? LinearGradient(colors: [goldColor, Colors.white, goldColor])
                                    : null,
                                color: !(isVip || isRare) ? const Color(0xFF7C4DFF).withOpacity(0.1) : null,
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white,
                                backgroundImage: CachedNetworkImageProvider(
                                  post.userAvatar,
                                  maxHeight: 150,
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
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                            color: isVip ? goldColor : (isDark ? Colors.white : Colors.black87),
                                          ),
                                        ),
                                      ),
                                      if (isVip) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C4DFF).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.checkCircle2, color: Color(0xFF7C4DFF), size: 12),
                                              const SizedBox(width: 4),
                                              Text('Verificado', style: GoogleFonts.poppins(color: const Color(0xFF7C4DFF), fontSize: 10, fontWeight: FontWeight.bold)),
                                            ],
                                          )
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(_getTimeAgo(post.createdAt), style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            if (trailingWidget != null) trailingWidget!,
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- CARDS VIEW 3D ---
                        Row(
                          children: [
                            Expanded(child: HolographicItemNode(name: post.offerItemName, img: post.offerItemImage, isOffer: true, isRare: isRare)),
                            _buildExchangeDivider(isDark),
                            Expanded(child: HolographicItemNode(name: post.requestItemName, img: null, isOffer: false, isRare: false)),
                          ],
                        ),

                        // --- FOOTER: TIMER & ACTION BUTTON ---
                        if (showOfferButton) ...[
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Timer
                              Row(
                                children: [
                                  const Icon(LucideIcons.timer, color: Color(0xFF7C4DFF), size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '23h 45m',
                                    style: GoogleFonts.poppins(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'restantes',
                                    style: GoogleFonts.poppins(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ],
                              ),
                              
                              // Button
                              GestureDetector(
                                onTap: onTradeTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00C2FF), Color(0xFF7C4DFF)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C4DFF).withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Ver detalles',
                                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(LucideIcons.arrowRight, color: Colors.white, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildExchangeDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ]
        ),
        child: Icon(LucideIcons.repeat, size: 20, color: isDark ? Colors.white60 : Colors.black54),
      ),
    );
  }
}

// ---------------------------------------------------------
// NUEVO WIDGET: CARTA HOLOGRÁFICA 3D
// ---------------------------------------------------------
class HolographicItemNode extends HookWidget {
  final String name;
  final String? img;
  final bool isOffer;
  final bool isRare;
  final String? topLabel;

  const HolographicItemNode({
    super.key,
    required this.name,
    this.img,
    required this.isOffer,
    this.isRare = false,
    this.topLabel,
  });

  bool _isLegendary(String itemName) {
    return itemName.toLowerCase().contains('(legendary)') || itemName.toLowerCase().contains('(leg)');
  }

  bool _isLR(String itemName) {
    return itemName.toLowerCase().contains('(lr)');
  }

  @override
  Widget build(BuildContext context) {
    final color = isOffer ? const Color(0xFF2EC4B6) : const Color(0xFF9D4EDD);
    
    final bool isLeg = _isLegendary(name);
    final bool isLR = _isLR(name);
    final Color rareColor = isLR ? const Color(0xFFFFD93D) : (isLeg ? const Color(0xFFA200FF) : color);

    // Controladores de rotación y brillo
    final rx = useState(0.0);
    final ry = useState(0.0);
    final glareX = useState(0.5);
    final glareY = useState(0.5);

    return Column(
      children: [
        Text(
          topLabel ?? (isOffer ? 'OFRECE' : 'BUSCA'),
          style: GoogleFonts.poppins(color: isOffer ? const Color(0xFF2EC4B6) : const Color(0xFF7C4DFF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);

            final percentageX = (localPosition.dx / box.size.width) - 0.5;
            final percentageY = (localPosition.dy / box.size.height) - 0.5;

            ry.value = percentageX * 0.4;
            rx.value = -percentageY * 0.4;

            glareX.value = percentageX + 0.5;
            glareY.value = percentageY + 0.5;
          },
          onPanEnd: (_) {
            rx.value = 0.0;
            ry.value = 0.0;
            glareX.value = 0.5;
            glareY.value = 0.5;
          },
          onPanCancel: () {
            rx.value = 0.0;
            ry.value = 0.0;
          },
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 150),
            builder: (context, val, child) {
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Perspectiva 3D
                ..rotateX(rx.value)
                ..rotateY(ry.value);

              return Transform(
                alignment: Alignment.center,
                transform: transform,
                child: child,
              );
            },
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.grey.withOpacity(0.05),
                border: Border.all(color: isRare ? rareColor : color.withOpacity(0.5), width: isRare ? 2.5 : 1.5),
                boxShadow: (rx.value != 0 || ry.value != 0) || isRare
                    ? [
                  BoxShadow(
                    color: (isRare ? rareColor : color).withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(-ry.value * 30, -rx.value * 30),
                  )
                ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Imagen base
                    if (img != null && img!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: img!,
                        fit: BoxFit.cover,
                        cacheManager: TioSamCacheManager.instance,
                        memCacheHeight: 400,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) => const Icon(LucideIcons.imageOff, color: Colors.grey),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color.withOpacity(0.2), color.withOpacity(0.8)],
                          )
                        ),
                        child: Center(
                          child: Icon(isOffer ? LucideIcons.gift : LucideIcons.search, size: 48, color: Colors.white.withOpacity(0.6)),
                        ),
                      ),

                    // 2. Gradiente inferior negro para el texto
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.9)],
                          ),
                        ),
                      ),
                    ),

                    // 3. Brillo Holográfico Dinámico (Glare)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment((glareX.value - 0.5) * 3, (glareY.value - 0.5) * 3),
                          radius: 1.5,
                          colors: [
                            Colors.white.withOpacity(rx.value != 0 ? 0.4 : (isRare ? 0.15 : 0.0)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // 4. Badges (Top Left LR/LEG y Top Right Estrella)
                    if (isRare) ...[
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: rareColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: rareColor, width: 1.5),
                          ),
                          child: Text(
                            isLR ? 'LR' : 'LEG',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: rareColor)),
                          child: Icon(LucideIcons.star, color: rareColor, size: 14),
                        ),
                      ),
                    ],

                    // 5. Texto
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}