import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  // Patrón Singleton para usar la misma instancia en toda la app
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> initNotifications() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) {
        if (kDebugMode) print('Token de Firebase: $token');
        await _saveTokenToDatabase(token);
      }
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('users').update({'fcm_token': token}).eq('id', user.id);
    }
  }

  // 👇 ¡NUEVO! Escuchamos los toques en las notificaciones
  void setupInteractedMessage(Function(String tradeId) onNavigate) async {
    // 1. Si la app estaba CERRADA por completo y se abrió desde la notificación
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, onNavigate);
    }

    // 2. Si la app estaba MINIMIZADA y el usuario tocó la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message, onNavigate);
    });
  }

  // Lógica interna para leer el "mapa secreto"
  void _handleMessage(RemoteMessage message, Function(String tradeId) onNavigate) {
    if (kDebugMode) print('Notificación tocada. Datos ocultos: ${message.data}');

    // Verificamos si es una notificación de nueva oferta
    if (message.data['type'] == 'new_offer') {
      final tradeId = message.data['trade_id'];
      if (tradeId != null) {
        // Ejecutamos la navegación hacia la pantalla de esa oferta
        onNavigate(tradeId);
      }
    }
  }
}