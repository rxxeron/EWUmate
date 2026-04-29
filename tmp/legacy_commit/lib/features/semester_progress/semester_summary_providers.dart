import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ewumate/core/models/profile.dart';
import 'package:ewumate/core/models/semester_summary.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/repositories/scholarship_repository.dart';
import 'package:ewumate/core/repositories/dashboard_repository.dart';
import 'package:ewumate/core/repositories/course_repository.dart';
import 'package:ewumate/core/models/models/scholarship_rule_model.dart';
import 'package:ewumate/core/models/semester_analytics.dart';
import 'package:ewumate/core/models/semester_course_marks.dart';
import 'package:ewumate/core/utils/grade_helper.dart';

class AcademicYear {
  final int yearNumber;
  final List<SemesterSummary> semesters;
  
  AcademicYear({required this.yearNumber, required this.semesters});
  
  double get totalCreditsEarned => semesters.fold(0.0, (acc, s) => acc + (s.creditsEarned ?? 0.0));
  
  double get cgpa {
    if (semesters.isEmpty) return 0.0;
    return semesters.last.cgpa ?? 0.0;
  }
}

final userScholarshipPolicyProvider = FutureProvider<ScholarshipRule?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final profile = await ref.watch(profileRepositoryProvider).getProfile(user.id);
  if (profile == null || profile.programCode == null) return null;
  
  // Assuming programId in DB matches programCode or we use 'like' in repo
  return ref.watch(scholarshipPolicyProvider(profile.programCode!, admittedSemester: profile.admittedSemester).future);
});

final academicYearsFutureProvider = FutureProvider<List<AcademicYear>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final profile = await ref.watch(profileRepositoryProvider).getProfile(user.id);
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
  
  final sorted = List<SemesterSummary>.from(summaries)..sort((a,b) => getSemOrder((a as dynamic).semesterCode as String).compareTo(getSemOrder((b as dynamic).semesterCode as String)));
  
  final track = profile.track ?? 'tri_semester';
  final bool isFallPhrm = track == 'bi_semester' && (profile.admittedSemester?.toLowerCase().startsWith('fall') ?? false);
  
  List<AcademicYear> years = [];
  int currentYearIndex = 1;
  List<SemesterSummary> currentGroup = [];
  
  for (var s in sorted) {
    currentGroup.add(s);
    
    // Dynamic group size: Fall PHRM Year 1 = 3, Year 2+ = 2. Others = track-based.
    int targetSize = (track == 'bi_semester') ? 2 : 3;
    if (isFallPhrm && currentYearIndex == 1) targetSize = 3;

    if (currentGroup.length == targetSize) {
      years.add(AcademicYear(yearNumber: currentYearIndex, semesters: List.from(currentGroup)));
      currentYearIndex++;
      currentGroup.clear();
    }
  }

  // Check if the current year is "full" to decide if the next year should appear automatically
  if (currentGroup.isNotEmpty) {
     years.add(AcademicYear(yearNumber: currentYearIndex, semesters: List.from(currentGroup)));
     
     // Determine next year's target size for placeholder
     int nextTargetSize = (track == 'bi_semester') ? 2 : 3;
     if (isFallPhrm && currentYearIndex == 1) nextTargetSize = 3;

     if (currentGroup.length == nextTargetSize && years.length < 4) {
       years.add(AcademicYear(yearNumber: currentYearIndex + 1, semesters: []));
     }
  } else if (years.isNotEmpty && years.length < 4) {
     years.add(AcademicYear(yearNumber: currentYearIndex, semesters: []));
  }
  
  return years;
});

/// A model to represent a scholarship award for a particular year.
class ScholarshipAward {
  final int forYear;
  final String tier;
  final double waiver;
  final String reason;

  ScholarshipAward({required this.forYear, required this.tier, required this.waiver, required this.reason});
}

/// Detects and calculates any scholarship awards based on completed years.
final awardedScholarshipProvider = FutureProvider<List<ScholarshipAward>>((ref) async {
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
        awards.add(ScholarshipAward(
          forYear: ay.yearNumber + 1,
          tier: tier,
          waiver: waiver,
          reason: 'Based on Year ${ay.yearNumber} performance (${yearCgpa.toStringAsFixed(2)} CGPA, ${ay.totalCreditsEarned.toStringAsFixed(1)} / ${requiredCredits.toStringAsFixed(0)} Cr)'
        ));
      }
    }
  }

  return awards;
});


