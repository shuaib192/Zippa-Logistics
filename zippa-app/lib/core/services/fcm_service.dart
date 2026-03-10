// ============================================
// 🔔 FCM SERVICE (fcm_service.dart)
// ============================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'package:zippa_app/data/api/api_client.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final ApiClient _apiClient = ApiClient();

  // ============================================
  // Initialize FCM and Permissions
  // ============================================
  static Future<void> initialize() async {
    // If not already initialized, ensure we do it with platform options
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }

    // 1. Request Permission (For iOS/Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    }

    // 2. Setup Local Notifications (For Foreground messages)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(initSettings);

    // 3. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground Notification: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 4. Handle Notification Clicks (When app is in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 Notification Clicked: ${message.data}');
      // TODO: Handle navigation based on message data
    });
  }

  // ============================================
  // Get and Update Token
  // ============================================
  static Future<void> syncToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🎟️ FCM Token: $token');
        await _apiClient.put('/users/fcm-token', {'token': token});
      }
    } catch (e) {
      debugPrint('❌ Error syncing FCM token: $e');
    }
  }

  // ============================================
  // Private: Show Local Notification
  // ============================================
  static void _showLocalNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'zippa_alerts',
      'Zippa Alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }
}
