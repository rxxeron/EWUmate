import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/repositories/dashboard_repository.dart';
import 'package:ewumate/core/utils/error_utils.dart';
import 'package:ewumate/core/theme/app_colors.dart';
import 'package:ewumate/core/theme/ewu_theme_extension.dart';
import 'package:ewumate/core/widgets/glass_kit.dart';
import 'semester_summary_providers.dart';
import 'widgets/grade_distribution_chart.dart';
import 'widgets/summary/cgpa_hero_dial_card.dart';
import 'widgets/summary/scholarship_selector_card.dart';
import 'widgets/summary/goal_input_grid.dart';
import 'widgets/summary/grade_scale_reference_card.dart';
import 'widgets/summary/awards_status_card.dart';
import 'widgets/summary/academic_years_timeline.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

class SemesterSummaryScreen extends ConsumerStatefulWidget {
  const SemesterSummaryScreen({super.key});

  @override
  ConsumerState<SemesterSummaryScreen> createState() => _SemesterSummaryScreenState();
}

class _SemesterSummaryScreenState extends ConsumerState<SemesterSummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.semesterSummaryKey,
          steps: OnboardingSteps.semesterSummary,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, Color color) {
    final colors = context.ewuColors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.sora(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final profileAsync = ref.watch(currentProfileFutureProvider);
    final policyAsync = ref.watch(userScholarshipPolicyProvider);
    final targetTier = ref.watch(scholarshipTargetProvider);
    final analyticsAsync = ref.watch(currentAnalyticsProvider);
    final currentMarksAsync = ref.watch(currentSemesterMarksProvider);
    final academicYearsAsync = ref.watch(academicYearsFutureProvider);
    final awardsAsync = ref.watch(awardedScholarshipProvider);
    final summariesRaw = ref.watch(allSemesterSummariesProvider).valueOrNull ?? [];

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Academic Journey & Goals',
          style: GoogleFonts.sora(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surfaceNavyBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : colors.borderSubtle,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colors.primaryCyan,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors.primaryCyan.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: const Color(0xFF071426),
              unselectedLabelColor: colors.secondaryText,
              labelStyle: GoogleFonts.sora(fontWeight: FontWeight.w800, fontSize: 11),
              unselectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 11),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Courses'),
                Tab(text: 'Grades'),
                Tab(text: 'Awards'),
              ],
            ),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.primaryCyan)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              AuthErrorUtils.getFriendlyMessage(e),
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(color: AppColors.error),
            ),
          ),
        ),
        data: (profile) {
          // Compute grade distribution counts from summaries
          final Map<String, int> gradeCounts = {};
          int totalHistoricalCourses = 0;
          for (final s in summariesRaw) {
            for (final c in s.courses) {
              String g = '';
              if (c is Map) {
                g = (c['grade'] ?? c['Grade'] ?? '').toString().trim();
              } else {
                try {
                  g = (c.grade ?? '').toString().trim();
                } catch (_) {}
              }
              if (g.isNotEmpty) {
                gradeCounts[g] = (gradeCounts[g] ?? 0) + 1;
                totalHistoricalCourses++;
              }
            }
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Overview Tab
              RefreshIndicator(
                color: colors.primaryCyan,
                backgroundColor: colors.surfaceNavyBlue,
                onRefresh: () async {
                  ref.invalidate(currentAnalyticsProvider);
                  ref.invalidate(currentProfileFutureProvider);
                  ref.invalidate(currentSemesterMarksProvider);
                  ref.invalidate(academicYearsFutureProvider);
                  ref.invalidate(awardedScholarshipProvider);
                  ref.invalidate(userScholarshipPolicyProvider);
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      analyticsAsync.when(
                        data: (analytics) => CgpaHeroDialCard(
                          profile: profile,
                          policyAsync: policyAsync,
                          analytics: analytics,
                          currentMarksAsync: currentMarksAsync,
                          awardsAsync: awardsAsync,
                        ),
                        loading: () => Center(child: CircularProgressIndicator(color: colors.primaryCyan)),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            AuthErrorUtils.getFriendlyMessage(e),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.sora(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle(context, 'Grade Distribution', Icons.bar_chart_rounded, colors.primaryCyan),
                      const SizedBox(height: 12),
                      GradeDistributionChart(
                        gradeCounts: gradeCounts,
                        totalCourses: totalHistoricalCourses,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle(context, 'Scholarship Target', Icons.emoji_events_rounded, colors.primaryCyan),
                      const SizedBox(height: 12),
                      ScholarshipSelectorCard(
                        policyAsync: policyAsync,
                        targetTier: targetTier,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle(context, 'Academic Journey', Icons.timeline_rounded, colors.primaryCyan),
                      const SizedBox(height: 12),
                      AcademicYearsTimeline(
                        asyncYears: academicYearsAsync,
                        awardsAsync: awardsAsync,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Courses & Goals Tab
              RefreshIndicator(
                color: colors.primaryCyan,
                backgroundColor: colors.surfaceNavyBlue,
                onRefresh: () async {
                  ref.invalidate(currentSemesterMarksProvider);
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle(context, 'Active Course Targets', Icons.track_changes_rounded, colors.primaryCyan),
                      const SizedBox(height: 8),
                      Text(
                        'Set target letter grades to simulate required marks for finals',
                        style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      GoalInputGrid(currentMarksAsync: currentMarksAsync),
                    ],
                  ),
                ),
              ),

              // 3. Grade Analysis Tab
              RefreshIndicator(
                color: colors.primaryCyan,
                backgroundColor: colors.surfaceNavyBlue,
                onRefresh: () async {
                  ref.invalidate(allSemesterSummariesProvider);
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GradeDistributionChart(
                        gradeCounts: gradeCounts,
                        totalCourses: totalHistoricalCourses,
                      ),
                      const SizedBox(height: 20),
                      const GradeScaleReferenceCard(),
                    ],
                  ),
                ),
              ),

              // 4. Awards & Scholarships Tab
              RefreshIndicator(
                color: colors.primaryCyan,
                backgroundColor: colors.surfaceNavyBlue,
                onRefresh: () async {
                  ref.invalidate(awardedScholarshipProvider);
                  ref.invalidate(userScholarshipPolicyProvider);
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ScholarshipSelectorCard(
                        policyAsync: policyAsync,
                        targetTier: targetTier,
                      ),
                      const SizedBox(height: 20),
                      AwardsStatusCard(awardsAsync: awardsAsync),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
