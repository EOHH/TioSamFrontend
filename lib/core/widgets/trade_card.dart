import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/trades/domain/models/trade_post.dart';

class TradeCard extends StatelessWidget {
  final TradePost post;
  final VoidCallback? onTradeTap; // Ahora es opcional
  final bool showOfferButton; // Nueva variable para controlar la visibilidad del botón

  const TradeCard({
    super.key,
    required this.post,
    this.onTradeTap,
    this.showOfferButton = true, // Por defecto siempre se muestra
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 8) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if ((difference.inDays / 7).floor() >= 1) {
      return 'Hace 1 semana';
    } else if (difference.inDays >= 2) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays >= 1) {
      return 'Hace 1 día';
    } else if (difference.inHours >= 2) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inHours >= 1) {
      return 'Hace 1 hora';
    } else if (difference.inMinutes >= 2) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inMinutes >= 1) {
      return 'Hace 1 minuto';
    } else {
      return 'Justo ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Usuario y Tiempo
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: CachedNetworkImageProvider(post.userAvatar),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                          _getTimeAgo(post.createdAt),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.moreHorizontal),
                  color: Colors.grey,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Cuerpo: El Intercambio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildItemBox(context, post.offerItemName, post.offerItemImage, isOffer: true),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.arrowRightLeft, color: Theme.of(context).primaryColor, size: 24),
                ),
                _buildItemBox(context, post.requestItemName, null, isOffer: false),
              ],
            ),

            // Botón de Acción (Se oculta completamente si showOfferButton es false)
            if (showOfferButton) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: onTradeTap,
                  icon: const Icon(LucideIcons.zap, size: 18),
                  label: const Text('Proponer Intercambio', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildItemBox(BuildContext context, String title, String? imageUrl, {required bool isOffer}) {
    return Column(
      children: [
        Text(
          isOffer ? 'OFRECE' : 'BUSCA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isOffer ? Theme.of(context).colorScheme.secondary : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 110,
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOffer ? Theme.of(context).colorScheme.secondary.withOpacity(0.3) : Theme.of(context).primaryColor.withOpacity(0.3),
            ),
            image: imageUrl != null && imageUrl.isNotEmpty
                ? DecorationImage(
                image: CachedNetworkImageProvider(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken)
            )
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}