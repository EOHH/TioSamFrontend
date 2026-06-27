import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

// Providers
import '../../../../core/providers/revenuecat_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../shop/presentation/controllers/shop_controller.dart';
import '../controllers/my_posts_controller.dart';
import '../controllers/profile_controller.dart';

class BadgeDef {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  BadgeDef(this.title, this.subtitle, this.icon, this.color, this.isUnlocked);
}

class ActivityItem {
  final String title;
  final String subtitle;
  final String timeText;
  final IconData icon;
  final Color iconColor;
  final String? imageUrl;
  final DateTime date;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.icon,
    required this.iconColor,
    this.imageUrl,
    required this.date,
  });
}

String _timeAgo(DateTime d) {
  Duration diff = DateTime.now().difference(d);
  if (diff.inDays > 0) return 'Hace ${diff.inDays}d';
  if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
  if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}m';
  return 'Justo ahora';
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentProfileProvider);
    final authState = ref.watch(authControllerProvider);
    final collectionState = ref.watch(myCollectionProvider);
    final myPostsState = ref.watch(myHistoryFeedProvider);
    final walletState = ref.watch(shopControllerProvider);
    final isVip = ref.watch(isVipProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(currentProfileProvider);
          ref.refresh(myHistoryFeedProvider);
          ref.refresh(myCollectionProvider);
          ref.refresh(shopControllerProvider);
        },
        child: profileState.when(
          data: (user) {
            if (user == null) {
              return ListView(children: const [Center(child: Text('Usuario no encontrado'))]);
            }

            final cardsCount = collectionState.value?.length ?? 0;
            final level = (user.completedTrades ~/ 5) + 1;
            
            // --- BADGES ENGINE ---
            List<BadgeDef> badges = [
              BadgeDef('Principiante', 'Nivel 1', LucideIcons.refreshCw, const Color(0xFF7C4DFF), true),
              BadgeDef('Comerciante', '10 intercambios', Icons.handshake_rounded, const Color(0xFF00C2FF), user.completedTrades >= 10),
              BadgeDef('Experto', '50 intercambios', LucideIcons.crown, const Color(0xFFFFD700), user.completedTrades >= 50),
              BadgeDef('Coleccionista', '20 cartas únicas', LucideIcons.gem, const Color(0xFFFF4B8B), cardsCount >= 20),
              BadgeDef('Confiable', '5★ reputación', LucideIcons.shieldCheck, const Color(0xFF4CAF50), user.reputation >= 4.8),
            ];

            // --- ACTIVITY ENGINE ---
            List<ActivityItem> activities = [];
            
            // Add closed trades
            if (myPostsState.value != null) {
              final closedTrades = myPostsState.value!.where((t) => t['status'] == 'closed').toList();
              for (var trade in closedTrades) {
                final date = DateTime.tryParse(trade['created_at']) ?? DateTime.now();
                activities.add(ActivityItem(
                  title: 'Completaste un intercambio',
                  subtitle: '${trade['offer_item']} por ${trade['request_item'] ?? 'otra carta'}',
                  timeText: _timeAgo(date),
                  icon: LucideIcons.refreshCw,
                  iconColor: const Color(0xFF4CAF50),
                  imageUrl: trade['image_url'],
                  date: date,
                ));
              }
            }

            // Add collections
            if (collectionState.value != null) {
              for (var item in collectionState.value!) {
                activities.add(ActivityItem(
                  title: 'Añadiste a ${item.cardName} a tu colección',
                  subtitle: '¡Nueva carta desbloqueada! 🔥',
                  timeText: _timeAgo(item.createdAt),
                  icon: LucideIcons.plus,
                  iconColor: const Color(0xFF5E2BFF),
                  imageUrl: item.imageUrl,
                  date: item.createdAt,
                ));
              }
            }

            // REMOVED: Mock Review if reputation > 0
            
            activities.sort((a, b) => b.date.compareTo(a.date));

            // STATS calculations
            final totalTrades = myPostsState.value?.where((t) => t['status'] == 'closed').length ?? 0;
            final totalReceived = collectionState.value?.length ?? 0;
            final totalOffered = myPostsState.value?.length ?? 0;
            final currentGems = walletState.value?.gems ?? 0;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // --- HEADER GRADIENT ---
                      Container(
                        height: 250,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5E2BFF), Color(0xFF00C2FF)],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                    Row(
                                      children: [
                                        walletState.when(
                                          data: (wallet) => GestureDetector(
                                            onTap: () => context.push('/shop'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.3))),
                                              child: Row(
                                                children: [
                                                  const Icon(LucideIcons.gem, color: Colors.white, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text((wallet?.gems ?? 0).toString(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                  const SizedBox(width: 8),
                                                  Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(LucideIcons.plus, color: Color(0xFF5E2BFF), size: 10))
                                                ],
                                              ),
                                            ),
                                          ),
                                          loading: () => const SizedBox(), error: (_, __) => const SizedBox(),
                                        ),
                                        const SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () => _showSettingsMenu(context, ref),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                            child: const Icon(LucideIcons.settings, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Colecciona, intercambia y diviértete 🎉', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // --- WHITE CARD OVERLAP ---
                      Container(
                        margin: const EdgeInsets.only(top: 150),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Column(
                          children: [
                            // 1. Perfil Info Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(colors: isVip ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)] : [const Color(0xFF00C2FF), const Color(0xFF5E2BFF)]),
                                        ),
                                        child: CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.white,
                                          backgroundImage: CachedNetworkImageProvider(user.avatarUrl),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -5, right: -5,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: const Color(0xFFFFD700), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]),
                                          child: Text(level.toString(), style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Info Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(child: Text(user.username, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: 6),
                                            const Icon(LucideIcons.badgeCheck, color: Color(0xFF5E2BFF), size: 18),
                                          ],
                                        ),
                                        Text('@${user.username.toLowerCase()}', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                                        const SizedBox(height: 6),
                                        Row(children: [const Icon(LucideIcons.mail, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(user.email, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11))]),
                                        const SizedBox(height: 2),
                                        Row(children: [const Icon(LucideIcons.mapPin, size: 12, color: Colors.grey), const SizedBox(width: 4), Text('Global', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11))]),
                                        const SizedBox(height: 2),
                                        Row(children: [const Icon(LucideIcons.calendar, size: 12, color: Colors.grey), const SizedBox(width: 4), Text('Se unió recientemente', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11))]),
                                      ],
                                    ),
                                  ),

                                  // Edit Button
                                  OutlinedButton.icon(
                                    onPressed: () => context.push('/edit-profile', extra: user),
                                    icon: const Icon(LucideIcons.pencil, size: 12, color: Color(0xFF5E2BFF)),
                                    label: Text('Editar', style: GoogleFonts.poppins(color: const Color(0xFF5E2BFF), fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      side: const BorderSide(color: Color(0xFF5E2BFF)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. Stats Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatBox(context, user.completedTrades.toString(), 'Tratos', 'realizados', Icons.handshake_rounded, const Color(0xFF00C2FF)),
                                  _buildStatBox(context, cardsCount.toString(), 'Cartas', 'en colección', LucideIcons.layers, const Color(0xFF7C4DFF)),
                                  _buildStatBox(context, user.reputation.toStringAsFixed(1), 'Reputación', 'valoraciones', LucideIcons.star, const Color(0xFFFFD700)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 3. Mis Insignias
                            _buildSectionTitle('Mis Insignias', 'Ver todas >'),
                            SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: badges.length,
                                itemBuilder: (context, index) {
                                  final b = badges[index];
                                  return _buildBadgeHexagon(b.title, b.subtitle, b.icon, b.color, b.isUnlocked);
                                },
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 4. Actividad Reciente
                            _buildSectionTitle('Actividad Reciente', 'Ver todas >'),
                            if (activities.isEmpty)
                               Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text('No hay actividad reciente.', style: GoogleFonts.poppins(color: Colors.grey)),
                              )
                            else
                               ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: activities.take(3).length, // Muestra max 3
                                itemBuilder: (context, index) {
                                  final act = activities[index];
                                  return _buildActivityTile(context, act);
                                },
                              ),

                            const SizedBox(height: 32),

                            // 5. Estadísticas Mensuales Grid
                            _buildSectionTitle('Estadísticas', 'Este mes ˅'),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMiniStat(totalTrades.toString(), 'Intercambios', LucideIcons.refreshCw, const Color(0xFF7C4DFF)),
                                    _buildMiniStat(totalReceived.toString(), 'Cartas obtenidas', LucideIcons.arrowUpRight, const Color(0xFF4CAF50)),
                                    _buildMiniStat(totalOffered.toString(), 'Cartas ofrecidas', LucideIcons.arrowDownRight, const Color(0xFFFF4B8B)),
                                    _buildMiniStat(currentGems.toString(), 'Gemas actuales', LucideIcons.gem, const Color(0xFF00C2FF)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
              title: Text('Cerrar Sesión', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text(action, style: GoogleFonts.poppins(color: const Color(0xFF5E2BFF), fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String value, String title, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeHexagon(String title, String subtitle, IconData icon, Color color, bool unlocked) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle, // Simplified hexagon shape to circle for Flutter standard container
              color: unlocked ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
              border: Border.all(color: unlocked ? color : Colors.grey.withOpacity(0.3), width: 2),
              boxShadow: unlocked ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : [],
            ),
            child: Icon(unlocked ? icon : LucideIcons.lock, color: unlocked ? color : Colors.grey, size: 24),
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: unlocked ? null : Colors.grey), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, ActivityItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: item.iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: item.title),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.timeText, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 6),
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(imageUrl: item.imageUrl!, width: 28, height: 40, fit: BoxFit.cover),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}