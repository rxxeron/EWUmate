import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../logic/exam_sync_logic.dart';
import '../../features/calendar/academic_repository.dart';
import '../../features/tasks/task_repository.dart';

/// Passive service that handles one-time initialization syncs
/// (Notifications are now fully handled by Server-Side pg_cron Edge Functions)
class LifecycleNotificationService {
  static final LifecycleNotificationService _instance =
      LifecycleNotificationService._internal();
  factory LifecycleNotificationService() => _instance;
  LifecycleNotificationService._internal();

  final _supabase = Supabase.instance.client;

  /// Initializes the service and performs one-time syncs.
  Future<void> initialize() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    debugPrint('[LifecycleNotify] Initializing for user ${user.id}');

    await _performSyncs();
  }

  Future<void> _performSyncs() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final academicRepo = AcademicRepository();
      final taskRepo = TaskRepository();

      final semesterCode = await academicRepo.getCurrentSemesterCode();
      if (semesterCode != null) {
        final enrolled = await academicRepo.fetchEnrolledCourses(semesterCode);
        final tasks = await taskRepo.fetchTasks();
        await ExamSyncLogic().syncExams(enrolled, tasks, semesterCode);
        debugPrint('[LifecycleNotify] Exam to Task sync completed.');
      }
    } catch (e) {
      debugPrint('[LifecycleNotify] Sync error: $e');
    }
  }
}
