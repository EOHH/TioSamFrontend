import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../services/analytics_service.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
// 🔥 IMPORTAMOS TU ONBOARDING
import '../../features/auth/presentation/screens/onboarding_screen.dart';

import '../../features/collection/domain/models/collection_item.dart';
import '../../features/collection/presentation/screens/collection_detail_screen.dart';
import '../../features/collection/presentation/screens/collection_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/trades/presentation/screens/offer_details_screen.dart';
import '../../features/market/presentation/screens/market_screen.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/trades/presentation/screens/trades_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../widgets/main_layout.dart';

// 👇 IMPORTA TU SPLASH
import '../widgets/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final authSubscriptionProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authSubscriptionProvider);
  final analytics = ref.watch(analyticsServiceProvider).analytics;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    observers: [
      FirebaseAnalyticsObserver(analytics: analytics),
    ],

    redirect: (context, state) {
      final session = ref.read(authRepositoryProvider).currentSession;

      // 🔥 AÑADIMOS EL ONBOARDING A LAS RUTAS "PÚBLICAS"
      final isAuthRoute =
          state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/onboarding';

      final isSplash = state.matchedLocation == '/';

      if (isSplash) return null;

      if (session == null) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute) return '/market';

      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // 🔥 DECLARAMOS LA RUTA DEL ONBOARDING
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()
      ),

      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      GoRoute(
        path: '/chat/:offerId',
        builder: (context, state) {
          final offerId = state.pathParameters['offerId']!;
          final contactName = state.uri.queryParameters['name'] ?? 'Coleccionista';
          final contactAvatar = state.uri.queryParameters['avatar'] ?? 'https://ui-avatars.com/api/?name=C';
          final contactId = state.uri.queryParameters['contactId'] ?? '';

          return ChatScreen(
            offerId: offerId,
            contactName: contactName,
            contactAvatar: contactAvatar,
            contactId: contactId,
          );
        },
      ),

      GoRoute(
        path: '/collection-detail',
        builder: (context, state) {
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
          final tradeId = state.pathParameters['id']!;
          return OfferDetailsScreen(tradeId: tradeId);
        },
      ),

      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // 👇 MAIN APP
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/market', builder: (context, state) => const MarketScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/trades', builder: (context, state) => const TradesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/shop', builder: (context, state) => const ShopScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/collection', builder: (context, state) => const CollectionScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});