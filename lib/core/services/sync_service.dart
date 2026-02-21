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

    // 24-hour throttle check
    if (!force) {
      final lastSync = _cache.getLastSyncTime();
      final currentTasks = _cache.getCachedTasks();
      
      // If we have data and it's fresh, we can skip.
      // But if we have NO tasks, we should always try to sync once if online.
      if (lastSync != null && currentTasks.isNotEmpty) {
        final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
        if (hoursSinceSync < 24) {
          debugPrint('[SyncService] Throttled: Last sync was $hoursSinceSync hours ago.');
          return;
        }
      }
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isSyncing = true;
    debugPrint('[SyncService] Starting full proactive sync...');

    try {
      // 1. Academic Config
      String semesterCode = '';
      try {
        final config = await _academicRepo.getActiveSemesterConfig();
        semesterCode = config['current_semester_code'] ?? config['active_semester'] ?? '';
      } catch (e) {
        debugPrint('[SyncService] Failed to sync config: $e');
      }
      
      if (semesterCode.isEmpty) {
        // Try fallback if possible
        semesterCode = 'Spring2026'; 
      }

      // 2. User Profile & Enrolled Sections
      List<String> enrolledIds = [];
      try {
        final userData = await _courseRepo.fetchUserData();
        enrolledIds = ((userData['enrolled_sections'] as List?) ?? [])
            .map((e) => e.toString())
            .toList();
            
        // Also sync academic stats (CGPA, etc. for Profile Screen)
        try {
          await _resultsRepo.fetchAcademicProfile();
        } catch (e) {
          debugPrint('[SyncService] Failed to sync academic stats: $e');
        }
      } catch (e) {
        debugPrint('[SyncService] Failed to sync user data: $e');
      }

      // 3. Course Details (Current)
      if (enrolledIds.isNotEmpty) {
        try {
          await _courseRepo.fetchCoursesByIds(semesterCode, enrolledIds);
        } catch (e) {
          debugPrint('[SyncService] Failed to sync courses: $e');
        }
      }

      // 4. Calendar/Holidays
      try {
        await _academicRepo.fetchHolidays(semesterCode);
      } catch (e) {
        debugPrint('[SyncService] Failed to sync holidays: $e');
      }

      // 5. Schedule Exceptions
      try {
        await _exceptionRepo.fetchExceptions();
      } catch (e) {
        debugPrint('[SyncService] Failed to sync exceptions: $e');
      }
      
      // 6. Tasks
      try {
        await _taskRepo.fetchTasks();
      } catch (e) {
        debugPrint('[SyncService] Failed to sync tasks: $e');
      }

      // 7. Semester Progress (Marks)
      try {
        await _semesterProgressRepo.fetchSemesterProgress(semesterCode);
      } catch (e) {
        debugPrint('[SyncService] Failed to sync progress tasks: $e');
      }

      // 8. Ramadan Timetable (Removed from cache per request)
      /*
      try {
        await RamadanService.getFullTimetable();
      } catch (e) {
        debugPrint('[SyncService] Failed to sync Ramadan: $e');
      }
      */

      debugPrint('[SyncService] Proactive sync pass completed.');
      await _cache.setLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('[SyncService] Critical sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
