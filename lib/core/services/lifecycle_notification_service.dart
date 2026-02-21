import 'dart:async';
import 'notification_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../logic/exam_sync_logic.dart';
import '../../features/calendar/academic_repository.dart';
import '../../features/tasks/task_repository.dart';

/// Passive service that handles one-time initialization tasks
/// and relies on [RealtimeNotificationService] for scheduled alerts.
class LifecycleNotificationService {
  static final LifecycleNotificationService _instance =
      LifecycleNotificationService._internal();
  factory LifecycleNotificationService() => _instance;
  LifecycleNotificationService._internal();

  final _supabase = Supabase.instance.client;

  /// Initializes the service and performs one-time syncs.
  /// No longer starts periodic timers to preserve battery.
  Future<void> initialize() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    debugPrint('[LifecycleNotify] Passive initialization for user ${user.id}');

    // We still perform some one-time syncs on launch for immediate data freshness,
    // but the actual "Reminders" are now handled by the Azure Cloud Scheduler.
    await _performSyncs();
  }

  Future<void> _performSyncs() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Ensure Final Exams are synced to Tasks for visibility (one-time on launch)
      // The cloud also does this, but keeping it here for immediate offline feedback.
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
