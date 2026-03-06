import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/task_model.dart';
import '../../features/results/results_repository.dart';
import '../../core/models/result_models.dart';
import '../../core/models/course_model.dart';
import '../../core/models/scholarship_rule_model.dart';
import '../../core/models/semester_progress_models.dart';
import '../../core/utils/course_utils.dart';


class CourseSummary {
  final String code;
  final String title;
  final String section;
  final double credits;
  final double marksObtained;     // Raw marks earned so far
  final double totalPossible;     // Graded weight so far (e.g. 30.0 out of 100)
  final double projectedMarks;    // (marksObtained / totalPossibleSoFar) × 100 — best estimate of final %
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
    this.totalPossible = 100.0,
    double? projectedMarks,  // If null, computed from marksObtained/totalPossible
    this.gradeGoal,
    this.upcomingTasks = const [],
    this.midExam,
    this.finalExam,
    this.targetFinalScore = 0.0,
  }) : projectedMarks = projectedMarks ??
         (totalPossible > 0 && totalPossible < 100
             ? (marksObtained / totalPossible) * 100
             : marksObtained);
}

class TierRequirement {
  final String name;
  final double threshold;
  final double? requiredSGPA;
  final bool isAchieved;
  final bool isImpossible;

  TierRequirement({
    required this.name,
    required this.threshold,
    this.requiredSGPA,
    this.isAchieved = false,
    this.isImpossible = false,
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
  
  // New Fields for Annual Strategy
  final double projectedYearlyGPA;
  final double liveYearlyGPA;  // Based on actual marks so far
  final double liveCGPA;       // Cumulative: past + live this sem
  final double goalCGPA;       // Cumulative: past + goal this sem (if all goals hit)
  final int cycleSemestersCount; // 1, 2, or 3
  final String cycleName; // e.g. "Year 1" or "Summer 25 - Spring 26"
  final List<TierRequirement> tierRequirements;

  // Credit Tracking for Scholarship
  final double cycleCreditsGoal; // Usually 30-35
  final double cycleCreditsCompleted; // Past completed semesters only
  final double cycleCreditsThisSemester; // Credits enrolled this semester (in progress)
  final double cycleCreditsRemaining; // Still left after this semester

  ScholarshipProjection({
    required this.currentCGPA,
    required this.projectedCGPA,
    required this.projectedSGPA,
    this.projectedYearlyGPA = 0.0,
    this.liveYearlyGPA = 0.0,
    this.liveCGPA = 0.0,
    this.goalCGPA = 0.0,
    this.currentTier = "",
    this.nextTier = "",
    this.distanceToNext = 0.0,
    this.requiredSGPA,
    this.cycleSemestersCount = 1,
    this.cycleName = "",
    this.tierRequirements = const [],
    this.cycleCreditsGoal = 30.0,
    this.cycleCreditsCompleted = 0.0,
    this.cycleCreditsThisSemester = 0.0,
    this.cycleCreditsRemaining = 30.0,
  });
}

class SemesterRepository {
  final _supabase = Supabase.instance.client;
  final _resultsRepo = ResultsRepository();

  // In-memory cache: program -> rule (avoids re-fetching every build)
  static final Map<String, ScholarshipRule> _ruleCache = {};

  /// Fetch the scholarship rule for a given [program] and [admitSemester].
  /// Returns a matching rule from Supabase, or a fallback default.
  Future<ScholarshipRule> fetchScholarshipRule(String programId, String admitSemester) async {
    final cacheKey = '$programId|$admitSemester';
    if (_ruleCache.containsKey(cacheKey)) return _ruleCache[cacheKey]!;

    try {
      final rows = await _supabase
          .from('scholarship_rules')
          .select()
          .eq('program_id', programId.toLowerCase())
          .eq('level', 'undergraduate');

      if (rows.isEmpty) return _defaultRule(programId);

      final (admitTerm, admitYear) = _parseSemesterName(admitSemester);
      final admitKeyVal = _semesterSortKey(admitTerm, admitYear);

      // Find the best matching row for the student's admit semester
      ScholarshipRule? best;
      for (final row in rows) {
        final rule = ScholarshipRule.fromMap(row);

        if (rule.admittedFrom != null) {
          final (ft, fy) = _parseSemesterName(rule.admittedFrom!);
          if (admitKeyVal < _semesterSortKey(ft, fy)) continue;
        }

        if (rule.admittedUpto != null) {
          final (tt, ty) = _parseSemesterName(rule.admittedUpto!);
          if (admitKeyVal > _semesterSortKey(tt, ty)) continue;
        }

        best = rule;
      }

      final result = best ?? _defaultRule(programId);
      _ruleCache[cacheKey] = result;
      debugPrint('[ScholarshipRule] $programId / $admitSemester -> annualCredits: ${result.annualCreditsRequired}');
      return result;
    } catch (e) {
      debugPrint('[ScholarshipRule] Error fetching rule: $e');
      return _defaultRule(programId);
    }
  }

  ScholarshipRule _defaultRule(String program) {
    // Fallback: engineering programs need 35, everyone else 30
    final isEng = program.contains('CSE') || program.contains('ICE') ||
        program.contains('EEE') || program.contains('GEB') ||
        program.contains('Civil') || program.contains('Pharmacy');
    return ScholarshipRule(
      id: 0,
      program: program,
      annualCreditsRequired: isEng ? 35 : 30,
      degreeCreditsRequired: isEng ? 140 : 130,
    );
  }

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

    // 5a. Fetch CourseMarks (mark distribution) from semester_progress
    //     Used for accurate live mark projection: totalObtained / totalPossibleSoFar × 100
    Map<String, CourseMarks> courseMarksMap = {};
    try {
      final progressData = await _supabase
          .from('semester_progress')
          .select('summary')
          .eq('user_id', user.id)
          .eq('semester_code', semesterCode)
          .maybeSingle();

      if (progressData != null) {
        final summaryRaw = progressData['summary'] as Map?;
        final summary = summaryRaw != null ? Map<String, dynamic>.from(summaryRaw) : {};
        final coursesRaw = summary['courses'] as Map?;
        if (coursesRaw != null) {
          final courses = Map<String, dynamic>.from(coursesRaw);
          for (var entry in courses.entries) {
            final val = Map<String, dynamic>.from(entry.value);
            val['courseCode'] = entry.key;
            final cm = CourseMarks.fromMap(val);
            courseMarksMap[cm.courseCode] = cm;
          }
        }
      }
    } catch (e) {
      debugPrint('[SemesterRepo] Could not fetch mark distribution: $e');
    }

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
      final totalPoss = (stat?['total_possible'] ?? 0.0).toDouble();
      final goal = stat?['grade_goal'] as String?;

      // Projected marks using mark distribution (if available in courseMarksMap)
      // courseMarksMap is fetched below — totalObtained / totalPossibleSoFar × 100
      double? projectedMarksValue;
      final courseMarksEntry = courseMarksMap[code];
      if (courseMarksEntry != null) {
        final possibleSoFar = courseMarksEntry.totalPossibleSoFar;
        final obtained = courseMarksEntry.totalObtained;
        if (possibleSoFar > 0) {
          projectedMarksValue = (obtained / possibleSoFar) * 100.0;
        }
      }

      summaries.add(CourseSummary(
        code: code,
        title: title,
        section: section,
        credits: credits,
        marksObtained: marks,
        totalPossible: totalPoss > 0 ? totalPoss : 100.0,
        projectedMarks: projectedMarksValue, // null = auto-computed from marks/totalPossible
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
      if (d == 'sunday' || d == 's') {
        codes.add('S');
      } else if (d == 'monday' || d == 'm') {
        codes.add('M');
      } else if (d == 'tuesday' || d == 't') {
        codes.add('T');
      } else if (d == 'wednesday' || d == 'w') {
        codes.add('W');
      } else if (d == 'thursday' || d == 'r') {
        codes.add('R');
      } else if (d == 'friday' || d == 'f') {
        codes.add('F');
      } else if (d == 'saturday' || d == 'a') {
        codes.add('A');
      }
    }
    final order = {'S': 0, 'M': 1, 'T': 2, 'W': 3, 'R': 4, 'F': 5, 'A': 6};
    codes.sort((a, b) => (order[a] ?? 99).compareTo(order[b] ?? 99));
    return codes.join('');
  }

  // --- Helpers for semester ordering ---

  /// EWU term order in an academic year: Summer (2) → Fall (3) → Spring (1)
  static const List<int> _termOrder = [2, 3, 1]; // Summer, Fall, Spring

  /// Converts a term integer (1/2/3) to its position in EWU annual cycle
  static int _termPosition(int term) => _termOrder.indexOf(term);

  /// Parse semester name like "Summer 2025" or "Fall 2025" → (term, year)
  /// Term: 1=Spring, 2=Summer, 3=Fall
  static (int term, int year) _parseSemesterName(String name) {
    final lower = name.toLowerCase();
    int term = 2; // default summer
    if (lower.contains('spring')) {
      term = 1;
    } else if (lower.contains('fall')) {
      term = 3;
    }
    final yearMatch = RegExp(r'\d{4}').firstMatch(name);
    final year = yearMatch != null ? int.parse(yearMatch.group(0)!) : 2024;
    return (term, year);
  }

  /// Returns a comparable integer for sorting semesters chronologically.
  /// Higher = later semester.
  static int _semesterSortKey(int term, int year) {
    // Summer=0, Fall=1, Spring=2 within the same academic year (Summer-Fall-Spring)
    // But Spring belongs to next calendar year from Summer/Fall perspective
    // So: Sum 2025=0, Fall 2025=1, Spring 2026=2, Sum 2026=3, Fall 2026=4, Spring 2027=5 ...
    final pos = _termPosition(term);
    // Spring (term=1) is in "cycle year" of previous Summer's year
    final adjustedYear = term == 1 ? year - 1 : year;
    return adjustedYear * 3 + pos;
  }

  ScholarshipProjection getScholarshipProjection(
    AcademicProfile profile, 
    List<CourseSummary> summaries, {
    ScholarshipRule? rule,
  }) {
    if (profile.semesters.isEmpty && summaries.isEmpty) {
      return ScholarshipProjection(currentCGPA: profile.cgpa, projectedCGPA: profile.cgpa, projectedSGPA: 0.0);
    }

    // 1. Parse admitted semester from studentId (format: YYYY-T-XX-XXX)
    final idParts = profile.studentId.split('-');
    int admitYear = idParts.length >= 1 ? (int.tryParse(idParts[0]) ?? 2024) : 2024;
    int admitTerm = idParts.length >= 2 ? (int.tryParse(idParts[1]) ?? 2) : 2; // 1=Spring, 2=Summer, 3=Fall
    final admitKey = _semesterSortKey(admitTerm, admitYear);

    // 2. Filter completed semesters (no "Ongoing" semesters)
    final pastCompleted = profile.semesters
        .where((s) => !s.semesterName.toLowerCase().contains('ongoing') && s.totalCredits > 0)
        .toList();

    // 3. Sort completed semesters chronologically
    pastCompleted.sort((a, b) {
      final (aTerm, aYear) = _parseSemesterName(a.semesterName);
      final (bTerm, bYear) = _parseSemesterName(b.semesterName);
      return _semesterSortKey(aTerm, aYear).compareTo(_semesterSortKey(bTerm, bYear));
    });

    // 4. Determine how many semesters have passed since ADMISSION (not since app start)
    //    Count only semesters >= admitKey
    final semsSinceAdmit = pastCompleted
        .where((s) {
          final (t, y) = _parseSemesterName(s.semesterName);
          return _semesterSortKey(t, y) >= admitKey;
        })
        .toList();

    final int pastSemsCount = semsSinceAdmit.length;
    final int currentCycleIndex = pastSemsCount ~/ 3;
    final int semInCycle = (pastSemsCount % 3) + 1; // 1, 2, or 3
    final int remainingInCycle = 3 - semInCycle;

    // 5. Cycle's completed semesters
    final cycleStartIdx = currentCycleIndex * 3;
    final List<SemesterResult> completedInCycle = [];
    for (int i = cycleStartIdx; i < semsSinceAdmit.length; i++) {
        completedInCycle.add(semsSinceAdmit[i]);
    }

    // Compute cycle year and term positions
    // Removed unused cycleTermStart and simplified logic
    final int cycleYearOffset = currentCycleIndex; 

    // Simple label: Year N (K/3)
    final cycleName = "Year ${currentCycleIndex + 1} ($semInCycle/3)";

    // 6. Calculate Earned in this Cycle (Past terms)
    double cyclePoints = 0.0;
    double cycleCredits = 0.0;
    for (var sem in completedInCycle) {
      cyclePoints += sem.termGPA * sem.totalCredits;
      cycleCredits += sem.totalCredits;
    }

    // 7. Current Semester Projection (Target vs Live)
    double targetCurrentPoints = 0.0; 
    double liveCurrentPoints = 0.0;
    double currentCredits = 0.0;
    
    for (var s in summaries) {
      final targetGp = _gradeToPoint(s.gradeGoal ?? 'B');
      targetCurrentPoints += targetGp * s.credits;

      // Normalize using projectedMarks (totalObtained/totalPossibleSoFar × 100)
      // projectedMarks is already computed in CourseSummary constructor
      final liveGp = _marksToPoint(s.projectedMarks);
      liveCurrentPoints += liveGp * s.credits;
      currentCredits += s.credits;
    }

    // 8. Historical before this cycle
    double historyPoints = 0.0;
    double historyCredits = 0.0;
    for (int i = 0; i < cycleStartIdx; i++) {
      historyPoints += semsSinceAdmit[i].termGPA * semsSinceAdmit[i].totalCredits;
      historyCredits += semsSinceAdmit[i].totalCredits;
    }

    // Combine Metrics
    double totalCyclePointsTarget = cyclePoints + targetCurrentPoints;
    double totalCyclePointsLive = cyclePoints + liveCurrentPoints;
    double totalCycleCredits = cycleCredits + currentCredits;

    double projectedYearlyGPA = totalCycleCredits > 0 ? totalCyclePointsTarget / totalCycleCredits : 0.0;
    double liveYearlyGPA = totalCycleCredits > 0 ? totalCyclePointsLive / totalCycleCredits : 0.0;

    double totalCumulativePointsLive = historyPoints + totalCyclePointsLive;
    double totalCumulativeCredits = historyCredits + totalCycleCredits;
    double liveCGPA = totalCumulativeCredits > 0 ? totalCumulativePointsLive / totalCumulativeCredits : profile.cgpa;

    // Goal-based cumulative CGPA: what would CGPA be if I hit all my grade goals?
    double totalCumulativePointsGoal = historyPoints + totalCyclePointsTarget;
    double goalCGPA = totalCumulativeCredits > 0 ? totalCumulativePointsGoal / totalCumulativeCredits : profile.cgpa;

    // 9. Thresholds — from DB rule if available, else fallback based on admit year
    double medhaMin, deansMin, meritMin;
    if (rule != null) {
      medhaMin = rule.tierMedhaLalonMin;
      deansMin = rule.tierDeansListMin;
      meritMin = rule.tierMerit100Min;
    } else {
      // Fallback: Spring 2026+ gets raised thresholds
      final isNewRules = (admitYear > 2025) || (admitYear == 2025 && admitTerm == 1 /* Spring */);
      medhaMin = isNewRules ? 3.75 : 3.50;
      deansMin = isNewRules ? 3.85 : 3.75;
      meritMin = isNewRules ? 3.95 : 3.90;
    }

    final thresholds = [medhaMin, deansMin, meritMin];
    final tierNames = [
      'Medha Lalon ($medhaMin+)',
      "Dean's List ($deansMin+)",
      '100% Merit ($meritMin+)',
    ];

    List<TierRequirement> tierReqs = [];
    // Estimate future credits per semester for remaining semesters AFTER the current one
    const double estimatedFutureCredits = 15.0;
    // Total credits if we include future semesters beyond the current one
    final double totalProjectedYearlyCredits = totalCycleCredits + (remainingInCycle * estimatedFutureCredits);

    for (int i = 0; i < thresholds.length; i++) {
        double targetThreshold = thresholds[i];
        double? reqRemainingSGPA;

        // FIX 2: Use LIVE yearly GPA (marks-based) to determine if already achieved
        // Not the goal-based projected GPA. If the student hasn't got the marks yet, it's not achieved.
        bool isAchieved = liveYearlyGPA >= targetThreshold;
        bool isImpossible = false;

        if (!isAchieved) {
          if (remainingInCycle == 0 && currentCredits > 0) {
            // FIX 3: This is the LAST (or only) semester of the cycle.
            // Compute: what SGPA does the student need in THIS semester?
            // Based on past completed cycle points only (not goal projections).
            final double totalPointsTarget = targetThreshold * totalCycleCredits;
            final double pointsNeededThisSem = totalPointsTarget - cyclePoints;
            reqRemainingSGPA = pointsNeededThisSem / currentCredits;
            if (reqRemainingSGPA > 4.0) {
              isImpossible = true;
              reqRemainingSGPA = null;
            } else if (reqRemainingSGPA <= 0.0) {
              isAchieved = true;
              reqRemainingSGPA = null;
            }
          } else if (totalProjectedYearlyCredits > totalCycleCredits) {
            // Future semesters remain — compute average SGPA needed across them
            final double totalPointsNeeded = targetThreshold * totalProjectedYearlyCredits;
            final double pointsNeededInFuture = totalPointsNeeded - (cyclePoints + liveCurrentPoints);
            final double creditsRemaining = totalProjectedYearlyCredits - totalCycleCredits;
            reqRemainingSGPA = pointsNeededInFuture / creditsRemaining;
            if (reqRemainingSGPA > 4.0) {
              isImpossible = true;
              reqRemainingSGPA = null;
            } else if (reqRemainingSGPA < 0.0) {
              reqRemainingSGPA = 0.0;
              isAchieved = true;
            }
          } else {
            isImpossible = true;
          }
        }

        tierReqs.add(TierRequirement(
            name: tierNames[i],
            threshold: targetThreshold,
            requiredSGPA: reqRemainingSGPA,
            isAchieved: isAchieved,
            isImpossible: isImpossible,
        ));
    }

    String currentTier = '';
    for (var req in tierReqs) {
        if (req.isAchieved) currentTier = req.name;
    }

    // FIX 1: Completed = only PAST finished semesters (not the current ongoing one)
    // Current semester credits are "in progress" → count as Left
    final double cycleCreditsGoal = rule?.annualCreditsRequired ?? 30.0;
    final double cycleCreditsCompleted = cycleCredits; // past sems only
    final double cycleCreditsInProgress = currentCredits; // current semester
    final double cycleCreditsRemaining = (cycleCreditsGoal - cycleCreditsCompleted - cycleCreditsInProgress).clamp(0.0, 40.0);

    return ScholarshipProjection(
      currentCGPA: profile.cgpa,
      projectedCGPA: projectedYearlyGPA,
      liveYearlyGPA: liveYearlyGPA,
      liveCGPA: liveCGPA,
      goalCGPA: goalCGPA,
      projectedYearlyGPA: projectedYearlyGPA,
      projectedSGPA: currentCredits > 0 ? targetCurrentPoints / currentCredits : 0.0,
      currentTier: currentTier,
      cycleSemestersCount: semInCycle,
      cycleName: cycleName,
      tierRequirements: tierReqs,
      cycleCreditsGoal: cycleCreditsGoal,
      cycleCreditsCompleted: cycleCreditsCompleted,
      cycleCreditsThisSemester: cycleCreditsInProgress,
      cycleCreditsRemaining: cycleCreditsInProgress + cycleCreditsRemaining,
    );
  }

  double _marksToPoint(double marks) {
    if (marks >= 80) return 4.0;
    if (marks >= 75) return 3.75;
    if (marks >= 70) return 3.5;
    if (marks >= 65) return 3.25;
    if (marks >= 60) return 3.0;
    if (marks >= 55) return 2.75;
    if (marks >= 50) return 2.5;
    if (marks >= 45) return 2.25;
    if (marks >= 40) return 2.0;
    return 0.0;
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
