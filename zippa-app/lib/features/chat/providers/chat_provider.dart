// ============================================
// 💬 CHAT PROVIDER (chat_provider.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'package:zippa_app/data/models/chat_message_model.dart';
import 'dart:async';

class ChatProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================
  // Fetch Messages
  // ============================================
  Future<void> fetchMessages(String orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/chat/order/$orderId');
      
      if (response['success'] == true) {
        final List<dynamic> data = response['messages'];
        _messages = data.map((json) => ChatMessage.fromJson(json)).toList();
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to load messages';
      }
    } catch (e) {
      _error = 'Connection error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Send Message
  // ============================================
  Future<bool> sendMessage(String orderId, String text) async {
    try {
      final response = await _api.post('/chat/order/send', {
        'orderId': orderId,
        'message': text,
      });

      if (response['success'] == true) {
        // Optimistically add to list or just refetch
        final newMessage = ChatMessage.fromJson(response['message']);
        _messages.add(newMessage);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // Polling for new messages
  // ============================================
  void startPolling(String orderId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _silentFetch(orderId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _silentFetch(String orderId) async {
    try {
      final response = await _api.get('/chat/order/$orderId');
      if (response['success'] == true) {
        final List<dynamic> data = response['messages'];
        final newMessages = data.map((json) => ChatMessage.fromJson(json)).toList();
        
        // Only update if count changed (simple check)
        if (newMessages.length != _messages.length) {
          _messages = newMessages;
          notifyListeners();
        }
      }
    } catch (e) {
      // Ignore errors during silent fetch
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
