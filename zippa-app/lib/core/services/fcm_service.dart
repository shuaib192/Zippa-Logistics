// ============================================
// 🔔 FCM SERVICE (v16 — DATA-ONLY HANDLER)
//
// Handles data-only payloads from the backend.
// Since there is NO "notification" key, the OS will NOT
// auto-display anything. WE handle display in ALL states:
// foreground, background, and terminated.
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

  static const String _channelId = 'zippa_priority_alerts';

  static Future<void> initialize() async {
    try {
      debugPrint('🔔 FCM v16: Initializing data-only handler...');
      
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // CRITICAL: Tell Firebase to show alerts even in foreground
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Create the notification channel
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

      // Initialize local notifications
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      
      await _localNotifications.initialize(initSettings);

      // FOREGROUND: Data-only messages always fire onMessage
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 v16 Foreground: ${message.data}');
        _showPopup(message);
      });

      debugPrint('✅ FCM v16 ready.');
    } catch (e) {
      debugPrint('❌ FCM v16 Init Error: $e');
    }
  }

  /// Called from both foreground (onMessage) and background handler
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 v16 Background: ${message.data}');
    
    // Initialize local notifications for background context
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'Order & Delivery Alerts',
      description: 'Crucial notifications for Zippa Logistics.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final localNotifications = FlutterLocalNotificationsPlugin();
    
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await localNotifications.initialize(initSettings);

    // Extract from data payload
    final title = message.data['title'] ?? 'Zippa Alert';
    final body = message.data['body'] ?? '';

    await localNotifications.show(
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
  }

  static void _showPopup(RemoteMessage message) {
    // Data-only: title and body are in message.data
    final title = message.data['title'] ?? 'Zippa Alert';
    final body = message.data['body'] ?? '';

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
    debugPrint('✅ v16 Popup displayed: $title');
  }

  static Future<void> syncToken() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🎟️ v16 Token: $token');
        await _apiClient.put('/users/fcm-token', {'token': token});
      }
    } catch (e) {
      debugPrint('❌ v16 Sync Error: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📢 v16 Subscribed: $topic');
    } catch (e) {
      debugPrint('❌ v16 Topic Error: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('❌ v16 Unsub Error: $e');
    }
  }
}
