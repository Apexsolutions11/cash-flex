import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cashflex/theme/app_theme.dart';
import 'package:cashflex/utils/constant/constant.dart' as app_constant;

class NotificationService {
  static String fcmToken = '';

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _setupFirebaseMessaging();
  }

  static Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);
      debugPrint('User granted permission: ${settings.authorizationStatus}');

      // Subscribe to topics used by the backend
      await _firebaseMessaging.subscribeToTopic('default');
      await _firebaseMessaging.subscribeToTopic('promo');
      await _firebaseMessaging.subscribeToTopic('all');

      final token = await _firebaseMessaging.getToken();
      fcmToken = token ?? '';
      if (fcmToken.isNotEmpty) debugPrint('FCM Token: $fcmToken');
    } catch (e) {
      debugPrint('Error in FCM setup: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      await _localNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('drawable/logo'),
        ),
        onDidReceiveNotificationResponse: (details) async {
          debugPrint('Notification response received');
        },
      );
      debugPrint('Local Notification initialized');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  static Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    _firebaseMessaging.getInitialMessage().then(_handleInitialMessage).catchError((e) {
      debugPrint('getInitialMessage error: $e');
    });
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(message);
    }
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      debugPrint(
        'App opened from notification: ${message.notification!.title}',
      );
    }
  }

  static void _handleInitialMessage(RemoteMessage? message) {
    if (message != null && message.notification != null) {
      debugPrint('Initial message received: ${message.notification!.title}');
    }
  }

  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    debugPrint('Background message received: ${message.data}');
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String payload = message.data['payload'] ?? '';

      NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          app_constant.appName.toLowerCase(),
          app_constant.appName,
          importance: Importance.max,
          priority: Priority.high,
          icon: 'drawable/logo',
          color: AppTheme.darkTheme.colorScheme.background,
          largeIcon: const DrawableResourceAndroidBitmap('mipmap/ic_launcher'),
        ),
      );

      await _localNotificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }
}
