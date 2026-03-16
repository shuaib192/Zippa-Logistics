// ============================================
// 🛰️ PUSH DEBUG SCREEN (push_debug_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zippa_app/core/theme/app_theme.dart';

class PushDebugScreen extends StatefulWidget {
  const PushDebugScreen({super.key});

  @override
  State<PushDebugScreen> createState() => _PushDebugScreenState();
}

class _PushDebugScreenState extends State<PushDebugScreen> {
  String _token = "Fetching...";
  String _permissionStatus = "Unknown";
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, "${DateTime.now().toString().split('.').first}: $msg");
    });
  }

  Future<void> _loadDebugInfo() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      
      setState(() {
        _token = token ?? "No token found";
        _permissionStatus = settings.authorizationStatus.toString();
      });
      _addLog("Token loaded.");
    } catch (e) {
      _addLog("Error loading info: $e");
    }
  }

  Future<void> _testLocalNotification() async {
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        'zippa_priority_alerts',
        'Zippa Priority',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      await flutterLocalNotificationsPlugin.show(
        999,
        '🚀 LOCAL TEST',
        'If you see this, the app can show popups!',
        notificationDetails,
      );
      _addLog("Local notification triggered.");
    } catch (e) {
      _addLog("Local test failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Push Debugger (V18)"),
        backgroundColor: ZippaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FCM Token (Crucial):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(_token, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _token));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Token copied to clipboard!")));
                },
                icon: const Icon(Icons.copy),
                label: const Text("Copy Token"),
                style: ElevatedButton.styleFrom(backgroundColor: ZippaColors.primary, foregroundColor: Colors.white),
              ),
            ),
            const Divider(height: 40),
            _StatusTile(title: "Permissions", value: _permissionStatus),
            const Divider(height: 40),
            const Text("Self-Test Tools:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testLocalNotification,
              child: const Text("Trigger Manual Popup"),
            ),
            const Divider(height: 40),
            const Text("Debug Logs:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, i) => Text(_logs[i], style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String title;
  final String value;
  const _StatusTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
