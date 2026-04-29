import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class SyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cacheService = CacheService();
  bool _isSyncing = false;

  void listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile)) {
        if (kDebugMode) debugPrint('[SyncService] Online. Attempting to flush offline queue...');
        flushQueue();
      }
    });
  }

  Future<void> flushQueue() async {
    if (_isSyncing) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isSyncing = true;
    final userId = user.id;

    try {
      final queue = _cacheService.getSyncQueue(userId);
      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      final successfulIndexes = <int>[];

      for (int i = 0; i < queue.length; i++) {
        final mutation = queue[i];
        bool success = false;

        try {
          final payload = mutation['payload'] as Map<String, dynamic>? ?? {};
          final type = mutation['type']?.toString() ?? '';
          final id = mutation['id']?.toString() ?? '';

          if (type == 'task_update') {
            await _supabase.from('tasks').update(payload).eq('id', id);
            success = true;
          } else if (type == 'task_create') {
            await _supabase.from('tasks').insert(payload);
            success = true;
          } else if (type == 'task_delete') {
            await _supabase.from('tasks').delete().eq('id', id);
            success = true;
          } else if (type == 'progress_update') {
            await _supabase
                .from('semester_course_marks')
                .update(payload)
                .eq('user_id', payload['user_id'])
                .eq('semester_code', payload['semester_code'])
                .eq('course_code', payload['course_code']);
            success = true;
          } else if (type == 'progress_create') {
            await _supabase
                .from('semester_course_marks')
                .insert(payload);
            success = true;
          }

          if (success) {
            successfulIndexes.add(i);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[SyncService] Failed to sync mutation: $mutation. Error: $e');
        }
      }

      // 4. Remove successful ones from queue
      if (successfulIndexes.isNotEmpty) {
        final remainingQueue = <Map<String, dynamic>>[];
        for (int i = 0; i < queue.length; i++) {
          if (!successfulIndexes.contains(i)) {
            remainingQueue.add(queue[i]);
          }
        }

        await _cacheService.clearSyncQueue(userId);
        for (var item in remainingQueue) {
          await _cacheService.enqueueMutation(userId, item);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
