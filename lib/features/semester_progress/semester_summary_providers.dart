import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ewumate/core/models/profile.dart';
import 'package:ewumate/core/models/semester_summary.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/services/cache_service.dart';
import 'package:ewumate/core/models/profile.dart';
import 'package:ewumate/core/models/semester_summary.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/services/cache_service.dart';
import 'package:ewumate/core/utils/course_utils.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/repositories/scholarship_repository.dart';
import 'package:ewumate/core/models/semester_course_marks.dart';
import 'package:ewumate/core/utils/grade_helper.dart';
import 'package:ewumate/core/models/grade_scale.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/models/models/scholarship_rule_model.dart';
import 'package:ewumate/core/repositories/course_repository.dart';
import 'package:ewumate/core/repositories/dashboard_repository.dart';

class AcademicYear {
  final int yearNumber;
  final List<SemesterSummary> semesters;

  AcademicYear({required this.yearNumber, required this.semesters});

  double get totalCreditsEarned =>
      semesters.fold(0.0, (acc, s) => acc + (s.creditsEarned ?? 0.0));

  double get cgpa {
    if (semesters.isEmpty) return 0.0;
    return semesters.last.cgpa ?? 0.0;
  }
}

final userScholarshipPolicyProvider = FutureProvider<ScholarshipRule?>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final profile = await ref
      .watch(profileRepositoryProvider)
      .getProfile(user.id);
  if (profile == null || profile.programCode == null) return null;

  // Assuming programId in DB matches programCode or we use 'like' in repo
  return ref.watch(
    scholarshipPolicyProvider(
      profile.programCode!,
      admittedSemester: profile.admittedSemester,
    ).future,
  );
});

final academicYearsFutureProvider = FutureProvider<List<AcademicYear>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final profile = await ref
      .watch(profileRepositoryProvider)
      .getProfile(user.id);
  if (profile == null) return [];

  final summaries = await ref.watch(allSemesterSummariesProvider.future);

  int getSemOrder(String semId) {
    if (semId.length < 5) return 0;
    final year = int.tryParse(semId.substring(semId.length - 4)) ?? 0;
    final sem = semId.substring(0, semId.length - 4);
    int sVal = 0;
    if (sem.toLowerCase() == 'spring') sVal = 1;
    if (sem.toLowerCase() == 'summer') sVal = 2;
    if (sem.toLowerCase() == 'fall') sVal = 3;
    return year * 10 + sVal;
  }

  final sorted = List<SemesterSummary>.from(summaries)
    ..sort(
      (a, b) => getSemOrder(
        (a as dynamic).semesterCode as String,
      ).compareTo(getSemOrder((b as dynamic).semesterCode as String)),
    );

  final track = profile.track ?? 'tri_semester';
  final bool isFallPhrm =
      track == 'bi_semester' &&
      (profile.admittedSemester?.toLowerCase().startsWith('fall') ?? false);

  // Filter out semesters that are effectively empty (no credits and no TGPA)
  // unless it's the current active semester (which we want to see in the grouping)
  final String? runningCode = ref.watch(currentSemesterCodeProvider).value;
  final filteredSorted = sorted.where((s) => 
    (s.creditsEarned ?? 0.0) > 0 || 
    (s.tgpa ?? 0.0) > 0 || 
    (s.semesterCode == runningCode)
  ).toList();

  // If the running semester isn't in summaries yet, we still need to account for it in the grouping
  bool runningIncluded = filteredSorted.any((s) => s.semesterCode == runningCode);
  if (!runningIncluded && runningCode != null) {
    // Add a dummy summary for the ongoing semester to ensure Year grouping accounts for it
    filteredSorted.add(SemesterSummary(
      id: 'ongoing',
      userId: user.id,
      semesterCode: runningCode,
      creditsEarned: 0.0,
      tgpa: 0.0,
      cgpa: profile.cgpa ?? 0.0,
    ));
    // Re-sort to maintain chronological order
    filteredSorted.sort(
      (a, b) => getSemOrder(
        (a as dynamic).semesterCode as String,
      ).compareTo(getSemOrder((b as dynamic).semesterCode as String)),
    );
  }

  List<AcademicYear> years = [];
  int currentYearIndex = 1;
  List<SemesterSummary> currentGroup = [];

  for (var s in filteredSorted) {
    currentGroup.add(s);

    // Dynamic group size: Fall PHRM Year 1 = 3, Year 2+ = 2. Others = track-based.
    int targetSize = (track == 'bi_semester') ? 2 : 3;
    if (isFallPhrm && currentYearIndex == 1) targetSize = 3;

    if (currentGroup.length == targetSize) {
      years.add(
        AcademicYear(
          yearNumber: currentYearIndex,
          semesters: List.from(currentGroup),
        ),
      );
      currentYearIndex++;
      currentGroup.clear();
    }
  }

  // Only add the final group if it contains actual data
  if (currentGroup.isNotEmpty) {
    years.add(
      AcademicYear(
        yearNumber: currentYearIndex,
        semesters: List.from(currentGroup),
      ),
    );
  }

  return years;
});

