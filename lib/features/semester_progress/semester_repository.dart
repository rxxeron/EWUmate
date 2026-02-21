import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/task_model.dart';
import '../../features/results/results_repository.dart';
import '../../core/models/result_models.dart';
import '../../core/models/course_model.dart';
import '../../core/utils/course_utils.dart';


class CourseSummary {
  final String code;
  final String title;
  final String section;
  final double credits;
  final double marksObtained;
  final String? gradeGoal;
  final List<Task> upcomingTasks;
  final Map<String, dynamic>? midExam;
  final Map<String, dynamic>? finalExam;
  final double targetFinalScore; 

  CourseSummary({
    required this.code,
    required this.title,
    required this.section,
    this.credits = 3.0,
    this.marksObtained = 0.0,
    this.gradeGoal,
    this.upcomingTasks = const [],
    this.midExam,
    this.finalExam,
    this.targetFinalScore = 0.0,
  });
}

class ScholarshipProjection {
  final double currentCGPA;
  final double projectedCGPA;
  final double projectedSGPA;
  final String currentTier;
  final String nextTier;
  final double distanceToNext;
  final double? requiredSGPA;

  ScholarshipProjection({
    required this.currentCGPA,
    required this.projectedCGPA,
    required this.projectedSGPA,
    this.currentTier = "",
    this.nextTier = "",
    this.distanceToNext = 0.0,
    this.requiredSGPA,
  });
}

class SemesterRepository {
  final _supabase = Supabase.instance.client;
  final _resultsRepo = ResultsRepository();

  Future<AcademicProfile> fetchAcademicProfile() => _resultsRepo.fetchAcademicProfile();

  /// Checks if the user is currently forced to enter grades before proceeding
  Future<bool> isGradeEntryEnforced() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Check direct flag on profile
      final profile = await _supabase.from('profiles').select('force_grade_entry').eq('id', user.id).single();
      if (profile['force_grade_entry'] == true) return true;

      // 2. Check current semester deadlines
      final active = await _supabase.from('active_semester').select().eq('is_active', true).single();
      final deadlineStr = active['grade_submission_deadline'];
      if (deadlineStr != null) {
        final deadline = DateTime.parse(deadlineStr);
        if (DateTime.now().isAfter(deadline)) {
          // Auto-trigger flag if deadline passed
          await _supabase.from('profiles').update({'force_grade_entry': true}).eq('id', user.id);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking grade entry enforcement: $e');
    }
    return false;
  }

