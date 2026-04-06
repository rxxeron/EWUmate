import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/notification.dart';
import '../providers/supabase_provider.dart';
import '../services/cache_service.dart';
import 'auth_repository.dart';

part 'task_repository.g.dart';

class TaskRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;

  TaskRepository(this._supabase, this._cache);

  Future<List<Task>> getActiveTasks(String userId) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .order('due_date', ascending: true);

    return (response as List).map((e) => Task.fromJson(e)).toList();
  }

  Stream<List<Task>> streamUserTasks(String userId) async* {
    // 1. Yield from cache instantly
    final cachedSchedule = _cache.getCachedDashboardSchedule(userId);
    if (cachedSchedule != null && cachedSchedule['tasks'] != null) {
      yield (cachedSchedule['tasks'] as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // 2. Stream from network
    try {
      await for (final events in _supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('due_date', ascending: true)) {
        
        final newTasks = events.map((e) => Task.fromJson(e)).toList();
        
        // Update physical cache
        final currentCache = _cache.getCachedDashboardSchedule(userId) ?? {};
        currentCache['tasks'] = newTasks.map((t) {
          final tMap = t.toJson();
          if (tMap['dueDate'] is DateTime) tMap['dueDate'] = tMap['dueDate'].toIso8601String();
          if (tMap['createdAt'] is DateTime) tMap['createdAt'] = tMap['createdAt'].toIso8601String();
          return tMap;
        }).toList();
        _cache.cacheDashboardSchedule(userId, currentCache);
        
        yield newTasks;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TaskRepository] Offline mode active: $e');
    }
  }

  Future<Task> createTask(String userId, Task task) async {
    try {
      final response = await _supabase
          .from('tasks')
          .insert(task.toJson())
          .select()
          .single();
      return Task.fromJson(response);
    } catch (e) {
      // Offline fallback
      _optimisticInsert(userId, task);
      await _cache.enqueueMutation(userId, {
        'action': 'create_task',
        'task': task.toJson(),
      });
      return task;
    }
  }

  Future<Task> updateTask(String userId, Task task) async {
    try {
      final response = await _supabase
          .from('tasks')
          .update(task.toJson())
          .eq('id', task.id)
          .select()
          .single();
      return Task.fromJson(response);
    } catch (e) {
      _optimisticUpdate(userId, task);
      await _cache.enqueueMutation(userId, {
        'action': 'update_task',
        'task': task.toJson(),
      });
      return task;
    }
  }

  Future<void> updateTaskStatus(String userId, String taskId, bool isCompleted) async {        
    try {
      await _supabase
          .from('tasks')
          .update({'is_completed': isCompleted})
          .eq('id', taskId);
    } catch (e) {
      _optimisticStatusUpdate(userId, taskId, isCompleted);
      await _cache.enqueueMutation(userId, {
        'action': 'update_task_status',
        'taskId': taskId,
        'isCompleted': isCompleted,
      });
    }
  }

  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      _optimisticDelete(userId, taskId);
      await _cache.enqueueMutation(userId, {
        'action': 'delete_task',
        'taskId': taskId,
      });
    }
  }

  // Optimistic Cache Updaters
  void _optimisticInsert(String userId, Task task) {
    final cached = _cache.getCachedDashboardSchedule(userId) ?? {};
    final tasksList = List<dynamic>.from(cached['tasks'] ?? []);
    final tMap = task.toJson();
    if (task.dueDate != null) tMap['due_date'] = task.dueDate!.toIso8601String();
    tasksList.add(tMap);
    cached['tasks'] = tasksList;
    _cache.cacheDashboardSchedule(userId, cached);
  }

  void _optimisticUpdate(String userId, Task task) {
    final cached = _cache.getCachedDashboardSchedule(userId);
    if (cached == null || cached['tasks'] == null) return;
    final tasksList = List<dynamic>.from(cached['tasks']);
    final index = tasksList.indexWhere((e) => (e as Map)['id'] == task.id);
    if (index != -1) {
      final tMap = task.toJson();
      if (task.dueDate != null) tMap['due_date'] = task.dueDate!.toIso8601String();
      tasksList[index] = tMap;
      cached['tasks'] = tasksList;
      _cache.cacheDashboardSchedule(userId, cached);
    }
  }

  void _optimisticStatusUpdate(String userId, String taskId, bool isCompleted) {
    final cached = _cache.getCachedDashboardSchedule(userId);
    if (cached == null || cached['tasks'] == null) return;
    final tasksList = List<dynamic>.from(cached['tasks']);
    final index = tasksList.indexWhere((e) => (e as Map)['id'] == taskId);
    if (index != -1) {
      final tMap = Map<String, dynamic>.from(tasksList[index]);
      tMap['is_completed'] = isCompleted;
      tasksList[index] = tMap;
      cached['tasks'] = tasksList;
      _cache.cacheDashboardSchedule(userId, cached);
    }
  }

  void _optimisticDelete(String userId, String taskId) {
    final cached = _cache.getCachedDashboardSchedule(userId);
    if (cached == null || cached['tasks'] == null) return;
    final tasksList = List<dynamic>.from(cached['tasks']);
    tasksList.removeWhere((e) => (e as Map)['id'] == taskId);
    cached['tasks'] = tasksList;
    _cache.cacheDashboardSchedule(userId, cached);
  }

  Stream<List<Notification>> streamNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('trigger_at', ascending: false)
        .map((events) => events.map((e) => Notification.fromJson(e)).toList()); 
  }
}

@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  return TaskRepository(
    ref.watch(supabaseClientProvider), 
    ref.watch(cacheServiceProvider)
  );
}

@riverpod
Future<List<Task>> activeTasksConfig(ActiveTasksConfigRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(taskRepositoryProvider).getActiveTasks(user.id);
}

@riverpod
Stream<List<Task>> allTasksStream(AllTasksStreamRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(taskRepositoryProvider).streamUserTasks(user.id);
}

@riverpod
Stream<List<Notification>> userNotifications(UserNotificationsRef ref) {        
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(taskRepositoryProvider).streamNotifications(user.id);        
}
