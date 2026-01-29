import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/task_model.dart';
import '../utils/date_utils.dart';
import '../constants/app_constants.dart';
import '../../features/calendar/academic_repository.dart';
import '../../features/tasks/task_repository.dart';

class ExamSyncLogic {
  final AcademicRepository _academicRepo = AcademicRepository();
  final TaskRepository _taskRepo = TaskRepository();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> syncExams(List<Course> enrolledCourses, List<Task> existingTasks,
      String semesterCode) async {
    if (userId.isEmpty) return;

    // 1. Fetch Exam Schedule
    final exams = await _academicRepo.fetchExamSchedule(semesterCode);
    if (exams.isEmpty) return;

    // 2. Iterate Courses
    for (var course in enrolledCourses) {
      if (course.sessions.isEmpty) continue;

      // 3. Determine Pattern
      final pattern = _getPattern(course.sessions);
      if (pattern.isEmpty) continue;

      // 4. Find Matching Exam
      final match = exams.firstWhere(
        (e) => e['class_days'] == pattern,
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        // 5. Check if Task Exists
        final examTitle = "Final Exam: ${course.code}";
        final exists = existingTasks.any(
            (t) => t.courseCode == course.code && t.type == TaskType.finalExam);

        if (!exists) {
          // 6. Create Task
            final dynamic examDateStr = match['exam_date']; // "24 April 2026"
          if (examDateStr != null && examDateStr is String) {
            final examDate = DateUtils.parseDate(examDateStr);

            if (examDate != null) {
              // Only add if within configured days ahead
              final now = DateTime.now();
              if (examDate.difference(now).inDays >
                  AppConstants.examSyncDaysAhead) {
                continue;
              }

              final taskId = 'final_exam_${course.code}_$semesterCode'
                  .replaceAll(' ', '_');

              await _taskRepo.addTask(Task(
                  id: taskId,
                  title: examTitle,
                  courseCode: course.code,
                  courseName: course.courseName,
                  assignDate: DateTime.now(),
                  dueDate: examDate,
                  submissionType: SubmissionType.offline,
                  type: TaskType.finalExam,
                  isCompleted: false)); // Removed userId arg as repo handles it
            }
          }
        }
      }
    }
  }

  String _getPattern(List<CourseSession> sessions) {
    // Unique days
    final days = sessions.map((s) => s.day).toSet().toList();

    // Convert to codes
    // S=Sunday, M=Monday, T=Tuesday, W=Wednesday, R=Thursday, F=Friday, A=Saturday
    // Or standard abbreviations used in the university
    // Assuming S, M, T, W, R, F, A (Sat)

    final codes = <String>[];
    for (var day in days) {
      final d = day.toLowerCase().trim();
      if (d == 'sunday') {
        codes.add('S');
      } else if (d == 'monday') {
        codes.add('M');
      } else if (d == 'tuesday') {
        codes.add('T');
      } else if (d == 'wednesday') {
        codes.add('W');
      } else if (d == 'thursday') {
        codes.add('R');
      } else if (d == 'friday') {
        codes.add('F');
      } else if (d == 'saturday') {
        codes.add('A');
      }
    }

    // Sort logic? ST, MW, SR, RA?
    // Usually ordered by week day: S, M, T, W, R, F, A
    // Sort mapping
    final order = {'S': 0, 'M': 1, 'T': 2, 'W': 3, 'R': 4, 'F': 5, 'A': 6};
    codes.sort((a, b) => (order[a] ?? 99).compareTo(order[b] ?? 99));

    return codes.join('');
  }

}