  /// Assign extracted exam dates to the user's profile cache for faster lookups
  Future<void> assignExamDatesToProfile(String semesterCode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch exams for this semester
      final exams = await _supabase.from(CourseUtils.semesterTable('exams', semesterCode)).select();
      if (exams.isEmpty) return;

      // 2. Map patterns to exam info
      final cache = {
        for (var e in exams)
          e['class_days'] as String: {
            'exam_date': e['exam_date'],
            'exam_day': e['exam_day'],
          }
      };

      // 3. Save to profile
      await _supabase.from('profiles').update({
        'exam_dates_cache': cache,
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Error assigning exam dates to profile: $e');
    }
  }

  Future<List<CourseSummary>> fetchSemesterSummary(String semesterCode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Ensure global grade scale and credits are loaded
    await ResultsRepository.ensureMetadataLoaded();

    
    // 1. Fetch Enrollment IDs from Profile
    final profile = await _supabase
        .from('profiles')
        .select('enrolled_sections')
        .eq('id', user.id)
        .single();
    
    
    final enrollmentIds = List<String>.from(profile['enrolled_sections'] ?? []);
    if (enrollmentIds.isEmpty) return [];

    // 2. Fetch Full Course Details
    final coursesTable = CourseUtils.semesterTable('courses', semesterCode);
    
    final courseData = await _supabase
        .from(coursesTable)
        .select()
        .inFilter('doc_id', enrollmentIds);
    
    final enrolledCourses = (courseData as List);
    if (enrolledCourses.isEmpty) return [];

    // 3. Fetch Tasks
    final tasksData = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .eq('is_completed', false);
    final tasks = (tasksData as List).map((t) => Task.fromSupabase(t)).toList();

    // 4. Fetch Semester Stats (Marks/Goals)
    final statsData = await _supabase
        .from('semester_course_stats')
        .select()
        .eq('user_id', user.id)
        .eq('semester', semesterCode);
    final statsMap = {
      for (var s in statsData as List) 
        s['course_code'] as String: s
    };

    // 5. Fetch Final Exams (Check cache first)
    final profileData = await _supabase.from('profiles').select('exam_dates_cache').eq('id', user.id).single();
    final examCache = Map<String, dynamic>.from(profileData['exam_dates_cache'] ?? {});

    List finals = [];
    if (examCache.isEmpty) {
      try {
        finals = await _supabase.from(CourseUtils.semesterTable('exams', semesterCode)).select();
        // Background update cache if empty
        unawaited(assignExamDatesToProfile(semesterCode));
      } catch (e) {
        debugPrint('Error fetching finals: $e');
      }
    }

    List<CourseSummary> summaries = [];

    for (var courseDataMap in enrolledCourses) {
      final courseMap = Map<String, dynamic>.from(courseDataMap);
      final course = Course.fromSupabase(courseMap, courseMap['doc_id'] ?? '');

      final code = course.code;
      final title = course.courseName;
      final section = course.section ?? '';
      final credits = double.tryParse(course.credits ?? '3.0') ?? 3.0;
      
      // Filter tasks for this course
      final courseTasks = tasks.where((t) => t.courseCode == code).toList();
      
      // Find Mid Exam from tasks
      Task? midTask;
      try {
         midTask = courseTasks.firstWhere((t) => t.type == TaskType.midTerm);
      } catch (_) {}

      // Calculate class pattern (e.g., ST, MW)
      String pattern = _getPattern(course.sessions);

      // Find Final Exam from university schedule (Cache or Live)
      Map<String, dynamic>? finalExamData;
      
      // 1. First check the explicit cache via course code
      if (examCache.containsKey(code)) {
         finalExamData = Map<String, dynamic>.from(examCache[code]);
         finalExamData['class_days'] = finalExamData['pattern'] ?? pattern; 
      } 
      // 2. Fallback to live matching if cache missed and pattern exists
      else if (pattern.isNotEmpty) {
          try {
            finalExamData = finals.firstWhere((f) => f['class_days'] == pattern);
          } catch (_) {}
      }

      final stat = statsMap[code];
      final marks = (stat?['marks_obtained'] ?? 0.0).toDouble();
      final goal = stat?['grade_goal'] as String?;

      summaries.add(CourseSummary(
        code: code,
        title: title,
        section: section,
        credits: credits,
        marksObtained: marks,
        gradeGoal: goal,
        upcomingTasks: courseTasks,
        midExam: midTask != null ? {'title': midTask.title, 'date': midTask.dueDate.toIso8601String()} : null,
        finalExam: finalExamData,
        targetFinalScore: _calculateTargetFinal(marks, goal),
      ));
    }

    return summaries;
  }

  String _getPattern(List<CourseSession> sessions) {
    if (sessions.isEmpty) return "";
    final days = sessions.map((s) => s.day).toSet().toList();
    final codes = <String>[];
    for (var day in days) {
      final d = day.toLowerCase().trim();
      if (d == 'sunday' || d == 's') codes.add('S');
      else if (d == 'monday' || d == 'm') codes.add('M');
      else if (d == 'tuesday' || d == 't') codes.add('T');
      else if (d == 'wednesday' || d == 'w') codes.add('W');
      else if (d == 'thursday' || d == 'r') codes.add('R');
      else if (d == 'friday' || d == 'f') codes.add('F');
      else if (d == 'saturday' || d == 'a') codes.add('A');
    }
    final order = {'S': 0, 'M': 1, 'T': 2, 'W': 3, 'R': 4, 'F': 5, 'A': 6};
    codes.sort((a, b) => (order[a] ?? 99).compareTo(order[b] ?? 99));
    return codes.join('');
  }

  ScholarshipProjection getScholarshipProjection(AcademicProfile profile, List<CourseSummary> summaries) {
    if (summaries.isEmpty) return ScholarshipProjection(currentCGPA: profile.cgpa, projectedCGPA: profile.cgpa, projectedSGPA: 0.0);

    double currentTotalPoints = profile.cgpa * profile.totalCreditsEarned;
    double projectedSemPoints = 0.0;
    double projectedSemCredits = 0.0;

    for (var s in summaries) {
      final gp = _gradeToPoint(s.gradeGoal ?? "B"); // Default to B if no goal
      projectedSemPoints += gp * s.credits;
      projectedSemCredits += s.credits;
    }

    double projectedSGPA = projectedSemCredits > 0 ? projectedSemPoints / projectedSemCredits : 0.0;
    double projectedCGPA = (profile.totalCreditsEarned + projectedSemCredits) > 0 
        ? (currentTotalPoints + projectedSemPoints) / (profile.totalCreditsEarned + projectedSemCredits) 
        : profile.cgpa;
    
    // Determine Threshold Era based on Student ID
    final parts = profile.studentId.split('-');
    int term = 0;
    int year = 0;
    if (parts.length >= 2) {
      term = int.tryParse(parts[1]) ?? 0;
      year = int.tryParse(parts[0]) ?? 0;
    }
    bool isNewCGPARules = year > 2026 || (year == 2026 && term >= 1);

    // Dynamic Thresholds
    List<double> thresholds;
    List<String> tierNames;
    if (isNewCGPARules) {
      thresholds = [3.75, 3.85, 3.95];
      tierNames = ["Medha Lalon (3.75+)", "Dean's List (3.85+)", "100% Merit (3.95+)"];
    } else {
      thresholds = [3.50, 3.75, 3.90];
      tierNames = ["Medha Lalon (3.50+)", "Dean's List (3.75+)", "100% Merit (3.90+)"];
    }
    
    String currentTier = "";
    String nextTier = thresholds[0].toString();
    double distance = 0.0;
    double? requiredSGPA;

    for (int i = 0; i < thresholds.length; i++) {
      if (projectedCGPA >= thresholds[i]) {
        currentTier = tierNames[i];
        if (i < thresholds.length - 1) {
          nextTier = tierNames[i + 1];
          distance = thresholds[i + 1] - projectedCGPA;
          
          // Calculate required SGPA for next tier
          if (projectedSemCredits > 0) {
            double targetTotalPoints = thresholds[i + 1] * (profile.totalCreditsEarned + projectedSemCredits);
            double requiredSemPoints = targetTotalPoints - currentTotalPoints;
            requiredSGPA = requiredSemPoints / projectedSemCredits;
            if (requiredSGPA! > 4.0) requiredSGPA = null; // Impossible
            if (requiredSGPA != null && requiredSGPA! < 0.0) requiredSGPA = 0.0;
          }
        } else {
          nextTier = "Max Tier reached!";
          distance = 0.0;
        }
      } else {
        if (currentTier.isEmpty) {
          nextTier = tierNames[i];
          distance = thresholds[i] - projectedCGPA;
          
          // Calculate required SGPA for first tier
          if (projectedSemCredits > 0) {
            double targetTotalPoints = thresholds[i] * (profile.totalCreditsEarned + projectedSemCredits);
            double requiredSemPoints = targetTotalPoints - currentTotalPoints;
            requiredSGPA = requiredSemPoints / projectedSemCredits;
            if (requiredSGPA! > 4.0) requiredSGPA = null; // Impossible
            if (requiredSGPA != null && requiredSGPA! < 0.0) requiredSGPA = 0.0;
          }
        }
        break;
      }
    }

    return ScholarshipProjection(
      currentCGPA: profile.cgpa,
      projectedCGPA: projectedCGPA,
      projectedSGPA: projectedSGPA,
      currentTier: currentTier,
      nextTier: nextTier,
      distanceToNext: distance,
      requiredSGPA: requiredSGPA,
    );
  }

  List<String> get availableGrades {
    if (ResultsRepository.gradeScaleCache.isEmpty) {
      return ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F'];
    }
    return ResultsRepository.gradeScaleCache.keys.toList();
  }

  double _gradeToPoint(String grade) {
    if (ResultsRepository.gradeScaleCache.isEmpty) {
      // Fallback
      switch (grade.toUpperCase()) {
        case 'A': return 4.0;
        case 'A-': return 3.7;
        case 'B+': return 3.3;
        case 'B': return 3.0;
        case 'B-': return 2.7;
        case 'C+': return 2.3;
        case 'C': return 2.0;
        case 'C-': return 1.7;
        case 'D': return 1.0;
        default: return 0.0;
      }
    }
    return ResultsRepository.gradeScaleCache[grade.toUpperCase()] ?? 0.0;
  }

  double _calculateTargetFinal(double currentMarks, String? goal) {
    if (goal == null) return 0.0;
    
    // Simple mock calculation: A needs 80, B needs 70, etc.
    // Assuming 40% worth from finals
    double targetTotal = 80.0;
    switch (goal) {
      case 'A': targetTotal = 80.0; break;
      case 'A-': targetTotal = 75.0; break;
      case 'B+': targetTotal = 70.0; break;
      case 'B': targetTotal = 65.0; break;
      default: targetTotal = 60.0;
    }

    final diff = targetTotal - currentMarks;
    if (diff <= 0) return 0.0;
    
    // Assuming finals are 40% of total grade
    // This is a rough estimation for user guidance
    return (diff / 40.0) * 100.0; 
  }

  Future<void> updateCourseStat(String semester, String code, {double? marks, String? goal}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await _supabase.from('semester_course_stats')
        .select()
        .eq('user_id', user.id)
        .eq('semester', semester)
        .eq('course_code', code)
        .maybeSingle();

      final data = {
        'user_id': user.id,
        'semester': semester,
        'course_code': code,
        'marks_obtained': marks ?? existing?['marks_obtained'] ?? 0.0,
        'grade_goal': goal ?? existing?['grade_goal'],
        'last_updated': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        await _supabase.from('semester_course_stats').update(data).eq('id', existing['id']);
      } else {
        await _supabase.from('semester_course_stats').insert(data);
      }
    } catch (e) {
      // Ignore for now, but in production we'd log this
    }
  }

