import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';

class ScheduleManagerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CourseRepository _courseRepo = CourseRepository();
  final AcademicRepository _academicRepo = AcademicRepository();

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<List<Course>> fetchEnrolledCourses(String semesterCode) async {
    if (_userId.isEmpty) return [];

    try {
      // 1. Get enrolled IDs
      final userData = await _courseRepo.fetchUserData();
      final enrolledIds = List<String>.from(userData['enrolledSections'] ?? []);

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
    if (_userId.isEmpty) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('schedule')
          .doc(semesterCode)
          .get();

      if (!doc.exists) return [];

      final data = doc.data() ?? {};
      return List<Map<String, dynamic>>.from(data['exceptions'] ?? []);
    } catch (e) {
      // debugPrint("Error fetching exceptions: $e");
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
    if (_userId.isEmpty) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('schedule')
        .doc(semesterCode);

    final dateStr = date.toIso8601String().split('T')[0];

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        List<Map<String, dynamic>> exceptions = [];
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data.containsKey('exceptions')) {
            exceptions = List<Map<String, dynamic>>.from(data['exceptions']);
          }
        }

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
            // Start/End time logic from makeupDate
            // Assuming 1 hour or default duration?
            // Better to calculate from original or passed in?
            // For now, let's just use formatted string or store just date.
            // DashboardLogic expects: startTime, endTime.
            // Let's assume default 1.5h or reuse original session length?
            // For simplicity, we'll store specific times if passed, or derive.
            // Let's store makeupDate as full ISO.
            // DashboardLogic reads: 'startTime', 'endTime'.

            // Generate formatted time strings "HH:mm AM/PM"
            // Borrowing rough formatter or using DateFormat in screen?
            // Repository shouldn't do formatting ideally.
            // Let's ask caller to pass times or Format here.

            // Minimal simple formatting here:
            // "hh:mm a"
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

            // Dashboard logic expects 'faculty'.
            newException['faculty'] = 'Makeup';
          }

          exceptions.add(newException);
        }

        transaction.set(
            docRef, {'exceptions': exceptions}, SetOptions(merge: true));
      });
    } catch (e) {
      // debugPrint("Error updating exception: $e");
      rethrow;
    }
  }
}
