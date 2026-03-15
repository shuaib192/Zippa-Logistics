// ============================================
// 🔔 SCRUBBED FCM SERVICE (v14)
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

  // Fresh Channel ID to force Android to reset notification preferences
  static const String _channelId = 'zippa_priority_alerts';

  static Future<void> initialize() async {
    try {
      debugPrint('🧼 SCRUBBED FCM: Rebuilding from scratch...');
      
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // 1. Create the Priority Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        'Order & Delivery Alerts',
        description: 'Crucial notifications for Zippa Logistics.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 2. Initialize Local Notifications
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      
      await _localNotifications.initialize(initSettings);

      // 3. Foreground Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 Scrubbed Foreground Received: ${message.notification?.title}');
        _showScrubbedAlert(message);
      });

    } catch (e) {
      debugPrint('❌ Scrubbed FCM Error: $e');
    }
  }

  static void _showScrubbedAlert(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'Zippa Alert';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Order & Delivery Alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_launcher',
          playSound: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }

  static Future<void> syncToken() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🎟️ Scrubbed Token: $token');
        await _apiClient.put('/users/fcm-token', {'token': token});
      }
    } catch (e) {
      debugPrint('❌ Scrubbed Sync Error: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📢 Scrubbed Subscribed: $topic');
    } catch (e) {
      debugPrint('❌ Scrubbed Sub Error: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('❌ Scrubbed Unsub Error: $e');
    }
  }
}
