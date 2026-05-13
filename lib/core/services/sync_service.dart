import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';
import '../utils/course_utils.dart';

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

          if (type == 'progress_update' || mutation['action'] == 'save_course_marks') {
            final data = mutation['data'] ?? mutation['payload'] ?? {};
            data.remove('is_new');

            if (data['id'] != null && data['id'].toString().startsWith('new_')) {
              data.remove('id');
            }

            // Normalize course code
            if (data['course_code'] != null) {
              data['course_code'] = CourseUtils.normalize(data['course_code']);
            }

            // Normalize semester code
            if (data['semester_code'] != null) {
              data['semester_code'] = CourseUtils.cleanSemester(data['semester_code']);
            } else if (mutation['semesterCode'] != null) {
              data['semester_code'] = CourseUtils.cleanSemester(mutation['semesterCode']);
            }

            await _supabase.from('semester_course_marks').upsert(
              data,
              onConflict: 'user_id,semester_code,course_code'
            );
            success = true;
          } else if (type == 'task_update') {
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
