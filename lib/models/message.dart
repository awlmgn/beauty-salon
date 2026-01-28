// models/message.dart
class Message {
  final int id;
  final int masterId;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.masterId,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      masterId: json['master_id'] ?? json['masterId'] ?? 0,
      text: json['text'] ?? '',
      isFromUser: (json['is_from_user'] ?? json['isFromUser'] ?? 0) == 1,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: (json['is_read'] ?? json['isRead'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'master_id': masterId,
      'text': text,
      'is_from_user': isFromUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  // Метод для создания "прочитанной" копии
  Message markAsRead() {
    return Message(
      id: id,
      masterId: masterId,
      text: text,
      isFromUser: isFromUser,
      timestamp: timestamp,
      isRead: true,
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, masterId: $masterId, text: $text, isFromUser: $isFromUser, timestamp: $timestamp, isRead: $isRead}';
  }
}