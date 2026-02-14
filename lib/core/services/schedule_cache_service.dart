import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleCacheService {
  static const String _statsKey = 'cached_academic_stats';

  Future<void> cacheStats(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, _encodeJson(stats));
  }

  Future<Map<String, dynamic>?> getCachedStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_statsKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearStatsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
  }

  // --- Schedule Cache ---
  String _getScheduleKey(String? semester) =>
      semester != null ? 'cached_schedule_$semester' : 'cached_schedule';

  Future<void> cacheSchedule(Map<String, dynamic> schedule,
      [String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getScheduleKey(semester), _encodeJson(schedule));
  }

  Future<Map<String, dynamic>?> getCachedSchedule([String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_getScheduleKey(semester));
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache([String? semester]) async {
    // Generic clear or schedule specific? Using for schedule in dashboard
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getScheduleKey(semester));
  }

  // --- Semester Progress Cache ---
  String _getProgressKey(String? semester) => semester != null
      ? 'cached_semester_progress_$semester'
      : 'cached_semester_progress';
  String _getEnrolledKey(String? semester) => semester != null
      ? 'cached_enrolled_courses_$semester'
      : 'cached_enrolled_courses';
  String _getMarksKey(String? semester) =>
      semester != null ? 'cached_marks_$semester' : 'cached_marks';

  Future<void> cacheProgress(Map<String, dynamic> data,
      [String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getProgressKey(semester), _encodeJson(data));
  }

  Future<Map<String, dynamic>?> getCachedProgress([String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_getProgressKey(semester));
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearProgressCache([String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getProgressKey(semester));
  }

  Future<void> cacheEnrolledCourses(List<String> ids,
      [String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_getEnrolledKey(semester), ids);
  }

  Future<List<String>?> getCachedEnrolledCourses([String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_getEnrolledKey(semester));
  }

  Future<void> cacheMarks(Map<String, String> marks, [String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getMarksKey(semester), _encodeJson(marks));
  }

  Future<Map<String, String>?> getCachedMarks([String? semester]) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_getMarksKey(semester));
    if (jsonStr == null) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return null;
    }
  }

  // --- Tasks Cache ---
  static const String _tasksKey = 'cached_tasks';

  Future<void> cacheTasks(List<Map<String, dynamic>> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasksKey, _encodeJson(tasks));
  }

  String _encodeJson(dynamic value) {
    return jsonEncode(_sanitizeValue(value));
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), _sanitizeValue(val)));
    }
    if (value is List) {
      return value.map(_sanitizeValue).toList();
    }
    return value;
  }

  Future<List<Map<String, dynamic>>?> getCachedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_tasksKey);
    if (jsonStr == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return null;
    }
  }
}
