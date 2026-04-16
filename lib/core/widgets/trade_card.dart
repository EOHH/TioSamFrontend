import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/trades/domain/models/trade_post.dart';

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
    else if ((difference.inDays / 7).floor() >= 1) return 'Hace 1 semana';
    else if (difference.inDays >= 2) return 'Hace ${difference.inDays} días';
    else if (difference.inDays >= 1) return 'Hace 1 día';
    else if (difference.inHours >= 2) return 'Hace ${difference.inHours} horas';
    else if (difference.inHours >= 1) return 'Hace 1 hora';
    else if (difference.inMinutes >= 2) return 'Hace ${difference.inMinutes} minutos';
    else if (difference.inMinutes >= 1) return 'Hace 1 minuto';
    else return 'Justo ahora';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surface,
      elevation: isDark ? 2 : 6, // Sombra más pronunciada en modo claro
      shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Esquinas más redondas
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABECERA DE USUARIO ---
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: CachedNetworkImageProvider(post.userAvatar),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3)),
                      Text(
                        _getTimeAgo(post.createdAt),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (trailingWidget != null) trailingWidget!,
              ],
            ),
            const SizedBox(height: 20),

            // --- SECCIÓN DE CARTAS (EL REDISEÑO) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Carta 1 (Ofrece)
                Expanded(child: _buildModernItemBox(context, post.offerItemName, post.offerItemImage, isOffer: true)),

                // Flecha central moderna
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: isDark ? Colors.grey : Colors.grey,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                    ),
                    child: Icon(LucideIcons.arrowRightLeft, color: isDark ? Colors.white70 : Colors.black87, size: 20),
                  ),
                ),

                // Carta 2 (Busca)
                Expanded(child: _buildModernItemBox(context, post.requestItemName, null, isOffer: false)),
              ],
            ),

            // --- BOTÓN DE ACCIÓN ---
            if (showOfferButton) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onTradeTap,
                  icon: const Icon(LucideIcons.zap, size: 20, color: Colors.white),
                  label: const Text('Proponer Intercambio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Color vibrante
                    elevation: 4,
                    shadowColor: Colors.blueAccent.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // 🔥 EL NUEVO COMPONENTE VISUAL DE LA CARTA
  Widget _buildModernItemBox(BuildContext context, String title, String? imageUrl, {required bool isOffer}) {
    final color = isOffer ? Colors.cyan : Colors.purpleAccent;

    return Column(
      children: [
        // Etiqueta superior (Badge)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            isOffer ? 'OFRECE' : 'BUSCA',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: color),
          ),
        ),
        const SizedBox(height: 12),

        // Contenedor de la imagen/texto
        Container(
          height: 160, // Altura fija para que ambas cartas midan igual
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14), // Un poco menos que el borde exterior
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. La Imagen de fondo (si existe)
                if (imageUrl != null && imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (context, url, error) => const Icon(LucideIcons.imageOff, color: Colors.grey),
                  )
                else
                // Si no hay imagen, mostramos un ícono tenue de fondo
                  Center(child: Icon(isOffer ? LucideIcons.gift : LucideIcons.search, size: 40, color: color.withOpacity(0.2))),

                // 2. 🔥 LA MAGIA: El Gradiente oscuro en la parte inferior
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.8),
                          Colors.black, // Completamente negro abajo
                        ],
                        stops: const [0.4, 0.6, 0.8, 1.0], // Ajusta dónde empieza a oscurecerse
                      ),
                    ),
                  ),

                // 3. El Texto (Siempre blanco y encima de todo)
                Align(
                  alignment: imageUrl != null && imageUrl.isNotEmpty ? Alignment.bottomCenter : Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        // Si hay imagen, forzamos blanco por el gradiente. Si no, usamos el color del tema.
                        color: (imageUrl != null && imageUrl.isNotEmpty) ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
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
}