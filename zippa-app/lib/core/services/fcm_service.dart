// ============================================
// 🔔 FCM SERVICE (fcm_service.dart)
// ============================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
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
    });
  }

  // ============================================
  // Request Notification Permission (Recommended to call from UI)
  // ============================================
  static Future<bool> requestNotificationPermission() async {
    try {
      // For Android 13+ and iOS, we use permission_handler which is more reliable
      PermissionStatus status = await Permission.notification.status;
      
      if (status.isDenied) {
        status = await Permission.notification.request();
      }
      
      if (status.isGranted) {
        debugPrint('✅ User granted notification permission via permission_handler');
        return true;
      }
      
      // Fallback to FCM built-in request if permission_handler didn't get it
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  // ============================================
  // Get and Update Token
  // ============================================
  static Future<void> syncToken() async {
    try {
      // Prompt for permissions when syncing token (if not already granted)
      bool granted = await requestNotificationPermission();

      if (granted) {
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('🎟️ FCM Token: $token');
          await _apiClient.put('/users/fcm-token', {'token': token});
        }
      } else {
         debugPrint('⚠️ User declined notification permissions.');
      }
    } catch (e) {
      debugPrint('❌ Error syncing FCM token: $e');
    }
  }

  // ============================================
  // Subscribe to Topic
  // ============================================
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📢 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  // ============================================
  // Unsubscribe from Topic
  // ============================================
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('🔇 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
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
