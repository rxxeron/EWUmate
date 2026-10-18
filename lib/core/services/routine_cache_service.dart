import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final routineCacheServiceProvider = Provider<RoutineCacheService>((ref) {
  return RoutineCacheService();
});

class CachedRoutineData {
  final Map<String, dynamic> calendar;
  final Map<String, dynamic> weeklyGrid;
  final List<dynamic> exceptions;
  final String checksum;
  final DateTime cachedAt;

  CachedRoutineData({
    required this.calendar,
    required this.weeklyGrid,
    required this.exceptions,
    required this.checksum,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
    'calendar': calendar,
    'weeklyGrid': weeklyGrid,
    'exceptions': exceptions,
    'checksum': checksum,
    'cachedAt': cachedAt.toIso8601String(),
  };

  factory CachedRoutineData.fromJson(Map<String, dynamic> json) => CachedRoutineData(
    calendar: Map<String, dynamic>.from(json['calendar'] ?? {}),
    weeklyGrid: Map<String, dynamic>.from(json['weeklyGrid'] ?? {}),
    exceptions: List<dynamic>.from(json['exceptions'] ?? []),
    checksum: json['checksum']?.toString() ?? '',
    cachedAt: DateTime.tryParse(json['cachedAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

class RoutineCacheService {
  static const String _boxName = 'routine_cache_box';

  Box? _getBox() {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return null;
  }

  /// Calculates a deterministic SHA-256 composite checksum for the 3 pillars
  String calculateChecksum({
    required Map<String, dynamic> calendar,
    required Map<String, dynamic> weeklyGrid,
    required List<dynamic> exceptions,
  }) {
    try {
      // Deterministically sort calendar events
      final eventsList = List<dynamic>.from(calendar['events'] as List? ?? []);
      eventsList.sort((a, b) {
        final aDate = (a['event_date'] ?? a['date'] ?? '').toString();
        final bDate = (b['event_date'] ?? b['date'] ?? '').toString();
        final aTitle = (a['title'] ?? a['name'] ?? '').toString();
        final bTitle = (b['title'] ?? b['name'] ?? '').toString();
        final c = aDate.compareTo(bDate);
        return c != 0 ? c : aTitle.compareTo(bTitle);
      });

      // Deterministically sort exceptions
      final exList = List<dynamic>.from(exceptions);
      exList.sort((a, b) {
        final aKey = "${a['date'] ?? ''}:${a['course_code'] ?? a['courseCode'] ?? ''}:${a['type'] ?? ''}";
        final bKey = "${b['date'] ?? ''}:${b['course_code'] ?? b['courseCode'] ?? ''}:${b['type'] ?? ''}";
        return aKey.compareTo(bKey);
      });

      final buffer = StringBuffer();
      buffer.write(jsonEncode({
        'classes_start_date': calendar['classes_start_date'],
        'classes_end_date': calendar['classes_end_date'],
        'events': eventsList,
      }));
      buffer.write(':::');
      buffer.write(jsonEncode(weeklyGrid));
      buffer.write(':::');
      buffer.write(jsonEncode(exList));

      final bytes = utf8.encode(buffer.toString());
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      if (kDebugMode) debugPrint('[RoutineCacheService] Checksum computation error: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Retrieves cached routine data for user and semester
  CachedRoutineData? getCachedRoutine(String userId, String semesterCode) {
    try {
      final box = _getBox();
      if (box == null) return null;

      final key = 'routine_${userId}_$semesterCode';
      final raw = box.get(key) as String?;
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CachedRoutineData.fromJson(decoded);
    } catch (e) {
      if (kDebugMode) debugPrint('[RoutineCacheService] Error reading cache: $e');
      return null;
    }
  }

  /// Gets stored checksum only
  String? getStoredChecksum(String userId, String semesterCode) {
    try {
      final box = _getBox();
      if (box == null) return null;

      final key = 'checksum_${userId}_$semesterCode';
      return box.get(key) as String?;
    } catch (_) {
      return null;
    }
  }

  /// Gets date string on which alarms were last deployed
  String? getLastScheduledDate(String userId, String semesterCode) {
    try {
      final box = _getBox();
      if (box == null) return null;

      final key = 'last_date_${userId}_$semesterCode';
      return box.get(key) as String?;
    } catch (_) {
      return null;
    }
  }

  /// Evaluates whether rolling 7-day schedule needs to be rebuilt.
  /// Returns TRUE if:
  /// 1. Force reschedule requested (e.g. exception edited in UI)
  /// 2. Checksum differs (calendar, routine, or exceptions edited)
  /// 3. Day rolled forward (e.g. last scheduled date != today)
  bool shouldReschedule({
    required String userId,
    required String semesterCode,
    required String newChecksum,
    required String todayDateStr,
    bool forceReschedule = false,
  }) {
    if (forceReschedule) return true;
    final storedChecksum = getStoredChecksum(userId, semesterCode);
    final lastDate = getLastScheduledDate(userId, semesterCode);

    if (storedChecksum == null || storedChecksum != newChecksum) {
      return true;
    }
    if (lastDate == null || lastDate != todayDateStr) {
      return true;
    }
    return false;
  }

  /// Persists the 3 pillars, checksum, and scheduled date in Hive
  Future<void> saveRoutineCache({
    required String userId,
    required String semesterCode,
    required Map<String, dynamic> calendar,
    required Map<String, dynamic> weeklyGrid,
    required List<dynamic> exceptions,
    required String checksum,
    required String scheduledDateStr,
  }) async {
    try {
      final box = _getBox();
      if (box == null) return;

      final cached = CachedRoutineData(
        calendar: calendar,
        weeklyGrid: weeklyGrid,
        exceptions: exceptions,
        checksum: checksum,
        cachedAt: DateTime.now(),
      );

      final key = 'routine_${userId}_$semesterCode';
      final checksumKey = 'checksum_${userId}_$semesterCode';
      final dateKey = 'last_date_${userId}_$semesterCode';

      await box.put(key, jsonEncode(cached.toJson()));
      await box.put(checksumKey, checksum);
      await box.put(dateKey, scheduledDateStr);
      if (kDebugMode) {
        debugPrint('[RoutineCacheService] Saved 3-pillar cache with checksum: ${checksum.substring(0, 10)}... (Date: $scheduledDateStr)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[RoutineCacheService] Error saving cache: $e');
    }
  }

  /// Clears cache for a given semester
  Future<void> clearRoutineCache(String userId, String semesterCode) async {
    try {
      final box = _getBox();
      if (box == null) return;
      await box.delete('routine_${userId}_$semesterCode');
      await box.delete('checksum_${userId}_$semesterCode');
      await box.delete('last_date_${userId}_$semesterCode');
    } catch (_) {}
  }
}

