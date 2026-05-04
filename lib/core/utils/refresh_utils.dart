import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_providers.dart';
import '../repositories/progress_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/profile_repository.dart';
import '../providers/academic_providers.dart';
import '../../features/semester_progress/semester_summary_providers.dart';

class RefreshUtils {
  static void refreshAcademicData(WidgetRef ref) {
    // 1. Core Profile & Academic State
    ref.invalidate(profileProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(academicStateProvider);
    ref.invalidate(currentSemesterCodeProvider);
    ref.invalidate(nextSemesterCodeProvider);

    // 2. Marks & Summaries
    ref.invalidate(currentSemesterMarksProvider);
    ref.invalidate(allSemesterSummariesProvider);
    
    // 3. Analytics & Projections
    ref.invalidate(currentAnalyticsProvider);
    ref.invalidate(projectedCGPAProvider);
    ref.invalidate(academicYearsFutureProvider);
    ref.invalidate(currentYearEarnedCreditsProvider);
    
    // 4. Scholarship & Goals
    ref.invalidate(userScholarshipPolicyProvider);
    ref.invalidate(awardedScholarshipProvider);
    // goalGradesProvider is a StateNotifier, usually updated manually, 
    // but its internal listener will fire on currentSemesterMarksProvider refresh.
  }
}
