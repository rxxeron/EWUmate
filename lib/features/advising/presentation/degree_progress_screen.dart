import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/models/profile.dart';
import 'package:ewumate/core/models/semester_summary.dart';
import 'package:ewumate/core/utils/course_utils.dart';
import 'package:ewumate/core/theme/ewu_theme_extension.dart';
import 'package:ewumate/core/widgets/glass_kit.dart';
import 'widgets/degree_progress/degree_hero_card.dart';
import 'widgets/degree_progress/degree_stats_grid.dart';
import 'widgets/degree_progress/degree_milestones_card.dart';
import 'widgets/degree_progress/degree_cgpa_action_card.dart';
import 'widgets/degree_progress/degree_academic_history_list.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

class DegreeProgressScreen extends ConsumerStatefulWidget {
  const DegreeProgressScreen({super.key});

  @override
  ConsumerState<DegreeProgressScreen> createState() => _DegreeProgressScreenState();
}

class _DegreeProgressScreenState extends ConsumerState<DegreeProgressScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(profileRepositoryProvider);
        ref.invalidate(allSemesterSummariesProvider);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.degreeProgressKey,
          steps: OnboardingSteps.degreeProgress,
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  int _getSemesterWeight(String semester) {
    final lower = semester.toLowerCase();
    if (lower.contains('spring')) return 1;
    if (lower.contains('summer')) return 2;
    if (lower.contains('fall')) return 3;
    return 0;
  }

  int _getYear(String semester) {
    final match = RegExp(r'\d{4}').firstMatch(semester);
    return match != null ? int.parse(match.group(0)!) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    if (userId == null) {
      return FullGradientScaffold(
        body: Center(
          child: Text(
            'User not found.',
            style: GoogleFonts.sora(color: colors.textSecondary),
          ),
        ),
      );
    }

    final profileStream = ref.watch(profileRepositoryProvider).streamProfile(userId);
    final semesterSummariesAsync = ref.watch(allSemesterSummariesProvider);

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Degree Progress',
          style: GoogleFonts.sora(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: colors.primaryCyan, size: 26),
            tooltip: 'Edit Course History',
            onPressed: () async {
              HapticFeedback.lightImpact();
              await context.push('/onboarding/course-history', extra: {'isEditMode': true});
              ref.invalidate(allSemesterSummariesProvider);
              ref.invalidate(academicStateProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileRepositoryProvider);
          ref.invalidate(allSemesterSummariesProvider);
          ref.invalidate(academicStateProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        color: colors.primaryCyan,
        backgroundColor: colors.surfaceNavyBlue,
        child: StreamBuilder<Profile?>(
          stream: profileStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: colors.primaryCyan));
            }

            final profile = snapshot.data;
            if (profile == null) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 500,
                  child: Center(
                    child: Text(
                      'Profile not found.',
                      style: GoogleFonts.sora(color: colors.textSecondary),
                    ),
                  ),
                ),
              );
            }

            final summariesRaw = (semesterSummariesAsync is AsyncData)
                ? (semesterSummariesAsync as AsyncData<List<SemesterSummary>>).value
                : <SemesterSummary>[];

            final int semestersCount = summariesRaw.length;
            final double earnedCredits = profile.totalCreditsEarned ?? 0.0;
            final int coursesDone = profile.totalCoursesCompleted;

            final programDetailsAsync = profile.programCode != null
                ? ref.watch(programDetailsProvider(profile.programCode!))
                : const AsyncData<Map<String, dynamic>?>(null);

            double requiredCredits = (programDetailsAsync.value?['total_degree_credits'] as num?)?.toDouble() ?? 140.0;

            // SPECIAL CASE: BBA curriculum credit adjustment based on admitted semester
            if (profile.programCode?.toUpperCase() == 'BBA') {
              if (CourseUtils.isSemesterBeforeSpring2025(profile.admittedSemester)) {
                requiredCredits = 123.0;
              } else {
                requiredCredits = 130.0;
              }
            }
            final String programName = programDetailsAsync.value?['name'] ?? profile.programCode ?? 'Undergraduate Program';

            final academicState = ref.watch(academicStateProvider).value;
            final String currentTrack = academicState?.track == 'bi_semester' ? 'Bi-Semester Track' : 'Tri-Semester Track';
            final String? runningSemesterCode = academicState?.currentSemesterCode;
            final String? upcomingSemesterCode = academicState?.nextSemesterCode;

            // Chronological sort for display, filtering out running & upcoming
            final summaries = summariesRaw
                .where((s) => s.semesterCode != runningSemesterCode && s.semesterCode != upcomingSemesterCode)
                .toList();

            summaries.sort((a, b) {
              final yearA = _getYear(a.semesterCode);
              final yearB = _getYear(b.semesterCode);
              if (yearA != yearB) return yearA.compareTo(yearB);
              return _getSemesterWeight(a.semesterCode).compareTo(_getSemesterWeight(b.semesterCode));
            });

            final double progressPercent = (earnedCredits / requiredCredits).clamp(0.0, 1.0);
            final int displayPercent = (progressPercent * 100).toInt();
            final double creditsRemaining = (requiredCredits - earnedCredits).clamp(0.0, requiredCredits);

            // Accurate remaining semesters based on degree curriculum
            final int totalDegreeSemesters = academicState?.track == 'bi_semester' ? 8 : 12;
            final int remainingSemesters = (totalDegreeSemesters - semestersCount).clamp(0, totalDegreeSemesters);

            final double actualCgpa = profile.cgpa ?? 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Circular Degree Gauge Card
                  DegreeHeroCard(
                    profile: profile,
                    earnedCredits: earnedCredits,
                    requiredCredits: requiredCredits,
                    coursesDone: coursesDone,
                    progressPercent: progressPercent,
                    displayPercent: displayPercent,
                    programName: programName,
                    currentTrack: currentTrack,
                  ),

                  const SizedBox(height: 16),

                  // 2. 2x2 Clean Stats Grid
                  DegreeStatsGrid(
                    creditsCompleted: earnedCredits,
                    creditsRemaining: creditsRemaining,
                    semestersCompleted: semestersCount,
                    semestersLeft: remainingSemesters,
                  ),

                  const SizedBox(height: 20),

                  // 4. 3-Phase Milestone Stepper Journey
                  DegreeMilestonesCard(progressPercent: progressPercent),

                  const SizedBox(height: 20),

                  // 5. CGPA & Semester Summary Quick Actions
                  DegreeCgpaActionCard(cgpa: actualCgpa),

                  const SizedBox(height: 14),

                  const DegreeSemesterSummaryLinkCard(),

                  const SizedBox(height: 24),

                  // 6. Previous Semesters History List
                  DegreeAcademicHistoryList(summaries: summaries),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
