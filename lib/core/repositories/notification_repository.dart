import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as model;
import '../providers/supabase_provider.dart';
import 'auth_repository.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  Stream<List<model.Notification>> streamNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map(
          (data) =>
              data.map((json) => model.Notification.fromJson(json)).toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}

@riverpod
NotificationRepository notificationRepository(NotificationRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationRepository(supabase);
}

@riverpod
Stream<List<model.Notification>> userNotifications(UserNotificationsRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(notificationRepositoryProvider).streamNotifications(user.id);
}
