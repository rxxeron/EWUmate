import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';
import '../../features/calendar/academic_repository.dart';
import '../../features/course_browser/course_repository.dart';
import '../services/connectivity_service.dart';

class ScheduleService {
  final _supabase = Supabase.instance.client;
  final _courseRepo = CourseRepository();
  final _academicRepo = AcademicRepository();

  /// Synchronizes the user's weekly schedule for a given semester based on enrolled section IDs.
  /// ONLY runs if the semester is the current active semester.
  Future<void> syncUserSchedule(String semester, List<String> sectionIds) async {
    if (!(await ConnectivityService().isOnline())) {
      debugPrint('[ScheduleService] Offline: Skipping remote schedule sync.');
      return;
    }
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('[ScheduleService] User not logged in, skipping sync.');
      return;
    }

    // Restriction: Only sync for ACTIVE semesters
    final activeSemesters = await _academicRepo.getActiveSemesterCodes();
    final cleanTarget = semester.replaceAll(' ', '');
 
    if (!activeSemesters.any((s) => s.replaceAll(' ', '') == cleanTarget)) {
      debugPrint('[ScheduleService] Skipping sync for $semester - not an active semester ($activeSemesters).');
      return;
    }

    if (sectionIds.isEmpty) {
      debugPrint('[ScheduleService] No sections provided, clearing schedule for $semester.');
      try {
        await _supabase.from('user_schedules').upsert({
          'user_id': user.id,
          'semester': semester.replaceAll(' ', ''),
          'weekly_template': <String, dynamic>{},
          'last_updated': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, semester');
      } catch (e) {
        debugPrint('[ScheduleService] Error clearing schedule: $e');
      }
      return;
    }

    try {
      debugPrint('[ScheduleService] Syncing schedule for $semester with ${sectionIds.length} sections.');
      
      // 1. Fetch full Course details (handles dynamic table internally)
      final courses = await _courseRepo.fetchCoursesByIds(semester, sectionIds);
      
      if (courses.isEmpty) {
        debugPrint('[ScheduleService] Warning: Fetched courses list is empty.');
        return;
      }

      // 2. Generate Weekly Template
      final weeklyTemplate = _generateWeeklyTemplate(courses);

      // 3. Fetch Holidays for cross-check
      final holidays = await _academicRepo.fetchHolidays(semester.replaceAll(' ', ''));
      final seen = <String>{};
      final holidayList = holidays
          .where((h) => h.title.toLowerCase().contains('holiday'))
          .map((h) {
        // DB dates are already ISO formatted (2026-02-21), try to use directly
        String dateStr = h.date;
        // If the date isn't already ISO, try to parse it
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(dateStr)) {
          final parsed = _academicRepo.parseDateForHolidays(h.date, semester);
          if (parsed != null) dateStr = _formatDate(parsed);
        }
        return {
          'date': dateStr,
          'name': h.title,
        };
      })
      .where((h) => seen.add('${h['date']}|${h['name']}')) // Deduplicate by date+name
      .toList();

      await _supabase.from('user_schedules').upsert({
        'user_id': user.id,
        'semester': semester.replaceAll(' ', ''),
        'weekly_template': weeklyTemplate,
        'holidays': holidayList,
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, semester');
      
      debugPrint('[ScheduleService] Successfully synced schedule for $semester with ${holidayList.length} holidays.');
    } catch (e) {
      debugPrint('[ScheduleService] Error syncing schedule: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> _generateWeeklyTemplate(List<Course> courses) {
    final template = <String, List<Map<String, dynamic>>>{};
    
    // Mapping from S, M, T, W, R, F, A to Full Day Names
    final dayMap = {
      'S': 'Sunday',
      'M': 'Monday',
      'T': 'Tuesday',
      'W': 'Wednesday',
      'R': 'Thursday',
      'F': 'Friday',
      'A': 'Saturday',
    };

    for (var course in courses) {
      for (var session in course.sessions) {
        // sessions.day might be things like "S", "MW", "TR", "A"
        final chars = session.day.replaceAll(' ', '').split('');
        for (var c in chars) {
          final dayName = dayMap[c];
          if (dayName != null) {
            template.putIfAbsent(dayName, () => []);
            template[dayName]!.add({
              'courseCode': course.code,
              'courseName': course.courseName,
              'type': session.type, // "Theory" or "Lab"
              'startTime': session.startTime,
              'endTime': session.endTime,
              'room': session.room,
              'faculty': session.faculty,
            });
          }
        }
      }
    }

    // Sort classes in each day by start time (optional but good for materialized view)
    // We'll leave it to the UI logic to sort if needed, but adding a basic sort here.
    return template;
  }

  String _formatDate(DateTime date) {
    // Standard format yyyy-MM-dd as expected by DashboardLogic
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
