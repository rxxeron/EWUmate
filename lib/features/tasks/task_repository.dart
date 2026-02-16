import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/task_model.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;

  // Stream of tasks for real-time updates
  Stream<List<Task>> getTasksStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) => data.map((d) => Task.fromSupabase(d)).toList());
  }

  Future<void> addTask(Task task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _supabase.from('tasks').insert(task.toSupabase(user.id));
  }

  Future<void> updateTask(Task task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _supabase
        .from('tasks')
        .update(task.toSupabase(user.id))
        .eq('id', task.id);
  }

  Future<List<Task>> fetchTasks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data =
          await _supabase.from('tasks').select().eq('user_id', user.id);

      return (data as List).map((d) => Task.fromSupabase(d)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('tasks')
        .update({'is_completed': isCompleted}).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('tasks').delete().eq('id', taskId);
  }
}
