import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';

class ScheduleManagerRepository {
  final _supabase = Supabase.instance.client;
  final CourseRepository _courseRepo = CourseRepository();
  final AcademicRepository _academicRepo = AcademicRepository();

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<Course>> fetchEnrolledCourses(String semesterCode) async {
    if (_userId == null) return [];

    try {
      // 1. Get enrolled IDs
      final userData = await _courseRepo.fetchUserData();
      final enrolledIds =
          List<String>.from(userData['enrolled_sections'] ?? []);

      if (enrolledIds.isEmpty) return [];

      // 2. Fetch course details
      final allCourses = await _courseRepo.fetchCourses(semesterCode);

      final List<Course> enrolledCourses = [];
      for (var courseList in allCourses.values) {
        for (var course in courseList) {
          if (enrolledIds.contains(course.id)) {
            enrolledCourses.add(course);
          }
        }
      }

      return enrolledCourses;
    } catch (e) {
      // print("Error fetching enrolled courses: $e");
      return [];
    }
  }

  Future<Map<String, DateTime?>> fetchSemesterDates(String semesterCode) async {
    final start = await _academicRepo.getFirstDayOfClasses(semesterCode);
    final end = await _academicRepo.getFinalExamDate(semesterCode);
    // Note: Classes usually end BEFORE exams start.
    // Ideally we want "Last Day of Classes".
    // Does AcademicRepo have it? It has `getFinalExamDate`.
    // Let's blindly use Final Exam Date as the cutoff for now, or investigate if "Last Day of Classes" event exists.
    // Fallback: If no "Last Day", use Final Exam Start - 1 day.

    DateTime? classEnd = end;
    if (end != null) {
      classEnd = end.subtract(const Duration(days: 1));
    }

    return {'start': start, 'end': classEnd};
  }

  // Exceptions: Cancelled or Makeup
  // Stored in: users/{userId}/schedule/{semesterCode} -> field 'exceptions' (List)
  // Each item: { date: 'yyyy-MM-dd', type: 'cancel'|'makeup', courseCode: '...', ... }

  Future<List<Map<String, dynamic>>> fetchExceptions(
      String semesterCode) async {
    if (_userId == null) return [];

    try {
      final res = await _supabase
          .from('profiles')
          .select('schedule_exceptions')
          .eq('id', _userId!)
          .single();
      final allExceptions =
          res['schedule_exceptions'] as Map<String, dynamic>? ?? {};
      return List<Map<String, dynamic>>.from(allExceptions[semesterCode] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<void> updateException(
    String semesterCode,
    String courseId,
    String courseCode, // Added for dashboard display
    String courseName, // Added for dashboard display
    DateTime date,
    String type, // 'cancel', 'makeup', 'active' (active removes exception)
    {
    DateTime? makeupDate,
    String? room, // Added room support
  }) async {
    if (_userId == null) return;

    final dateStr = date.toIso8601String().split('T')[0];

    try {
      final res = await _supabase
          .from('profiles')
          .select('schedule_exceptions')
          .eq('id', _userId!)
          .single();
      final Map<String, dynamic> allExceptions =
          Map<String, dynamic>.from(res['schedule_exceptions'] ?? {});
      List<Map<String, dynamic>> exceptions =
          List<Map<String, dynamic>>.from(allExceptions[semesterCode] ?? []);

      // Remove existing exception for this date/course if any
      exceptions.removeWhere(
          (e) => e['courseCode'] == courseCode && e['date'] == dateStr);

      if (type != 'active') {
        // Add new exception
        final Map<String, dynamic> newException = {
          'courseCode': courseCode,
          'courseName': courseName, // Snapshot for dashboard
          'date': dateStr,
          'type': type,
        };

        if (type == 'makeup' && makeupDate != null) {
          newException['makeupDate'] = makeupDate.toIso8601String();

          String fmt(int h, int m) {
            final suffix = h >= 12 ? "PM" : "AM";
            int oh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
            final mStr = m.toString().padLeft(2, '0');
            return "$oh:$mStr $suffix";
          }

          newException['startTime'] = fmt(makeupDate.hour, makeupDate.minute);
          final end =
              makeupDate.add(const Duration(minutes: 90)); // Default 1.5h
          newException['endTime'] = fmt(end.hour, end.minute);
          newException['room'] = room ?? 'TBA';
          newException['faculty'] = 'Makeup';
        }

        exceptions.add(newException);
      }

      allExceptions[semesterCode] = exceptions;
      await _supabase
          .from('profiles')
          .update({'schedule_exceptions': allExceptions}).eq('id', _userId!);
    } catch (e) {
      // debugPrint("Error updating exception: $e"); // Re-add if debugPrint is available
      rethrow;
    }
  }
}
