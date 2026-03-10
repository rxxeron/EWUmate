import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/connectivity_service.dart';

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Stream<Map<String, dynamic>> getScheduleStream(String semesterCode) {
    final user = _supabase.auth.currentUser;
    final controller = StreamController<Map<String, dynamic>>();

    final safeKey = CourseUtils.safeCacheKey('schedule', semesterCode);
    // 1. Initial cached value
    final cachedSchedule =
        OfflineCacheService().getCachedSchedule(safeKey);
    if (cachedSchedule != null) {
      controller.add(cachedSchedule);
    }

    if (user == null) {
      controller.close();
      return controller.stream;
    }

    // 2. Wrap combined stream with error handling and caching
    final scheduleStream = _supabase
        .from('user_schedules')
        .stream(primaryKey: ['user_id', 'semester']).map((data) {
      final filtered = data
          .where((item) =>
              item['user_id'] == user.id && item['semester'] == semesterCode)
          .toList();
      return filtered.isNotEmpty ? filtered.first : <String, dynamic>{};
    });

    final exceptionsStream = _supabase
        .from('schedule_exceptions')
        .stream(primaryKey: ['id']).map((data) =>
            data.where((item) => item['user_id'] == user.id).toList());

    final subscription =
        DataMerger.combine(scheduleStream, exceptionsStream).listen(
      (mergedData) {
        // Update cache
        OfflineCacheService().cacheSchedule(safeKey, mergedData);
        controller.add(mergedData);
      },
      onError: (e) {
        debugPrint("Schedule stream error (likely offline): $e");
      },
    );

    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  /// Fetches the schedule data a single time using REST instead of WebSockets.
  /// Use this for screens that don't need realtime or when WebSockets fail.
  Future<Map<String, dynamic>> getScheduleFuture(String semesterCode) async {
    final safeKey = CourseUtils.safeCacheKey('schedule', semesterCode);
    // 1. Try cache first
    final cached = OfflineCacheService().getCachedSchedule(safeKey);
    if (cached != null) {
      // Also fetch exceptions from cache if available
      final cachedEx = OfflineCacheService().getCachedExceptions();
      cached['exceptions'] = cachedEx;
      
      // Refresh in background if online
      _refreshScheduleInBackground(semesterCode);
      
      return cached;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {};
    }

    // 2. Fetch from Supabase only if online
    if (await ConnectivityService().isOnline()) {
      try {
        final scheduleResult = await _supabase
            .from('user_schedules')
            .select()
            .eq('user_id', user.id)
            .eq('semester', semesterCode)
            .maybeSingle();
        
        final Map<String, dynamic> merged = Map<String, dynamic>.from(scheduleResult ?? {});

        final exceptionsResult = await _supabase
            .from('schedule_exceptions')
            .select()
            .eq('user_id', user.id);
        
        final exceptionsList = List<Map<String, dynamic>>.from(exceptionsResult as List? ?? []);
        merged['exceptions'] = exceptionsList;
        
        await OfflineCacheService().cacheSchedule(safeKey, merged);
        await OfflineCacheService().cacheExceptions(exceptionsList);
        
        return merged;
      } catch (e) {
        debugPrint('[DashboardRepo] Error fetching schedule future: $e');
      }
    }

    return {};
  }

  void _refreshScheduleInBackground(String semesterCode) async {
    if (!(await ConnectivityService().isOnline())) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final scheduleResult = await _supabase
          .from('user_schedules')
          .select()
          .eq('user_id', user.id)
          .eq('semester', semesterCode)
          .maybeSingle();
      
      if (scheduleResult != null) {
        final exceptionsResult = await _supabase
            .from('schedule_exceptions')
            .select()
            .eq('user_id', user.id);
        
        final exceptionsList = List<Map<String, dynamic>>.from(exceptionsResult as List? ?? []);
        final Map<String, dynamic> merged = Map<String, dynamic>.from(scheduleResult);
        merged['exceptions'] = exceptionsList;

        final safeKey = CourseUtils.safeCacheKey('schedule', semesterCode);
        await OfflineCacheService().cacheSchedule(safeKey, merged);
        await OfflineCacheService().cacheExceptions(exceptionsList);
        debugPrint("[DashboardRepo] Schedule refreshed in background.");
      }
    } catch (_) {}
  }
}

class DataMerger {
  static Stream<Map<String, dynamic>> combine(
      Stream<Map<String, dynamic>> scheduleStream,
      Stream<List<Map<String, dynamic>>> exceptionsStream) {
    return StreamBuilderLike.combine2(scheduleStream, exceptionsStream,
        (scheduleData, exceptionsList) {
      // 1. Prepare base schedule data
      final Map<String, dynamic> merged = Map.from(scheduleData);

      // 2. Merge exceptions
      // In Firestore, exceptions were a subcollection merged into 'exceptions' list.
      // Here we do the same.
      // We explicitly cast to List<dynamic> to ensure mutability if needed, though we just replace it.

      // Note: 'exceptions' field might not exist in user_schedules table (we removed it in valid schema),
      // but if we had it, we'd append. Since we don't, we just use the streamed list.
      merged['exceptions'] = exceptionsList;

      return merged;
    });
  }
}

// Simple helper to combine two streams without rxdart
class StreamBuilderLike {
  static Stream<T> combine2<A, B, T>(
      Stream<A> streamA, Stream<B> streamB, T Function(A, B) combiner) {
    // ignore: close_sinks
    final controller = StreamController<T>();
    A? lastA;
    B? lastB;
    bool hasA = false;
    bool hasB = false;

    void update() {
      // Logic: If we have A, we can emit even if B is missing (defaults to empty list)
      if (hasA) {
        try {
          controller.add(combiner(lastA as A, (lastB ?? []) as B));
        } catch (e) {
          debugPrint("DataMerger combined error: $e");
        }
      }
    }

    final subA = streamA.listen(
        (data) {
          lastA = data;
          hasA = true;
          update();
        },
        onError: (e) => debugPrint("StreamA error: $e"));

    final subB = streamB.listen(
        (data) {
          lastB = data;
          hasB = true;
          update();
        },
        onError: (e) => debugPrint("StreamB error: $e"));

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };

    return controller.stream;
  }
}
