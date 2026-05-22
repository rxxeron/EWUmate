import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cache_service.g.dart';

class CacheService {
  static const String _profileBox = 'profile_box';
  static const String _dashboardBox = 'dashboard_box';
  static const String _scheduleBox = 'schedule_box';
  static const String _syncQueueBox = 'sync_queue_box';
  static const String _semesterProgressBox = 'semester_progress_box';
  static const String _notificationsBox = 'notifications_box';

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox('course_catalog');
      await Hive.openBox(_profileBox);
      await Hive.openBox(_dashboardBox);
      await Hive.openBox(_scheduleBox);
      await Hive.openBox(_syncQueueBox);
      await Hive.openBox(_semesterProgressBox);
      await Hive.openBox(_notificationsBox);
      await Hive.openBox(_authBox);
      await Hive.openBox('faculty');
      if (kDebugMode) debugPrint('[CacheService] Successfully initialized Hive boxes.');
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] Failed to initialize Hive: $e');
    }
  }

  // Generic write
  Future<void> setMapData(
    String boxName,
    String key,
    Map<String, dynamic> data,
  ) async {
    try {
      final box = Hive.box(boxName);
      await box.put(key, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] Write error in $boxName: $e');
    }
  }

  // Generic read
  Map<String, dynamic>? getMapData(String boxName, String key) {
    try {
      final box = Hive.box(boxName);
      final dataStr = box.get(key) as String?;
      if (dataStr != null) {
        return jsonDecode(dataStr) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] Read error in $boxName: $e');
    }
    return null;
  }

  // Type specific accessors
  Future<void> cacheProfile(String userId, Map<String, dynamic> data) =>
      setMapData(_profileBox, userId, data);
  Map<String, dynamic>? getCachedProfile(String userId) =>
      getMapData(_profileBox, userId);

  Future<void> cacheDashboardAnalytics(
    String userId,
    String semesterCode,
    Map<String, dynamic> data,
  ) => setMapData(_dashboardBox, '${userId}_${semesterCode}_analytics', data);

  Map<String, dynamic>? getCachedDashboardAnalytics(String userId, String semesterCode) =>
      getMapData(_dashboardBox, '${userId}_${semesterCode}_analytics');

  Future<void> cacheDashboardSchedule(
    String userId,
    String semesterCode,
    Map<String, dynamic> data,
  ) {
    data['_cache_updated_at'] = DateTime.now().toIso8601String();
    return setMapData(_dashboardBox, '${userId}_${semesterCode}_schedule', data);
  }

  Map<String, dynamic>? getCachedDashboardSchedule(String userId, String semesterCode) =>
      getMapData(_dashboardBox, '${userId}_${semesterCode}_schedule');

  Future<void> invalidateDashboardSchedule(String userId, String semesterCode) async {
    try {
      final box = Hive.box(_dashboardBox);
      await box.delete('${userId}_${semesterCode}_schedule');
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] invalidateDashboardSchedule error: $e');
    }
  }

  Future<void> clearAll() async {
    await Hive.box(_profileBox).clear();
    await Hive.box(_dashboardBox).clear();
    await Hive.box(_scheduleBox).clear();
    await Hive.box(_syncQueueBox).clear();
    await Hive.box(_semesterProgressBox).clear();
    await Hive.box(_notificationsBox).clear();
    if (Hive.isBoxOpen(_authBox)) await Hive.box(_authBox).clear();
    // Note: We keep global data like 'course_catalog' and 'faculty' intact
  }

  // --- Offline Sync Queue ---
  Future<void> enqueueMutation(String userId, Map<String, dynamic> mutation) async {
    final box = Hive.box(_syncQueueBox);
    final key = '${userId}_queue';
    final existingDataStr = box.get(key) as String?;
    
    List<dynamic> queue = [];
    if (existingDataStr != null) {
      queue = jsonDecode(existingDataStr) as List<dynamic>;
    }
    
    queue.add(mutation);
    await box.put(key, jsonEncode(queue));
    if (kDebugMode) debugPrint('[CacheService] Enqueued mutation: ${mutation['action']}');
  }

  List<Map<String, dynamic>> getSyncQueue(String userId) {
    final box = Hive.box(_syncQueueBox);
    final key = '${userId}_queue';
    final existingDataStr = box.get(key) as String?;
    
    if (existingDataStr != null) {
      final decoded = jsonDecode(existingDataStr) as List<dynamic>;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<void> removeQueueItemByMatch(String userId, bool Function(Map<String, dynamic>) test) async {
    final box = Hive.box(_syncQueueBox);
    final key = '${userId}_queue';
    final existingDataStr = box.get(key) as String?;
    
    if (existingDataStr != null) {
      List<dynamic> queue = jsonDecode(existingDataStr);
      queue.removeWhere((item) => test(item as Map<String, dynamic>));
      await box.put(key, jsonEncode(queue));
    }
  }

  Future<void> removeQueueItem(String userId, String id) async {
    await removeQueueItemByMatch(userId, (item) {
      if (item.containsKey('taskId') && item['taskId'] == id) return true;
      if (item.containsKey('task') && item['task']['id'] == id) return true;
      if (item.containsKey('data') && item['data']['course_code'] == id) return true;
      return false;
    });
  }

  Future<void> clearSyncQueue(String userId) async {
    final box = Hive.box(_syncQueueBox);
    await box.delete('${userId}_queue');
  }

  void clearEnrollmentCache(String userId, String semesterCode) {
    Hive.box(_dashboardBox).delete('enrollment_codes_${userId}_$semesterCode');
    Hive.box(_dashboardBox).delete('available_courses_$semesterCode');
  }

  void clearSemesterProgressCache(String userId, String semesterCode) {
    Hive.box(_semesterProgressBox).delete('marks_${userId}_$semesterCode');
  }

  // --- Auth Persistence for Zero-Wait Entry ---
  static const String _authBox = 'auth_box';
  Future<void> saveLastUserId(String userId) async {
    final box = await Hive.openBox(_authBox);
    await box.put('last_user_id', userId);
  }

  String? getLastUserId() {
    if (!Hive.isBoxOpen(_authBox)) return null;
    return Hive.box(_authBox).get('last_user_id') as String?;
  }
}

@Riverpod(keepAlive: true)
CacheService cacheService(CacheServiceRef ref) {
  return CacheService();
}
