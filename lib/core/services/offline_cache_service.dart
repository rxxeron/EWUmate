import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  // Box names
  static const String _tasksBoxName = 'tasks_box';
  static const String _semesterBoxName = 'semester_box';
  static const String _ramadanBoxName = 'ramadan_box';
  static const String _profileBoxName = 'profile_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _metadataBoxName = 'metadata_box';

  // Cache Version (Increment this when structural changes occur)
  static const int _currentVersion = 2; 

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Open all necessary boxes with a timeout
    try {
      await Future.wait([
        Hive.openBox(_tasksBoxName),
        Hive.openBox(_semesterBoxName),
        Hive.openBox(_ramadanBoxName),
        Hive.openBox(_profileBoxName),
        Hive.openBox(_settingsBoxName),
        Hive.openBox(_metadataBoxName),
      ]).timeout(const Duration(seconds: 4));
      
      await _handleMigration();
      debugPrint('OfflineCacheService: Hive initialized and boxes opened.');
    } catch (e) {
      debugPrint('OfflineCacheService: Hive initialization error or timeout $e');
    }
  }

  Future<void> _handleMigration() async {
    final settings = Hive.box(_settingsBoxName);
    final oldVersion = settings.get('cache_version', defaultValue: 1) as int;

    if (oldVersion < _currentVersion) {
      debugPrint('OfflineCacheService: Migrating cache from v$oldVersion to v$_currentVersion');
      
      // For version 2, we changed key naming to be strictly lowercase and standardized.
      // Easiest and safest way to clear stale data is to wipe the semester and metadata boxes.
      await Hive.box(_semesterBoxName).clear();
      await Hive.box(_metadataBoxName).clear();
      await Hive.box(_tasksBoxName).clear();
      
      await settings.put('cache_version', _currentVersion);
      debugPrint('OfflineCacheService: Stale semester cache cleared for new standardization.');
    }
  }

  // --- Task Methods ---
  Future<void> cacheTasks(List<Map<String, dynamic>> tasks) async {
    final box = Hive.box(_tasksBoxName);
    await box.put('all_tasks', tasks);
  }

  List<Map<String, dynamic>> getCachedTasks() {
    final box = Hive.box(_tasksBoxName);
    final data = box.get('all_tasks');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // --- Semester/Degree Methods ---
  Future<void> cacheAcademicProfile(Map<String, dynamic> profile) async {
    final box = Hive.box(_profileBoxName);
    await box.put('academic_profile', profile);
  }

  Map<String, dynamic>? getCachedAcademicProfile() {
    final box = Hive.box(_profileBoxName);
    final data = box.get('academic_profile');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  // --- Ramadan Methods ---
  Future<void> cacheRamadanTimetable(List<Map<String, dynamic>> timetable) async {
    final box = Hive.box(_ramadanBoxName);
    await box.put('timetable', timetable);
  }

  List<Map<String, dynamic>> getCachedRamadanTimetable() {
    final box = Hive.box(_ramadanBoxName);
    final data = box.get('timetable');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> clearRamadanCache() async {
    final box = Hive.box(_ramadanBoxName);
    await box.clear();
  }

  // --- Dashboard Data Methods ---
  Future<void> cacheDashboardData(Map<String, dynamic> data) async {
    final box = Hive.box(_semesterBoxName);
    await box.put('dashboard_summary', data);
  }

  Map<String, dynamic>? getCachedDashboardData() {
    final box = Hive.box(_semesterBoxName);
    final data = box.get('dashboard_summary');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  // --- Semester Progress Methods ---
  Future<void> cacheSemesterProgress(String semesterCode, List<Map<String, dynamic>> progress) async {
    final box = Hive.box(_semesterBoxName);
    await box.put('progress_$semesterCode', progress);
  }

  List<Map<String, dynamic>> getCachedSemesterProgress(String semesterCode) {
    final box = Hive.box(_semesterBoxName);
    final data = box.get('progress_$semesterCode');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // --- Schedule Methods ---
  Future<void> cacheSchedule(String semesterCode, Map<String, dynamic> schedule) async {
    final box = Hive.box(_semesterBoxName);
    await box.put('schedule_$semesterCode', schedule);
  }

  Map<String, dynamic>? getCachedSchedule(String semesterCode) {
    final box = Hive.box(_semesterBoxName);
    final data = box.get('schedule_$semesterCode');
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  // --- Academic Config Methods ---
  Future<void> cacheAcademicConfig(Map<String, dynamic> config) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('academic_config', config);
  }

  Map<String, dynamic>? getCachedAcademicConfig() {
    final box = Hive.box(_settingsBoxName);
    final data = box.get('academic_config');
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  // --- Enrollment Methods ---
  Future<void> cacheEnrolledSections(List<String> sections) async {
    final box = Hive.box(_profileBoxName);
    await box.put('enrolled_sections', sections);
  }

  List<String> getCachedEnrolledSections() {
    final box = Hive.box(_profileBoxName);
    final data = box.get('enrolled_sections');
    if (data == null) return [];
    return List<String>.from(data);
  }

  // --- Course Metadata Methods ---
  Future<void> cacheCourseDetails(String docId, Map<String, dynamic> details) async {
    final box = Hive.box(_metadataBoxName);
    await box.put(docId, details);
  }

  Map<String, dynamic>? getCachedCourseDetails(String docId) {
    final box = Hive.box(_metadataBoxName);
    final data = box.get(docId);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  // --- Semester Summary Map Methods ---
  Future<void> cacheSemesterSummaryMap(String semesterCode, Map<String, dynamic> summary) async {
    final box = Hive.box(_semesterBoxName);
    await box.put('summary_$semesterCode', summary);
  }

  Map<String, dynamic>? getCachedSemesterSummaryMap(String semesterCode) {
    final box = Hive.box(_semesterBoxName);
    final data = box.get('summary_$semesterCode');
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  // --- Holiday/Calendar Methods ---
  Future<void> cacheHolidays(String semesterCode, List<Map<String, dynamic>> holidays) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('holidays_$semesterCode', holidays);
  }

  List<Map<String, dynamic>> getCachedHolidays(String semesterCode) {
    final box = Hive.box(_settingsBoxName);
    final data = box.get('holidays_$semesterCode');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // --- Schedule Exception Methods ---
  Future<void> cacheExceptions(List<Map<String, dynamic>> exceptions) async {
    final box = Hive.box(_semesterBoxName);
    await box.put('schedule_exceptions', exceptions);
  }

  List<Map<String, dynamic>> getCachedExceptions() {
    final box = Hive.box(_semesterBoxName);
    final data = box.get('schedule_exceptions');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // --- Sync Metadata Methods ---
  Future<void> setLastSyncTime(DateTime time) async {
    final box = Hive.box(_metadataBoxName);
    await box.put('last_full_sync', time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final box = Hive.box(_metadataBoxName);
    final data = box.get('last_full_sync');
    if (data == null) return null;
    return DateTime.tryParse(data.toString());
  }
  
  // --- User Metadata Methods ---
  Future<void> cacheUserMetadata(Map<String, dynamic> metadata) async {
    final box = Hive.box(_profileBoxName);
    await box.put('user_metadata', metadata);
  }

  Map<String, dynamic>? getCachedUserMetadata() {
    final box = Hive.box(_profileBoxName);
    final data = box.get('user_metadata');
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  // --- Generic Methods ---
  Future<void> clearAllCache() async {
    await Hive.deleteFromDisk();
    await init();
  }
}
