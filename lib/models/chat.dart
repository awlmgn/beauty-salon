// models/chat.dart
import 'master.dart';

class Chat {
  final int masterId;
  final Master master;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  Chat({
    required this.masterId,
    required this.master,
    this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      masterId: json['master_id'],
      master: Master(
        id: json['master_id'],
        name: json['master_name'],
        specialization: json['specialization'] ?? 'Парикмахер',
        description: json['description'] ?? 'Профессиональный мастер',
        experience: json['experience'] ?? 1,
        imageUrl: json['image_url'] ?? 'assets/default_master.png',
        rating: json['rating'] != null ? double.parse(json['rating'].toString()) : 0.0,
      ),
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Chat{master: ${master.name}, lastMessage: $lastMessage, unreadCount: $unreadCount}';
  }
}