/// A model to represent a scholarship award for a particular year.
class ScholarshipAward {
  final int forYear;
  final String tier;
  final double waiver;
  final String reason;

  ScholarshipAward({
    required this.forYear,
    required this.tier,
    required this.waiver,
    required this.reason,
  });
}

/// Detects and calculates any scholarship awards based on completed years.
final awardedScholarshipProvider = FutureProvider<List<ScholarshipAward>>((
  ref,
) async {
  final years = await ref.watch(academicYearsFutureProvider.future);
  final policy = await ref.watch(userScholarshipPolicyProvider.future);
  if (policy == null || years.isEmpty) return [];

  List<ScholarshipAward> awards = [];

  for (var ay in years) {
    // A scholarship is typically evaluated after a FULL year (all semesters completed)
    // and applied to the NEXT year.
    // We check if the year met the credit threshold (e.g. 30 for Tri-sem, 24 for Bi-sem)
    // Use the dynamic policy values directly
    final requiredCredits = policy.annualCreditsRequired;

    if (ay.totalCreditsEarned >= requiredCredits) {
      String tier = '';
      double waiver = 0.0;

      final yearCgpa = ay.cgpa;
      if (yearCgpa >= policy.tierMerit100Min) {
        tier = 'Merit 100%';
        waiver = policy.waiverMerit100;
      } else if (yearCgpa >= policy.tierDeansListMin) {
        tier = "Dean's List";
        waiver = policy.waiverDeansList;
      } else if (yearCgpa >= policy.tierMedhaLalonMin) {
        tier = 'Medha Lalon';
        waiver = policy.waiverMedhaLalon;
      }

      if (tier.isNotEmpty) {
        awards.add(
          ScholarshipAward(
            forYear: ay.yearNumber + 1,
            tier: tier,
            waiver: waiver,
            reason:
                'Based on Year ${ay.yearNumber} performance (${yearCgpa.toStringAsFixed(2)} CGPA, ${ay.totalCreditsEarned.toStringAsFixed(1)} / ${requiredCredits.toStringAsFixed(0)} Cr)',
          ),
        );
      }
    }
  }

  return awards;
});

/// A state provider to hold the goal grades entered by the user.
/// It initializes from the database and persists changes back to semester_course_marks.
final goalGradesProvider =
    StateNotifierProvider<GoalGradesNotifier, Map<String, String>>((ref) {
      return GoalGradesNotifier(ref);
    });

class GoalGradesNotifier extends StateNotifier<Map<String, String>> {
  final Ref ref;
  GoalGradesNotifier(this.ref) : super({}) {
    _init();
  }

  void _init() {
    ref.listen(currentSemesterMarksProvider, (prev, next) {
      if (next is AsyncData<List<SemesterCourseMarks>>) {
        final Map<String, String> goals = {};
        for (var m in next.value) {
          if (m.gradeGoal != null) {
            goals[m.courseCode.toUpperCase().replaceAll(' ', '')] = m.gradeGoal!;
          }
        }
        // Update state but preserve existing keys if next list is partial (though unlikely here)
        state = {...state, ...goals};
      }
    }, fireImmediately: true);
  }

  Future<void> updateGoal(String courseCode, String grade) async {
    state = {...state, courseCode: grade};

    // Persist to DB
    final normalizedCode = courseCode.toUpperCase().replaceAll(' ', '');
    final marks = ref.read(currentSemesterMarksProvider).valueOrNull ?? [];
    final courseMark = marks
        .where((m) => m.courseCode.toUpperCase().replaceAll(' ', '') == normalizedCode)
        .firstOrNull;
    if (courseMark != null) {
      final updated = courseMark.copyWith(gradeGoal: grade);
      await ref.read(progressRepositoryProvider).updateCourseMarks(updated);

      // Update analytics by refetching from db to trigger UI refresh.
      // Supabase's `trg_calculate_live_projection` calculates the latest values securely.
      ref.invalidate(currentAnalyticsProvider);
    }
  }
}

/// A state provider to hold the selected scholarship target.
final scholarshipTargetProvider =
    StateNotifierProvider<ScholarshipTargetNotifier, String?>((ref) {
      return ScholarshipTargetNotifier(ref);
    });

class ScholarshipTargetNotifier extends StateNotifier<String?> {
  final Ref ref;
  ScholarshipTargetNotifier(this.ref) : super(null) {
    _init();
  }

  void _init() {
    ref.listen(currentProfileFutureProvider, (prev, next) {
      if (next is AsyncData<Profile?>) {
        state = next.value?.scholarshipStatus;
      }
    }, fireImmediately: true);
  }

  Future<void> updateTarget(String target) async {
    state = target;
    final profile = await ref.read(currentProfileFutureProvider.future);
    if (profile != null) {
      final updated = profile.copyWith(scholarshipStatus: target);
      await ref.read(profileRepositoryProvider).updateProfile(updated);
      ref.invalidate(currentProfileFutureProvider);
      ref.invalidate(currentAnalyticsProvider);
    }
  }
}

