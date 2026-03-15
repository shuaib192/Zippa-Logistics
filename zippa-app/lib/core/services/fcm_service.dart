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
    try {
      debugPrint('🔔 FCM: Initializing Hybrid System...');
      
      // 1. Initialize Firebase
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // 2. Setup Notification Channel (MANDATORY for Android 8+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'zippa_alerts', // id
        'High Importance Notifications', // name (User sees this)
        description: 'Priority alerts for orders and delivery updates.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Setup Local Notifications Settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('🚀 Notification User Action: ${details.payload}');
        },
      );

      // 4. Listen for Foreground Messages (Manually show alert)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 Foreground Message: ${message.notification?.title}');
        handleIncomingMessage(message);
      });

      // 5. Handle Notification Clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 Notification Click Handler');
      });
      
      debugPrint('✅ FCM Service Ready');
    } catch (e) {
      debugPrint('❌ FCM Init Error: $e');
    }
  }

  // ============================================
  // UNIFIED HANDLER: Handles both data and notification
  // ============================================
  static void handleIncomingMessage(RemoteMessage message) {
    // If we have a notification object, use it. Otherwise look in data.
    final String? title = message.notification?.title ?? message.data['title'];
    final String? body = message.notification?.body ?? message.data['body'];

    if (title != null && body != null) {
      _showLocalNotification(title, body, message.data);
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true, 
        badge: true, 
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      return false;
    }
  }

  static Future<void> syncToken() async {
    try {
      await requestNotificationPermission();
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🎟️ FCM Token: $token');
        await _apiClient.put('/users/fcm-token', {'token': token});
      }
    } catch (e) {
      debugPrint('❌ Token Sync Error: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📢 Subscribed to $topic');
    } catch (e) {
      debugPrint('❌ Subscription Error: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('🔇 Unsubscribed from $topic');
    } catch (e) {
      debugPrint('❌ Unsubscription Error: $e');
    }
  }

  static void _showLocalNotification(String title, String body, Map<String, dynamic> data) {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'zippa_alerts',
        'High Importance Notifications',
        channelDescription: 'Priority alerts for orders and delivery updates.',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_launcher',
        playSound: true,
        fullScreenIntent: true, // Attempt to wake up screen
        category: AndroidNotificationCategory.alarm,
      );
      
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      
      _localNotifications.show(
        title.hashCode ^ body.hashCode,
        title,
        body,
        details,
        payload: data.toString(),
      );
    } catch (e) {
      debugPrint('❌ Local Notification Error: $e');
    }
  }
}
