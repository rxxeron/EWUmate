import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/connectivity_service.dart';

class ExceptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  /// Fetch all active exceptions for the user
  Future<List<Map<String, dynamic>>> fetchExceptions() async {
    // 1. Get cached data
    final cached = OfflineCacheService().getCachedExceptions();

    if (_uid == null) {
      return cached;
    }

    // 2. If online, refresh
    if (await ConnectivityService().isOnline()) {
      try {
        final data = await _supabase
            .from('schedule_exceptions')
            .select()
            .eq('user_id', _uid!);

        final exceptions = List<Map<String, dynamic>>.from(data);
        // 3. Update cache
        await OfflineCacheService().cacheExceptions(exceptions);
        return exceptions;
      } catch (e) {
        debugPrint('[ExceptionRepo] Error refreshing exceptions: $e');
      }
    }

    return cached;
  }

  /// Add a cancellation exception
  Future<void> addCancellation(String date, String courseCode,
      {bool pendingMakeup = false}) async {
    if (_uid == null) {
      return;
    }

    final newException = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': _uid,
      'type': 'cancel',
      'date': date,
      'course_code': courseCode,
      'metadata': {'pendingMakeup': pendingMakeup},
    };

    // 1. Local Update
    final current = OfflineCacheService().getCachedExceptions();
    current.add(newException);
    await OfflineCacheService().cacheExceptions(current);

    // 2. Sync if online
    if (await ConnectivityService().isOnline()) {
      try {
        await _supabase.from('schedule_exceptions').insert({
          'user_id': _uid,
          'type': 'cancel',
          'date': date,
          'course_code': courseCode,
          'metadata': {'pendingMakeup': pendingMakeup},
        });
      } catch (e) {
        debugPrint('[ExceptionRepo] Error syncing cancellation: $e');
      }
    } else {
      debugPrint('Offline: Cancellation saved locally.');
    }
  }

  /// Add a makeup class exception
  Future<void> addMakeupClass({
    required String date,
    required String courseCode,
    required String courseName,
    required String startTime,
    required String endTime,
    required String room,
  }) async {
    if (_uid == null) {
      return;
    }

    final newException = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': _uid,
      'type': 'makeup',
      'date': date,
      'course_code': courseCode,
      'course_name': courseName,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    };

    // 1. Local Update
    final current = OfflineCacheService().getCachedExceptions();
    current.add(newException);
    await OfflineCacheService().cacheExceptions(current);

    // 2. Sync if online
    if (await ConnectivityService().isOnline()) {
      try {
        await _supabase.from('schedule_exceptions').insert({
          'user_id': _uid,
          'type': 'makeup',
          'date': date,
          'course_code': courseCode,
          'course_name': courseName,
          'start_time': startTime,
          'end_time': endTime,
          'room': room,
        });
      } catch (e) {
        debugPrint('[ExceptionRepo] Error syncing makeup class: $e');
      }
    } else {
      debugPrint('Offline: Makeup class saved locally.');
    }
  }

  /// Update an existing makeup class exception
  Future<void> updateMakeupClass({
    required String id,
    required String date,
    required String startTime,
    required String endTime,
    required String room,
  }) async {
    if (_uid == null) {
      return;
    }

    // 1. Local Update
    final current = OfflineCacheService().getCachedExceptions();
    final index = current.indexWhere((e) => e['id'].toString() == id);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(current[index]);
      updated['date'] = date;
      updated['start_time'] = startTime;
      updated['end_time'] = endTime;
      updated['room'] = room;
      current[index] = updated;
      await OfflineCacheService().cacheExceptions(current);
    }

    // 2. Sync if online (skip if temp ID)
    if (id.startsWith('temp_')) {
      return;
    }

    if (await ConnectivityService().isOnline()) {
      try {
        await _supabase.from('schedule_exceptions').update({
          'date': date,
          'start_time': startTime,
          'end_time': endTime,
          'room': room,
          'type': 'makeup',
        }).eq('id', id);
      } catch (e) {
        debugPrint('[ExceptionRepo] Error updating makeup class: $e');
      }
    }
  }

  /// Remove an exception (e.g. undo cancel)
  Future<void> removeException(String id) async {
    if (_uid == null) {
      return;
    }

    // 1. Local Update
    final current = OfflineCacheService().getCachedExceptions();
    current.removeWhere((e) => e['id'].toString() == id);
    await OfflineCacheService().cacheExceptions(current);

    // 2. Sync if online (skip if temp ID)
    if (id.startsWith('temp_')) {
      return;
    }

    if (await ConnectivityService().isOnline()) {
      try {
        await _supabase.from('schedule_exceptions').delete().eq('id', id);
      } catch (e) {
        debugPrint('[ExceptionRepo] Error removing exception: $e');
      }
    }
  }

  Future<String?> findExceptionId(
      String date, String courseCode, String type) async {
    // Check cache first
    final current = OfflineCacheService().getCachedExceptions();
    try {
      final match = current.firstWhere((e) =>
          e['date'] == date &&
          e['course_code'] == courseCode &&
          e['type'] == type);
      return match['id']?.toString();
    } catch (_) {}

    if (_uid == null) {
      return null;
    }
    try {
      final data = await _supabase
          .from('schedule_exceptions')
          .select('id')
          .eq('user_id', _uid!)
          .eq('date', date)
          .eq('course_code', courseCode)
          .eq('type', type)
          .maybeSingle();

      return data?['id']?.toString();
    } catch (e) {
      debugPrint('[ExceptionRepo] Error finding exception ID: $e');
      return null;
    }
  }
}
