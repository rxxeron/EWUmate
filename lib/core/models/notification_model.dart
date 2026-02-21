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

    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return AppNotification(
      id: id,
      title: map['title'] ?? 'No Title',
      body: map['body'] ?? '',
      createdAt: parseDate(map['createdAt']),
      isRead: map['read'] ?? false,
      type: parseType(map['type']),
    );
  }
}