/// A state provider to hold the goal grades entered by the user.
/// It initializes from the database and persists changes back to semester_course_marks.
final goalGradesProvider = StateNotifierProvider<GoalGradesNotifier, Map<String, String>>((ref) {
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
            goals[m.courseCode] = m.gradeGoal!;
          }
        }
        state = {...state, ...goals};
      }
    }, fireImmediately: true);
  }

  Future<void> updateGoal(String courseCode, String grade) async {
    state = {...state, courseCode: grade};
    
    // Persist to DB
    final marks = ref.read(currentSemesterMarksProvider).valueOrNull ?? [];
    final courseMark = marks.where((m) => m.courseCode == courseCode).firstOrNull;
    if (courseMark != null) {
      final updated = courseMark.copyWith(gradeGoal: grade);
      await ref.read(progressRepositoryProvider).updateCourseMarks(updated);
      
      // Update analytics after change
      _syncAnalytics();
    }
  }

  Future<void> _syncAnalytics() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final analytics = await ref.read(currentAnalyticsProvider.future);
    if (analytics == null) return;

    final sgpa = ref.read(projectedSGPAProvider);
    final cgpa = await ref.read(projectedCGPAProvider.future);
    final profile = await ref.read(currentProfileFutureProvider.future);
    final marks = ref.read(currentSemesterMarksProvider).valueOrNull ?? [];
    final allMetadata = ref.read(allCoursesProvider).valueOrNull ?? [];

    // Calculate actual enrolled credits for this semester
    double enrolled = 0.0;
    for (var m in marks) {
      final meta = allMetadata.where((c) => c.code == m.courseCode).firstOrNull;
      enrolled += meta?.creditVal ?? 3.0;
    }

    final earned = profile?.totalCreditsEarned ?? 0.0;

    final policy = await ref.read(userScholarshipPolicyProvider.future);

    // 2. Identify the academic track to determine the fallback threshold
    final track = profile?.track ?? 'tri_semester';
    final fallbackThreshold = (track == 'bi_semester') ? 24.0 : 30.0;

    final updatedAnalytics = analytics.copyWith(
      liveSgpa: sgpa,
      liveCgpa: cgpa,
      takenInThisSem: (enrolled > 0) ? enrolled : (profile?.enrolledCredits ?? 0.0),
      completedCredit: earned,
      requiredCredit: policy?.annualCreditsRequired ?? fallbackThreshold,
      updatedAt: DateTime.now(),
    );

    await ref.read(dashboardRepositoryProvider).updateAnalytics(updatedAnalytics);
  }
}

/// A state provider to hold the selected scholarship target.
final scholarshipTargetProvider = StateNotifierProvider<ScholarshipTargetNotifier, String?>((ref) {
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
    // Attempt to find actual credits from metadata
    final meta = allMetadata.where((m) => m.code == course.courseCode).firstOrNull;
    final credits = meta?.creditVal ?? 3.0; 
    
    final goalGrade = goals[course.courseCode] ?? 'A';
    final gradePoint = GradeHelper.getGradePoint(goalGrade);
    
    totalPoints += (gradePoint * credits);
    totalCredits += credits;
  }
  
  if (totalCredits == 0) return 0.0;
  return totalPoints / totalCredits;
});

/// Calculates the projected CGPA combining past CGPA and predicted SGPA.
final projectedCGPAProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  
  final profile = await ref.watch(profileRepositoryProvider).getProfile(user.id);
  if (profile == null) return 0.0;
  
  final currentCgpa = profile.cgpa ?? 0.0;
  final earnedCredits = profile.totalCreditsEarned ?? 0.0;
  
  final predictedSgpa = ref.watch(projectedSGPAProvider);
  final enrolledCredits = profile.enrolledCredits;
  
  if (enrolledCredits == 0) return currentCgpa;
  
  final predictedTotalPoints = (currentCgpa * earnedCredits) + (predictedSgpa * enrolledCredits);
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

/// Fetches the dynamically configured grade scale from the database.
final gradeScaleMapProvider = FutureProvider<Map<String, double>>((ref) async {
  final supabase = Supabase.instance.client;
  final res = await supabase.from('grade_scale').select('grade, min_score').eq('policy', 'modern');
  
  Map<String, double> scale = {};
  for (var row in res) {
    if (row['min_score'] != null) {
      scale[row['grade']] = (row['min_score'] as num).toDouble();
    }
  }
  return scale;
});
