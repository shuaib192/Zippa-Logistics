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
      debugPrint('☢️ NUCLEAR FCM: Initializing...');
      
      // 1. Initialize Firebase
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // 2. Setup Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'zippa_alerts',
        'Zippa Notifications',
        description: 'Crucial delivery and order alerts.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
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
          debugPrint('🚀 Notification Action: ${details.payload}');
        },
      );

      // 4. Foreground Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 Nuclear Foreground Message Received');
        handleNuclearMessage(message);
      });

      // 5. Open App Handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 Nuclear Notification Clicked');
      });
      
      debugPrint('✅ NUCLEAR FCM: Ready');
    } catch (e) {
      debugPrint('❌ NUCLEAR FCM Error: $e');
    }
  }

  // ============================================
  // NUCLEAR HANDLER: This is the brain of the fix
  // ============================================
  static void handleNuclearMessage(RemoteMessage message) {
    debugPrint('☢️ Processing Data-Only Message...');
    
    // We look for title and body INSIDE the data object
    final String? title = message.data['title'] ?? message.notification?.title;
    final String? body = message.data['body'] ?? message.notification?.body;

    if (title != null && body != null) {
      _showLocalNotification(title, body, message.data);
    } else {
      debugPrint('⚠️ Nuclear Message missing content. Data: ${message.data}');
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
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
        debugPrint('🎟️ Nuclear Token: $token');
        await _apiClient.put('/users/fcm-token', {'token': token});
      }
    } catch (e) {
      debugPrint('❌ Nuclear Sync Error: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📢 Subscribed: $topic');
    } catch (e) {
      debugPrint('❌ Subscription Error: $e');
    }
  }

  static void _showLocalNotification(String title, String body, Map<String, dynamic> data) {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'zippa_alerts',
        'Zippa Notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: 'ic_launcher',
        playSound: true,
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
      debugPrint('❌ Local Notification Display Error: $e');
    }
  }
}
