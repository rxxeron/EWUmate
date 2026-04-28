import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/notification.dart';
import '../providers/supabase_provider.dart';
import 'auth_repository.dart';

part 'task_repository.g.dart';

class TaskRepository {
  final SupabaseClient _supabase;

  TaskRepository(this._supabase);

  Future<List<Task>> getActiveTasks(String userId) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .order('due_date', ascending: true);

    return (response as List).map((e) => Task.fromJson(e)).toList();
  }

  Stream<List<Task>> streamUserTasks(String userId) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('due_date', ascending: true)
        .map((events) => events.map((e) => Task.fromJson(e)).toList());
  }

  Future<Task> createTask(Task task) async {
    final response = await _supabase
        .from('tasks')
        .insert(task.toJson())
        .select()
        .single();
    return Task.fromJson(response);
  }

  Future<Task> updateTask(Task task) async {
    final response = await _supabase
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();
    return Task.fromJson(response);
  }

  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {        
    await _supabase
        .from('tasks')
        .update({'is_completed': isCompleted})
        .eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
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
  return TaskRepository(ref.watch(supabaseClientProvider));
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
