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
    // 1. Initialize Firebase
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }

    // 2. Setup Notification Channel for Android (CRITICAL for background/heads-up)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'zippa_alerts', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important zippa notifications.', // description
      importance: Importance.max,
    );

    // Create the channel on the device
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Setup Local Notifications Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(initSettings);

    // 4. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground Notification: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 5. Handle Notification Clicks (When app is in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 Notification Clicked: ${message.data}');
    });
  }

  // ============================================
  // Request Notification Permission (Recommended to call from UI)
  // ============================================
  static Future<bool> requestNotificationPermission() async {
    try {
      // 1. Use Firebase's native requestPermission FIRST — this is the most
      //    reliable way to trigger the Android 13+ system dialog
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notification permission granted via Firebase');
        return true;
      }
      
      // 2. Fallback: try permission_handler as a secondary approach
      PermissionStatus status = await Permission.notification.status;
      if (status.isDenied) {
        status = await Permission.notification.request();
      }
      
      if (status.isGranted) {
        debugPrint('✅ Notification permission granted via permission_handler');
        return true;
      }
      
      debugPrint('⚠️ Notification permission not granted. Status: ${settings.authorizationStatus}');
      return false;
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
      await requestNotificationPermission();

      // Always try to get the token — on some devices permission is
      // granted silently and getToken() works even without explicit grant
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🎟️ FCM Token: $token');
        await _apiClient.put('/users/fcm-token', {'token': token});
      } else {
        debugPrint('⚠️ Could not retrieve FCM token.');
      }
    } catch (e) {
      debugPrint('❌ Error syncing FCM token: $e');
    }
  }

  // ============================================
  // Subscribe to Topic (Not supported on web)
  // ============================================
  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) {
      debugPrint('📢 Topic subscription skipped on web (not supported)');
      return;
    }
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📢 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  // ============================================
  // Unsubscribe from Topic (Not supported on web)
  // ============================================
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
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
