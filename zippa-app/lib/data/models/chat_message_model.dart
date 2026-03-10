// ============================================
// 🎓 CHAT MESSAGE MODEL (chat_message_model.dart)
// ============================================

class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String msg;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.msg,
    required this.isRead,
    required this.createdAt,
    this.senderName,
  });

  // Factory constructor — creates a Message from JSON (API response)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      msg: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      senderName: json['sender_name'],
    );
  }
}
