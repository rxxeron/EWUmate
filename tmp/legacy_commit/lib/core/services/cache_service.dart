import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cache_service.g.dart';

class CacheService {
  static const String _profileBox = 'profile_box';
  static const String _dashboardBox = 'dashboard_box';
  static const String _scheduleBox = 'schedule_box';

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_profileBox);
      await Hive.openBox(_dashboardBox);
      await Hive.openBox(_scheduleBox);
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
  }
}

@Riverpod(keepAlive: true)
CacheService cacheService(CacheServiceRef ref) {
  return CacheService();
}
