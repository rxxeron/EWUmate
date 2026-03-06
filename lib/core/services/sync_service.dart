import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/calendar/academic_repository.dart';
import '../../features/course_browser/course_repository.dart';
import '../../features/dashboard/exception_repository.dart';
import '../../features/tasks/task_repository.dart';
import '../../features/semester_progress/semester_progress_repository.dart';
import '../../features/results/results_repository.dart';
import '../services/offline_cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/ramadan_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = Supabase.instance.client;
  final _academicRepo = AcademicRepository();
  final _courseRepo = CourseRepository();
  final _exceptionRepo = ExceptionRepository();
  final _taskRepo = TaskRepository();
  final _semesterProgressRepo = SemesterProgressRepository();
  final _resultsRepo = ResultsRepository();
  final _cache = OfflineCacheService();
  StreamSubscription? _connectivitySubscription;

  void init() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = ConnectivityService().statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        debugPrint('[SyncService] Network restored. Triggering auto-sync...');
        performFullSync(force: true);
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Performs a full proactive sync of essential data to ensure offline availability.
  /// This should be called on app start or login when online.
  Future<void> performFullSync({bool force = false}) async {
    if (_isSyncing) return;
    if (!(await ConnectivityService().isOnline())) {
      debugPrint('[SyncService] Offline: Skipping proactive sync.');
      return;
    }

    if (!force && _shouldThrottleSync()) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isSyncing = true;
    debugPrint('[SyncService] Starting full proactive sync...');

    try {
      final semesterCode = await _syncAcademicConfig().timeout(const Duration(seconds: 4));
      await _syncUserDataAndProfile().timeout(const Duration(seconds: 4)).catchError((_) => null);
      
      if (semesterCode.isNotEmpty) {
        await _syncCourseDetails(semesterCode).timeout(const Duration(seconds: 5)).catchError((_) => null);
        await _syncCalendarAndHolidays(semesterCode).timeout(const Duration(seconds: 5)).catchError((_) => null);
        await _syncSemesterProgress(semesterCode).timeout(const Duration(seconds: 5)).catchError((_) => null);
      }

      await _syncSchedulesAndTasks().timeout(const Duration(seconds: 5)).catchError((_) => null);

      debugPrint('[SyncService] Proactive sync pass completed.');
      await _cache.setLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('[SyncService] Critical sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  bool _shouldThrottleSync() {
    final lastSync = _cache.getLastSyncTime();
    final currentTasks = _cache.getCachedTasks();
    
    if (lastSync != null && currentTasks.isNotEmpty) {
      final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
      if (hoursSinceSync < 24) {
        debugPrint('[SyncService] Throttled: Last sync was $hoursSinceSync hours ago.');
        return true;
      }
    }
    return false;
  }

  Future<String> _syncAcademicConfig() async {
    try {
      final config = await _academicRepo.getActiveSemesterConfig();
      return config['current_semester_code'] ?? config['active_semester'] ?? 'Spring2026';
    } catch (e) {
      debugPrint('[SyncService] Failed to sync config: $e');
      return 'Spring2026';
    }
  }

  Future<void> _syncUserDataAndProfile() async {
    try {
      await _courseRepo.fetchUserData();
      await _resultsRepo.fetchAcademicProfile();
    } catch (e) {
      debugPrint('[SyncService] Failed to sync user data/profile: $e');
    }
  }

  Future<void> _syncCourseDetails(String semesterCode) async {
    try {
      final userData = await _courseRepo.fetchUserData();
      final enrolledIds = ((userData['enrolled_sections'] as List?) ?? [])
          .map((e) => e.toString())
          .toList();
      if (enrolledIds.isNotEmpty) {
        await _courseRepo.fetchCoursesByIds(semesterCode, enrolledIds);
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync courses: $e');
    }
  }

  Future<void> _syncCalendarAndHolidays(String semesterCode) async {
    try {
      await _academicRepo.fetchHolidays(semesterCode);
    } catch (e) {
      debugPrint('[SyncService] Failed to sync holidays: $e');
    }
  }

  Future<void> _syncSemesterProgress(String semesterCode) async {
    try {
      await _semesterProgressRepo.fetchSemesterProgress(semesterCode);
    } catch (e) {
      debugPrint('[SyncService] Failed to sync progress tasks: $e');
    }
  }

  Future<void> _syncSchedulesAndTasks() async {
    try {
      await _exceptionRepo.fetchExceptions();
      await _taskRepo.fetchTasks();
    } catch (e) {
      debugPrint('[SyncService] Failed to sync exceptions/tasks: $e');
    }
  }
}
