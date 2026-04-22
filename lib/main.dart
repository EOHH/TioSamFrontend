import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importaciones de Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- Vigilante de background
import 'firebase_options.dart';

// 👇 Importación del Gigante de Pagos: RevenueCat
import 'package:purchases_flutter/purchases_flutter.dart';

// Importaciones de nuestra arquitectura core
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

// 👇 1. EL VIGILANTE NOCTURNO: Escucha notificaciones cuando la app está minimizada o cerrada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializamos Firebase para este hilo independiente
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Notificación recibida en background: ${message.messageId}");
}

Future<void> main() async {
  // Asegura que los bindings de Flutter estén listos antes de ejecutar código asíncrono
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // 2. INICIALIZAR FIREBASE (Paso Maestro para las notificaciones)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. REGISTRAR AL VIGILANTE NOCTURNO
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. Inicializar Supabase con las credenciales del .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 👇 5. INICIALIZAR REVENUECAT (EL MOTOR DE PAGOS)
  // Activamos el modo debug para ver en consola si la conexión a la tienda es exitosa
  await Purchases.setLogLevel(LogLevel.debug);

  // Public API Key de Android (goog_...)
  PurchasesConfiguration configuration = PurchasesConfiguration("goog_uWJFeYTFeTBwYySobsHHTdTuHEV");
  await Purchases.configure(configuration);

  // 6. Arrancar la app envuelta en ProviderScope para que Riverpod funcione
  runApp(
    const ProviderScope(
      child: AnimeTradeApp(),
    ),
  );
}

class AnimeTradeApp extends ConsumerWidget {
  const AnimeTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el router que ya tiene la lógica de redirección
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Anime Trade App',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}