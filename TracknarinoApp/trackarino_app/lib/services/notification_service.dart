import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Callback para manejar la acción cuando se toca una notificación
  Function(RemoteMessage)? onNotificationTap;

  // Inicializar el servicio
  Future<void> initialize() async {
    // Configurar Firebase Messaging
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar notificaciones locales
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@drawable/ic_notification');
    
    const DarwinInitializationSettings iOSSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationResponse(details);
      },
    );

    // Manejar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Manejar notificaciones en background que se tocan
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (onNotificationTap != null) {
        onNotificationTap!(message);
      }
    });
  }

  // Manejar mensajes recibidos en primer plano
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'trackarino_channel',
            'Tracknariño Notificaciones',
            channelDescription: 'Canal para notificaciones de Tracknariño',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@drawable/ic_notification',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // Manejar respuesta a notificaciones
  void _handleNotificationResponse(NotificationResponse details) {
    // Aquí podrías manejar la respuesta a una notificación local
    // Por ahora, no hacemos nada específico
  }

  // Obtener el token del dispositivo
  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Suscribirse a un tema
  Future<void> subscribeTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Cancelar suscripción a un tema
  Future<void> unsubscribeTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Mostrar una notificación local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required int id,
    String? payload,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'trackarino_channel',
          'Tracknariño Notificaciones',
          channelDescription: 'Canal para notificaciones de Tracknariño',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
} 