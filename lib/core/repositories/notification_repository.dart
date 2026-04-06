import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as model;
import '../providers/supabase_provider.dart';
import '../services/cache_service.dart';
import 'auth_repository.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;

  NotificationRepository(this._supabase, this._cache);

  Stream<List<model.Notification>> streamNotifications(String userId) async* {
    final cachedData = _cache.getMapData('dashboard_box', 'notifications_$userId');
    if (cachedData != null && cachedData['list'] != null) {
      final list = (cachedData['list'] as List)
          .map((json) => model.Notification.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      yield list;
    }

    try {
      await for (final data in _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50)) {
        
        final notifications = data.map((json) {
          final modifiableJson = Map<String, dynamic>.from(json);
          if (modifiableJson['payload'] is String) {
            try {
              modifiableJson['payload'] = jsonDecode(modifiableJson['payload']);
            } catch (_) {
              modifiableJson['payload'] = null;
            }
          }
          return model.Notification.fromJson(modifiableJson);
        }).toList();

        _cache.setMapData('dashboard_box', 'notifications_$userId', {
          'list': notifications.map((n) => n.toJson()).toList(),
        });

        yield notifications;
      }
    } catch (e) {
      debugPrint('[Notifications] Offline mode fallback: $e');
    }
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
  final cache = ref.watch(cacheServiceProvider);
  return NotificationRepository(supabase, cache);
}

@riverpod
Stream<List<model.Notification>> userNotifications(UserNotificationsRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(notificationRepositoryProvider).streamNotifications(user.id);
}
