import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

// 👇 EL VIGILANTE NOCTURNO: Función "Zombie" para Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("📩 Push recibida en background: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // INICIALIZACIÓN SECUENCIAL SEGURA
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await Purchases.setLogLevel(LogLevel.debug);
  PurchasesConfiguration configuration = PurchasesConfiguration("goog_uWJFeYTFeTBwYySobsHHTdTuHEV");
  await Purchases.configure(configuration);

  runApp(const ProviderScope(child: AnimeTradeApp()));
}

class AnimeTradeApp extends ConsumerWidget {
  const AnimeTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TioSam Marketplace',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}