import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:ewumate/core/models/task.dart';
import 'package:ewumate/core/models/notification.dart';
import 'package:ewumate/core/providers/supabase_provider.dart';
import 'package:ewumate/core/services/cache_service.dart';
import 'package:ewumate/core/utils/course_utils.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/features/auth/auth_providers.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';

part 'task_repository.g.dart';

class TaskRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;

  TaskRepository(this._supabase, this._cache);

  Future<List<Task>> getActiveTasks(String userId, {String? semesterCode}) async {
    var query = _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false);
    
    if (semesterCode != null) {
      final safeSem = CourseUtils.cleanSemester(semesterCode);
      query = query.or('semester_code.eq.$safeSem,semester_code.is.null');
    }

    final response = await query.order('due_date', ascending: true);
    return (response as List).map((e) => Task.fromJson(e)).toList();
  }

  Stream<List<Task>> streamUserTasks(String userId, String semesterCode) async* {
    final safeSem = CourseUtils.cleanSemester(semesterCode);
    // 1. Yield from cache instantly
    final cachedSchedule = _cache.getCachedDashboardSchedule(userId, safeSem);
    if (cachedSchedule != null && cachedSchedule['tasks'] != null) {
      yield (cachedSchedule['tasks'] as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // 2. Stream from network
    try {
      var query = _supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId);
      
      // Note: Supabase Stream doesn't support complex .or filters easily in all client versions
      // so we stream all active/recent tasks and filter locally if needed, 
      // or just trust the stream to be specific if we can.
      
      await for (final events in query.order('due_date', ascending: true)) {
        final newTasks = events.map((e) => Task.fromJson(e)).toList();
        
        // Update physical cache
        final currentCache = _cache.getCachedDashboardSchedule(userId, safeSem) ?? {};
        currentCache['tasks'] = newTasks.map((t) {
          final tMap = t.toJson();
          if (tMap['dueDate'] is DateTime) tMap['dueDate'] = tMap['dueDate'].toIso8601String();
          if (tMap['createdAt'] is DateTime) tMap['createdAt'] = tMap['createdAt'].toIso8601String();
          return tMap;
        }).toList();
        _cache.cacheDashboardSchedule(userId, safeSem, currentCache);
        
        yield newTasks;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TaskRepository] Offline mode active: $e');
    }
  }

  Future<Task> createTask(String userId, Task task, {String? semesterCode}) async {
    try {
      final response = await _supabase
          .from('tasks')
          .insert(task.toJson())
          .select()
          .single();
      final savedTask = Task.fromJson(response);
      if (semesterCode != null) _optimisticInsert(userId, savedTask, semesterCode);
      return savedTask;
    } catch (e) {
      // Offline fallback
      if (semesterCode != null) _optimisticInsert(userId, task, semesterCode);
      await _cache.enqueueMutation(userId, {
        'action': 'create_task',
        'task': task.toJson(),
      });
      return task;
    }
  }

  Future<Task> updateTask(String userId, Task task, {String? semesterCode}) async {
    try {
      final response = await _supabase
          .from('tasks')
          .update(task.toJson())
          .eq('id', task.id)
          .select()
          .single();
      final savedTask = Task.fromJson(response);
      if (semesterCode != null) _optimisticUpdate(userId, savedTask, semesterCode);
      return savedTask;
    } catch (e) {
      if (semesterCode != null) _optimisticUpdate(userId, task, semesterCode);
      await _cache.enqueueMutation(userId, {
        'action': 'update_task',
        'task': task.toJson(),
      });
      return task;
    }
  }

  Future<void> updateTaskStatus(String userId, String taskId, bool isCompleted, {String? semesterCode}) async {        
    try {
      await _supabase
          .from('tasks')
          .update({'is_completed': isCompleted})
          .eq('id', taskId);
      if (semesterCode != null) _optimisticStatusUpdate(userId, taskId, isCompleted, semesterCode);
    } catch (e) {
      if (semesterCode != null) _optimisticStatusUpdate(userId, taskId, isCompleted, semesterCode);
      await _cache.enqueueMutation(userId, {
        'action': 'update_task_status',
        'taskId': taskId,
        'isCompleted': isCompleted,
      });
    }
  }

  Future<void> updateTaskMissedStatus(String userId, String taskId, bool isMissed, {String? semesterCode}) async {
    try {
      await _supabase
          .from('tasks')
          .update({'is_missed': isMissed})
          .eq('id', taskId);
    } catch (e) {
       // Manual optimistic update for missed status
       if (semesterCode != null) {
         final safeSem = CourseUtils.cleanSemester(semesterCode);
         final cached = _cache.getCachedDashboardSchedule(userId, safeSem);
         if (cached != null && cached['tasks'] != null) {
           final tasksList = List<dynamic>.from(cached['tasks']);
           final index = tasksList.indexWhere((e) => (e as Map)['id'] == taskId);
           if (index != -1) {
             final tMap = Map<String, dynamic>.from(tasksList[index]);
             tMap['is_missed'] = isMissed;
             tasksList[index] = tMap;
             cached['tasks'] = tasksList;
             _cache.cacheDashboardSchedule(userId, safeSem, cached);
           }
         }
       }
       
      await _cache.enqueueMutation(userId, {
        'action': 'update_task_missed',
        'taskId': taskId,
        'isMissed': isMissed,
      });
    }
  }

  Future<void> deleteTask(String userId, String taskId, {String? semesterCode}) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      if (semesterCode != null) _optimisticDelete(userId, taskId, semesterCode);
    } catch (e) {
      if (semesterCode != null) _optimisticDelete(userId, taskId, semesterCode);
      await _cache.enqueueMutation(userId, {
        'action': 'delete_task',
        'taskId': taskId,
      });
    }
  }

  // Optimistic Cache Updaters
  void _optimisticInsert(String userId, Task task, String semesterCode) {
    final safeSem = CourseUtils.cleanSemester(semesterCode);
    final cached = _cache.getCachedDashboardSchedule(userId, safeSem) ?? {};
    final tasksList = List<dynamic>.from(cached['tasks'] ?? []);
    final tMap = task.toJson();
    if (task.dueDate != null) tMap['due_date'] = task.dueDate!.toIso8601String();
    tasksList.add(tMap);
    cached['tasks'] = tasksList;
    _cache.cacheDashboardSchedule(userId, safeSem, cached);
  }

  void _optimisticUpdate(String userId, Task task, String semesterCode) {
    final safeSem = CourseUtils.cleanSemester(semesterCode);
    final cached = _cache.getCachedDashboardSchedule(userId, safeSem);
    if (cached == null || cached['tasks'] == null) return;
    final tasksList = List<dynamic>.from(cached['tasks']);
    final index = tasksList.indexWhere((e) => (e as Map)['id'] == task.id);
    if (index != -1) {
      final tMap = task.toJson();
      if (task.dueDate != null) tMap['due_date'] = task.dueDate!.toIso8601String();
      tasksList[index] = tMap;
      cached['tasks'] = tasksList;
      _cache.cacheDashboardSchedule(userId, safeSem, cached);
    }
  }

  void _optimisticStatusUpdate(String userId, String taskId, bool isCompleted, String semesterCode) {
    final safeSem = CourseUtils.cleanSemester(semesterCode);
    final cached = _cache.getCachedDashboardSchedule(userId, safeSem);
    if (cached == null || cached['tasks'] == null) return;
    final tasksList = List<dynamic>.from(cached['tasks']);
    final index = tasksList.indexWhere((e) => (e as Map)['id'] == taskId);
    if (index != -1) {
      final tMap = Map<String, dynamic>.from(tasksList[index]);
      tMap['is_completed'] = isCompleted;
      tasksList[index] = tMap;
      cached['tasks'] = tasksList;
      _cache.cacheDashboardSchedule(userId, safeSem, cached);
    }
  }

  void _optimisticDelete(String userId, String taskId, String semesterCode) {
    final safeSem = CourseUtils.cleanSemester(semesterCode);
    final cached = _cache.getCachedDashboardSchedule(userId, safeSem);
    if (cached == null || cached['tasks'] == null) return;
    final tasksList = List<dynamic>.from(cached['tasks']);
    tasksList.removeWhere((e) => (e as Map)['id'] == taskId);
    cached['tasks'] = tasksList;
    _cache.cacheDashboardSchedule(userId, safeSem, cached);
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
  final semCode = ref.watch(currentSemesterCodeProvider).value;
  return ref.watch(taskRepositoryProvider).getActiveTasks(user.id, semesterCode: semCode);
}

@Riverpod(keepAlive: true)
Stream<List<Task>> allTasksStream(AllTasksStreamRef ref) {
  final user = ref.watch(currentUserProvider);
  final semCode = ref.watch(currentSemesterCodeProvider).value ?? 'Summer2026';
  if (user == null) return const Stream.empty();
  return ref.watch(taskRepositoryProvider).streamUserTasks(user.id, semCode);
}

@Riverpod(keepAlive: true)
Stream<List<Notification>> userNotifications(UserNotificationsRef ref) {        
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(taskRepositoryProvider).streamNotifications(user.id);        
}
