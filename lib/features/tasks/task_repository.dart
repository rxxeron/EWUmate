import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/task_model.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/connectivity_service.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  final _controller = StreamController<List<Task>>.broadcast();
  StreamSubscription? _subscription;

  // Stream of tasks for real-time updates
  Stream<List<Task>> getTasksStream() {
    final user = _supabase.auth.currentUser;
    
    // Initial fetch from cache
    _emitCachedTasks();

    if (user != null && _subscription == null) {
      // Setup Supabase listener if not already done
      _subscription = _supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .listen((data) {
            final remoteTasks = data.map((d) => Task.fromSupabase(d)).toList();
            OfflineCacheService().cacheTasks(remoteTasks.map((t) => t.toMap()).toList());
            if (!_controller.isClosed) {
              _controller.add(remoteTasks);
            }
          }, onError: (e) {
            debugPrint("TasksStream Supabase Error: $e");
            _subscription?.cancel();
            _subscription = null;
          });
    }

    return _controller.stream;
  }

  void _emitCachedTasks() {
    Future.microtask(() {
      if (!_controller.isClosed) {
        final cachedData = OfflineCacheService().getCachedTasks();
        final cachedTasks =
            cachedData.map((d) => Task.fromMap(d, d['id'] ?? '')).toList();
        _controller.add(cachedTasks);
      }
    });
  }

  Future<void> addTask(Task task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Local update
    final currentTasks = OfflineCacheService().getCachedTasks();
    currentTasks.add(task.toMap());
    await OfflineCacheService().cacheTasks(currentTasks);
    _emitCachedTasks(); // Notify UI immediately

    // Sync if online
    if (await ConnectivityService().isOnline()) {
      try {
        await _supabase.from('tasks').insert(task.toSupabase(user.id));
      } catch (e) {
        debugPrint("Error syncing new task to Supabase: $e");
      }
    } else {
      debugPrint("Offline: New task saved locally, will sync when online.");
    }
  }

  Future<void> updateTask(Task task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Local update
    final currentTasks = OfflineCacheService().getCachedTasks();
    final index = currentTasks.indexWhere((t) => t['id'] == task.id);
    if (index != -1) {
      currentTasks[index] = task.toMap();
      await OfflineCacheService().cacheTasks(currentTasks);
      _emitCachedTasks(); // Notify UI immediately

      // Sync if online
      if (await ConnectivityService().isOnline()) {
        try {
          await _supabase
              .from('tasks')
              .update(task.toSupabase(user.id))
              .eq('id', task.id);
        } catch (e) {
          debugPrint("Error syncing task update to Supabase: $e");
        }
      }
    }
  }

  Future<List<Task>> fetchTasks() async {
    // 1. Return cached data immediately
    final cachedData = OfflineCacheService().getCachedTasks();
    List<Task> cachedTasks = cachedData.map((d) => Task.fromMap(d, d['id'] ?? '')).toList();

    final user = _supabase.auth.currentUser;
    if (user == null) return cachedTasks;

    try {
      final data =
          await _supabase.from('tasks').select().eq('user_id', user.id);

      final remoteTasks = (data as List).map((d) => Task.fromSupabase(d)).toList();
      
      // 2. Update cache with fresh data
      await OfflineCacheService().cacheTasks(remoteTasks.map((t) => t.toMap()).toList());
      
      return remoteTasks;
    } catch (e) {
      debugPrint("Error fetching tasks from Supabase, using cache: $e");
      return cachedTasks;
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    // Local update
    final currentTasks = OfflineCacheService().getCachedTasks();
    final index = currentTasks.indexWhere((t) => t['id'] == taskId);
    if (index != -1) {
      final taskMap = Map<String, dynamic>.from(currentTasks[index]);
      taskMap['isCompleted'] = isCompleted;
      currentTasks[index] = taskMap;
      await OfflineCacheService().cacheTasks(currentTasks);
      _emitCachedTasks(); // Notify UI immediately

      // Sync if online
      if (await ConnectivityService().isOnline()) {
        try {
          await _supabase
              .from('tasks')
              .update({'is_completed': isCompleted}).eq('id', taskId);
        } catch (e) {
          debugPrint("Error syncing task completion to Supabase: $e");
        }
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    // Local update
    final currentTasks = OfflineCacheService().getCachedTasks();
    currentTasks.removeWhere((t) => t['id'] == taskId);
    await OfflineCacheService().cacheTasks(currentTasks);
    _emitCachedTasks(); // Notify UI immediately

    // Sync if online
    if (await ConnectivityService().isOnline()) {
      try {
        await _supabase.from('tasks').delete().eq('id', taskId);
      } catch (e) {
        debugPrint("Error syncing task deletion to Supabase: $e");
      }
    }
  }
}
