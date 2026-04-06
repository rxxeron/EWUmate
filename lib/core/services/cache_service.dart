import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_profileBox);
      await Hive.openBox(_dashboardBox);
      await Hive.openBox(_scheduleBox);
      await Hive.openBox(_syncQueueBox);
      debugPrint('[CacheService] Successfully initialized Hive boxes.');
    } catch (e) {
      debugPrint('[CacheService] Failed to initialize Hive: $e');
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
      debugPrint('[CacheService] Write error in $boxName: $e');
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
      debugPrint('[CacheService] Read error in $boxName: $e');
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
    Map<String, dynamic> data,
  ) => setMapData(_dashboardBox, '${userId}_analytics', data);
  Map<String, dynamic>? getCachedDashboardAnalytics(String userId) =>
      getMapData(_dashboardBox, '${userId}_analytics');

  Future<void> cacheDashboardSchedule(
    String userId,
    Map<String, dynamic> data,
  ) => setMapData(_dashboardBox, '${userId}_schedule', data);
  Map<String, dynamic>? getCachedDashboardSchedule(String userId) =>
      getMapData(_dashboardBox, '${userId}_schedule');

  Future<void> clearAll() async {
    await Hive.box(_profileBox).clear();
    await Hive.box(_dashboardBox).clear();
    await Hive.box(_scheduleBox).clear();
    await Hive.box(_syncQueueBox).clear();
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
    debugPrint('[CacheService] Enqueued mutation: ${mutation['action']}');
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
}

@Riverpod(keepAlive: true)
CacheService cacheService(CacheServiceRef ref) {
  return CacheService();
}
