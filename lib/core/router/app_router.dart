import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/collection/domain/models/collection_item.dart';
import '../../features/collection/presentation/screens/collection_detail_screen.dart';
import '../../features/collection/presentation/screens/collection_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/offer_details_screen.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/trades/presentation/screens/trades_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart'; // IMPORTANTE
import '../widgets/main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final authSubscriptionProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authSubscriptionProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final session = ref.read(authRepositoryProvider).currentSession;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (session == null) return isAuthRoute ? null : '/login';
      if (isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      // RUTA DEL CHAT (Fuera del BottomNav porque ocupa pantalla completa)
      GoRoute(
        path: '/chat/:offerId',
        builder: (context, state) {
          final offerId = state.pathParameters['offerId']!;
          // Extraemos los datos de la URL (query parameters)
          final contactName = state.uri.queryParameters['name'] ?? 'Coleccionista';
          final contactAvatar = state.uri.queryParameters['avatar'] ?? 'https://ui-avatars.com/api/?name=C';

          return ChatScreen(
            offerId: offerId,
            contactName: contactName,
            contactAvatar: contactAvatar,
          );
        },
      ),
      GoRoute(
        path: '/collection-detail',
        builder: (context, state) {
          // Extraemos el objeto completo que le pasaremos desde la cuadrícula
          final item = state.extra as CollectionItem;
          return CollectionDetailScreen(item: item);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) {
          final profile = state.extra as UserProfile;
          return EditProfileScreen(currentProfile: profile);
        },
      ),
      GoRoute(
        path: '/offer/:id',
        builder: (context, state) {
          // Extraemos el ID que viene oculto en la URL
          final tradeId = state.pathParameters['id']!;
          return OfferDetailsScreen(tradeId: tradeId);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/trades', builder: (context, state) => const TradesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/shop', builder: (context, state) => const ShopScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/collection', builder: (context, state) => const CollectionScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});