import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    // 1. Yield local data immediately for instant UI
    final localNotifs = getLocalNotifications(userId);
    yield localNotifs;

    try {
      await for (final data in _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50)) {
        
        final notifications = data.where((json) {
          return json['is_dispatched'] == true;
        }).map((json) {
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

        // 3. Update local storage with fresh server data
        await _syncLocalWithServer(userId, notifications);
        yield notifications;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Notifications] Offline mode fallback: $e');
    }
  }

  List<model.Notification> getLocalNotifications(String userId) {
    try {
      final box = Hive.box('notifications_box');
      final dataStr = box.get('notifs_$userId') as String?;
      if (dataStr != null) {
        final List<dynamic> decoded = jsonDecode(dataStr);
        return decoded.map((j) => model.Notification.fromJson(Map<String, dynamic>.from(j))).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Notifications] Local read error: $e');
    }
    return [];
  }

  Future<void> saveLocalNotification(model.Notification notification) async {
    try {
      final box = Hive.box('notifications_box');
      final key = 'notifs_${notification.userId}';
      
      final currentList = getLocalNotifications(notification.userId);
      if (currentList.any((n) => n.id == notification.id)) return;

      final updatedList = [notification, ...currentList];
      // Keep last 100
      final limitedList = updatedList.length > 100 ? updatedList.sublist(0, 100) : updatedList;
      
      await box.put(key, jsonEncode(limitedList.map((n) => n.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('[Notifications] Local save error: $e');
    }
  }

  Future<void> _syncLocalWithServer(String userId, List<model.Notification> serverNotifs) async {
    try {
      final box = Hive.box('notifications_box');
      final key = 'notifs_$userId';
      await box.put(key, jsonEncode(serverNotifs.map((n) => n.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('[Notifications] Sync error: $e');
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

@Riverpod(keepAlive: true)
Stream<List<model.Notification>> userNotifications(UserNotificationsRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(notificationRepositoryProvider).streamNotifications(user.id);
}
