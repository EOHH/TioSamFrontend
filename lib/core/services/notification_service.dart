import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🔥 Motor de notificaciones locales
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // 📡 Canal VIP Android
  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'Notificaciones Importantes',
    description:
    'Este canal se usa para alertas urgentes como nuevas ofertas o mensajes.',
    importance: Importance.max,
  );

  Future<void> initNotifications() async {
    // 1. Permisos
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();

      if (token != null) {
        if (kDebugMode) print('Token de Firebase: $token');
        await _saveTokenToDatabase(token);
      }

      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken);
      });
    }

    // 2. Crear canal Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', user.id);
    }
  }

  // 👇 Setup navegación + notificaciones
  void setupInteractedMessage(Function(String routePath) onNavigate) async {
    // 1. App cerrada
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageData(initialMessage.data, onNavigate);
    }

    // 2. App en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageData(message.data, onNavigate);
    });

    // 3. Inicializar local notifications (FIX v21)
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final Map<String, dynamic> data =
          jsonDecode(response.payload!);
          _handleMessageData(data, onNavigate);
        }
      },
    );

    // 4. Foreground (push forzada)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        if (kDebugMode) {
          print(
              'Push forzada en Primer Plano: ${notification.title}');
        }

        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  // 🧠 Routing inteligente
  void _handleMessageData(
      Map<String, dynamic> data,
      Function(String routePath) onNavigate) {
    if (kDebugMode) {
      print('Notificación tocada. Datos procesados: $data');
    }

    final type = data['type'];

    if (type == 'new_offer') {
      final tradeId = data['trade_id'];
      if (tradeId != null) {
        onNavigate('/offer/$tradeId');
      }
    } else if (type == 'offer_accepted') {
      onNavigate('/trades');
    } else if (type == 'new_chat_message') {
      final offerId = data['offer_id'];
      final contactId = data['contact_id'] ?? '';
      final contactName =
          data['contact_name'] ?? 'Coleccionista';
      final contactAvatar = data['contact_avatar'] ??
          'https://ui-avatars.com/api/?name=C';

      if (offerId != null) {
        onNavigate(
          '/chat/$offerId?name=${Uri.encodeComponent(contactName)}'
              '&avatar=${Uri.encodeComponent(contactAvatar)}'
              '&contactId=$contactId',
        );
      }
    }
  }
}