/// Calculates the projected SGPA for the current semester based on goal grades.
final projectedSGPAProvider = Provider<double>((ref) {
  final goals = ref.watch(goalGradesProvider);
  final currentMarksAsync = ref.watch(currentSemesterMarksProvider);
  final allCoursesAsync = ref.watch(allCoursesProvider);

  final marks = currentMarksAsync.valueOrNull ?? [];
  final allMetadata = allCoursesAsync.valueOrNull ?? [];

  if (marks.isEmpty || goals.isEmpty) return 0.0;

  double totalPoints = 0.0;
  double totalCredits = 0.0;

  for (var course in marks) {
    final meta = allMetadata
        .where((m) => m.code == course.courseCode)
        .firstOrNull;
    final credits = meta?.creditVal ?? 3.0;

    final policy = GradeHelper.getPolicyForSemester(course.semesterCode);
    final scale = ref.watch(gradePointMapProvider(policy)).valueOrNull;

    String goalGrade = goals[course.courseCode] ?? 'A';

    double gradePoint = 0.0;
    if (scale != null) {
      // If the saved goal isn't in the DB-driven scale for this policy
      // Fallback to highest grade point if it's A+ vs A, or just use Scale's first if missing
      if (!scale.containsKey(goalGrade)) {
        if (goalGrade == 'A+' && scale.containsKey('A')) {
          gradePoint = scale['A']!;
        } else {
          // Use the highest point available in the scale
          gradePoint = scale.values.fold(0.0, (a, b) => a > b ? a : b);
        }
      } else {
        gradePoint = scale[goalGrade]!;
      }
    } else {
      // Temporary fallback to hardcoded helper if DB isn't ready
      gradePoint = GradeHelper.getGradePoint(
        goalGrade,
        semesterCode: course.semesterCode,
      );
    }

    totalPoints += (gradePoint * credits);
    totalCredits += credits;
  }

  if (totalCredits == 0) return 0.0;
  return totalPoints / totalCredits;
});

/// Calculates the projected CGPA combining past CGPA and predicted SGPA.
final currentEnrolledCreditsProvider = Provider<double>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.enrolledCredits ?? 0.0;
});

final projectedCGPAProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;

  final profile = await ref
      .watch(profileRepositoryProvider)
      .getProfile(user.id);
  if (profile == null) return 0.0;

  final currentCgpa = profile.cgpa ?? 0.0;
  final earnedCredits = profile.totalCreditsEarned ?? 0.0;

  final predictedSgpa = ref.watch(projectedSGPAProvider);
  final enrolledCredits = profile.enrolledCredits;

  if (enrolledCredits == 0) return currentCgpa;

  final predictedTotalPoints =
      (currentCgpa * earnedCredits) + (predictedSgpa * enrolledCredits);
  final newTotalCredits = earnedCredits + enrolledCredits;

  return newTotalCredits > 0 ? (predictedTotalPoints / newTotalCredits) : 0.0;
});

/// Stable FutureProvider for the current user's profile to prevent StreamBuilder flicker
final currentProfileFutureProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});

/// Gets the total credits earned in the current ongoing academic year.
final currentYearEarnedCreditsProvider = FutureProvider<double>((ref) async {
  final years = await ref.watch(academicYearsFutureProvider.future);
  if (years.isEmpty) return 0.0;

  // The last academic year in the list is the current one
  return years.last.totalCreditsEarned;
});

/// Fetches the dynamically configured grade point from the database for a specific policy.
final gradePointMapProvider =
    FutureProvider.family<Map<String, double>, String>((ref, policy) async {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('grade_scale')
          .select('grade, point')
          .eq('policy', policy);

      Map<String, double> points = {};
      for (var row in res) {
        if (row['point'] != null) {
          points[row['grade']] = (row['point'] as num).toDouble();
        }
      }
      return points;
    });

/// Fetches the dynamically configured grade scale from the database for a specific policy.
final gradeScaleMapProvider =
    FutureProvider.family<Map<String, double>, String>((ref, policy) async {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('grade_scale')
          .select('grade, min_score')
          .eq('policy', policy);

      Map<String, double> scale = {};
      for (var row in res) {
        if (row['min_score'] != null) {
          scale[row['grade']] = (row['min_score'] as num).toDouble();
        }
      }
      return scale;
    });

/// Fetches the list of valid grades for a policy, sorted by grade point descending.
final policyGradesProvider = FutureProvider.family<List<String>, String>((
  ref,
  policy,
) async {
  final supabase = Supabase.instance.client;
  final res = await supabase
      .from('grade_scale')
      .select('grade, point')
      .eq('policy', policy)
      .order('point', ascending: false);

  return (res as List).map((row) => row['grade'] as String).toList();
});

/// Fetches the full list of grade scale entries.
final gradeScaleListProvider = FutureProvider<List<GradeScale>>((ref) async {
  final supabase = Supabase.instance.client;
  final res = await supabase.from('grade_scale').select('*');
  return (res as List).map((row) => GradeScale.fromJson(row)).toList();
});
