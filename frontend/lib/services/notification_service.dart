import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  static Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;
  
  // Initialize notifications
  static Future<void> initialize() async {
    // Request permission for iOS
    if (!kIsWeb) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
    
    // Configure local notifications
    const androidInitSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iOSInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iOSInitSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
    
    // Configure FCM
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Check for initial notification that launched the app
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
  
  static void _onSelectNotification(NotificationResponse response) {
    try {
      final payload = jsonDecode(response.payload ?? '{}');
      _notificationStreamController.add(payload);
    } catch (e) {
      print('Failed to parse notification payload: $e');
    }
  }
  
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message in the foreground: ${message.notification?.title}');
    
    // Show local notification
    await _showLocalNotification(
      message.notification?.title ?? 'New notification',
      message.notification?.body ?? '',
      message.data,
    );
  }
  
  static void _handleNotificationTap(RemoteMessage message) {
    _notificationStreamController.add(message.data);
  }
  
  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'arbitrage_notifications',
      'Arbitrage Notifications',
      channelDescription: 'Notifications about arbitrage opportunities',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iOSDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
  }
  
  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }
  
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }
  
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
  
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

// This function must be top-level (not inside a class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // Here you can handle the background message
} 