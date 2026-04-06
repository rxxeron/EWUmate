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
        debugPrint('[SyncService] Online. Attempting to flush offline queue...');
        flushQueue();
      }
    });
  }

  Future<void> flushQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = _cacheService.getOfflineQueue();
      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      final successfulIds = <int>[];

      for (int i = 0; i < queue.length; i++) {
        final mutation = queue[i] as Map<String, dynamic>;
        bool success = false;

        try {
          if (mutation['type'] == 'task_update') {
            await _supabase.from('tasks').update(mutation['payload']).eq('id', mutation['id']);
            success = true;
          } else if (mutation['type'] == 'task_create') {
            await _supabase.from('tasks').insert(mutation['payload']);
            success = true;
          } else if (mutation['type'] == 'task_delete') {
            await _supabase.from('tasks').delete().eq('id', mutation['id']);
            success = true;
          } else if (mutation['type'] == 'progress_update') {
            await _supabase
                .from('semester_course_marks')
                .update(mutation['payload'])
                .eq('user_id', mutation['payload']['user_id'])
                .eq('semester_code', mutation['payload']['semester_code'])
                .eq('course_code', mutation['payload']['course_code']);
            success = true;
          } else if (mutation['type'] == 'progress_create') {
            await _supabase
                .from('semester_course_marks')
                .insert(mutation['payload']);
            success = true;
          }

          if (success) {
            successfulIds.add(i);
          }
        } catch (e) {
          debugPrint('[SyncService] Failed to sync mutation: $mutation. Error: $e');
        }
      }

      // Remove successful ones
      if (successfulIds.isNotEmpty) {
        final newQueue = List<dynamic>.from(queue);
        for (var index in successfulIds.reversed) {
          newQueue.removeAt(index);
        }
        await _cacheService.clearOfflineQueue(); 
        if (newQueue.isNotEmpty) {
          for (var item in newQueue) {
            await _cacheService.enqueueMutation(item);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
