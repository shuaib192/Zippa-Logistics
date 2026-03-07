import 'package:flutter/material.dart';
import 'package:zippa_app/data/api/api_client.dart';

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => n['is_read'] == false).length;

  // ============================================
  // API CALL: Get Notifications
  // ============================================
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/notifications');
      if (response['success'] != false && response['notifications'] != null) {
        _notifications = response['notifications'] as List;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = 'Failed to fetch notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // API CALL: Mark as Read
  // ============================================
  Future<void> markAsRead(String id) async {
    try {
      final response = await _apiClient.put('/notifications/$id/read', {});
      if (response['success'] != false) {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