  /// Finalizes the semester: 
  /// 1. Saves all grades to academic history
  /// 2. Swaps enrolled_sections_next -> enrolled_sections
  /// 3. Clears the gatekeeper
  Future<bool> submitFinalGradesAndTransition(String semesterCode, Map<String, String> grades) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Fetch current academic_data
      final acadRes = await _supabase.from('academic_data').select().eq('user_id', user.id).maybeSingle();
      Map<String, dynamic> semesters = Map<String, dynamic>.from(acadRes?['semesters'] ?? {});

      // 2. Add current grades to history
      semesters[semesterCode] = grades;

      // 3. Update profiles (The "Swap")
      final profile = await _supabase.from('profiles').select().eq('id', user.id).single();
      final nextSections = profile['enrolled_sections_next'] ?? [];

      await _supabase.from('profiles').update({
        'enrolled_sections': nextSections,
        'enrolled_sections_next': [],
        'force_grade_entry': false,
        'exam_dates_cache': {}, // Clear cache for new semester
      }).eq('id', user.id);

      // 4. Update academic_data
      await _supabase.from('academic_data').update({
        'semesters': semesters,
      }).eq('user_id', user.id);

      // 5. Trigger stats recalculation via existing Azure logic (handled via client call or DB trigger)
      // For now, we assume the DB trigger will handle it or user will refresh.

      return true;
    } catch (e) {
      debugPrint('Transition failed: $e');
      return false;
    }
  }
}
