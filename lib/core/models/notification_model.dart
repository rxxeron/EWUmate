import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { reminder, advising, broadcast, unknown }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type = NotificationType.unknown,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    NotificationType parseType(String? t) {
      if (t == 'reminder') return NotificationType.reminder;
      if (t == 'advising') return NotificationType.advising;
      if (t == 'broadcast') return NotificationType.broadcast;
      return NotificationType.unknown;
    }

    return AppNotification(
      id: id,
      title: map['title'] ?? 'No Title',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['read'] ?? false,
      type: parseType(map['type']),
    );
  }
}
