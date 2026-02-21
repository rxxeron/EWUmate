import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/notification_model.dart';
import 'dart:async';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<AppNotification>> getPersonalNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .map((d) => AppNotification.fromMap(d, d['id']))
            .toList());
  }

  Stream<List<AppNotification>> getBroadcasts() {
    return _supabase
        .from('admin_broadcasts')
        .stream(primaryKey: ['id'])
        .order('sent_at', ascending: false)
        .limit(20)
        .map((data) => data.map((d) {
              final map = Map<String, dynamic>.from(d);
              map['type'] = 'broadcast';
              // Map 'sent_at' to 'createdAt' for model compatibility if needed
              if (map['sent_at'] != null) map['createdAt'] = map['sent_at'];
              return AppNotification.fromMap(map, map['id']);
            }).toList());
  }

  Future<void> markAsRead(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      // Ignore
    }
  }
}
