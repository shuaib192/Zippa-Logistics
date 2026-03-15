// ============================================
// 🔔 SCRUBBED FCM SERVICE (v14)
// ============================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'debug_log_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final ApiClient _apiClient = ApiClient();

  static const String _channelId = 'zippa_priority_alerts';

  static Future<void> initialize() async {
    try {
      DebugLogService.addLog('🚀 Initializing FCM Scrub...');
      
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

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
      DebugLogService.addLog('✅ Channel registered: $_channelId');

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      
      await _localNotifications.initialize(initSettings);
      DebugLogService.addLog('✅ Local notifications ready');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        DebugLogService.addLog('🔔 Foreground msg: ${message.notification?.title}');
        _showScrubbedAlert(message);
      });

    } catch (e) {
      DebugLogService.addLog('❌ Init Error: $e');
    }
  }

  static void _showScrubbedAlert(RemoteMessage message) {
    try {
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
            priority: Priority.max,
            icon: 'ic_launcher',
            playSound: true,
            ticker: 'Zippa Logistics Alert',
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
        ),
      );
      DebugLogService.addLog('✅ Alert displayed!');
    } catch (e) {
      DebugLogService.addLog('❌ Display Error: $e');
    }
  }

  static Future<void> syncToken() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      String? token = await _messaging.getToken();
      if (token != null) {
        DebugLogService.addLog('🎟️ Token synced');
        await _apiClient.put('/users/fcm-token', {'token': token});
      }
    } catch (e) {
      DebugLogService.addLog('❌ Sync Error: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      DebugLogService.addLog('📢 Subscribed to $topic');
    } catch (e) {
      DebugLogService.addLog('❌ Topic Error: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      DebugLogService.addLog('🔇 Unsubscribed from $topic');
    } catch (e) {
      debugPrint('❌ Scrubbed Unsub Error: $e');
    }
  }
}
