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

  // 👇 AHORA RECIBE UNA RUTA COMPLETA EN LUGAR DE SOLO EL ID
  void setupInteractedMessage(Function(String routePath) onNavigate) async {
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

  // 👇 LÓGICA DE ENRUTAMIENTO DINÁMICO
  void _handleMessage(RemoteMessage message, Function(String routePath) onNavigate) {
    if (kDebugMode) print('Notificación tocada. Datos ocultos: ${message.data}');

    final type = message.data['type'];

    // 1. Nueva Oferta -> Vamos a los detalles de la oferta
    if (type == 'new_offer') {
      final tradeId = message.data['trade_id'];
      if (tradeId != null) {
        onNavigate('/offer/$tradeId');
      }
    }
    // 2. Oferta Aceptada -> Vamos a la pantalla de intercambios
    else if (type == 'offer_accepted') {
      onNavigate('/trades');
    }
    // 3. NUEVO: Mensaje de Chat -> Vamos directo a ese chat
    // Navegación directa al Chat con datos reales
    else if (type == 'new_chat_message') {
      final offerId = message.data['offer_id'];

      // Extraemos la información real que mandó la Edge Function
      final contactId = message.data['contact_id'] ?? '';
      final contactName = message.data['contact_name'] ?? 'Coleccionista';
      final contactAvatar = message.data['contact_avatar'] ?? 'https://ui-avatars.com/api/?name=C';

      if (offerId != null) {
        // Formateamos la URL dinámicamente con los datos reales
        onNavigate('/chat/$offerId?name=${Uri.encodeComponent(contactName)}&avatar=${Uri.encodeComponent(contactAvatar)}&contactId=$contactId');
      }
    }
  }
}