import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/active_semester.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import 'user_academic_providers.dart';
import 'advising_notifier.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/providers/feature_flag_provider.dart';
import 'widgets/advising/advising_locked_view.dart';
import 'widgets/advising/advising_course_selection_tab.dart';
import 'widgets/advising/advising_saved_drafts_tab.dart';
import 'widgets/advising/advising_generation_history_tab.dart';
import 'widgets/advising/advising_generation_overview_view.dart';
import '../../../core/services/screen_protection_service.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

class AdvisingScreen extends ConsumerStatefulWidget {
  const AdvisingScreen({super.key});

  @override
  ConsumerState<AdvisingScreen> createState() => _AdvisingScreenState();
}

class _AdvisingScreenState extends ConsumerState<AdvisingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateProtectionForTab(_tabController.index);
    _tabController.addListener(_handleTabChanged);
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(activeSemesterProvider);
        ref.invalidate(availableAdvisingCoursesProvider);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.advisingKey,
          steps: OnboardingSteps.advising,
        );
      }
    });
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    _updateProtectionForTab(_tabController.index);
  }

  void _updateProtectionForTab(int index) {
    final hasActiveGen = ref.read(advisingNotifierProvider).generationId != null;
    if (hasActiveGen) {
      ScreenProtectionService.enableProtection();
    } else if (index == 1) {
      // Tab 1 is 'My Drafts' -> Screenshot Allowed
      ScreenProtectionService.disableProtection();
    } else {
      // Tab 0 (Pick Courses), Tab 2 (Generations) -> Protected
      ScreenProtectionService.enableProtection();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _refreshTimer?.cancel();
    ScreenProtectionService.disableProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSemAsync = ref.watch(activeSemesterProvider);
    final advisingState = ref.watch(advisingNotifierProvider);
    final isFeatureOpenAsync = ref.watch(isAdvisingOpenProvider);

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Pre-Advising',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: _buildProtectionBadge(advisingState.generationId != null),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeSemesterProvider);
          ref.invalidate(availableAdvisingCoursesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primaryCyan,
        backgroundColor: AppColors.surfaceNavyBlue,
        child: activeSemAsync.when(
          data: (activeSem) {
            if (activeSem != null) {
              final advStart = activeSem.advisingStartDate;
              final classStart = activeSem.upcomingClassesStartDate;

              // Manual Admin Switch Overrides Automatic Dates
              final isFeatureOpen = isFeatureOpenAsync.value ?? false;
              bool isLocked = !isFeatureOpen;

              if (isLocked) {
                final openDateStr = advStart != null
                    ? DateFormat('MMM dd, yyyy h:mm a').format(advStart.subtract(const Duration(days: 16)))
                    : 'TBA';
                final closeDateStr = classStart != null
                    ? DateFormat('MMM dd, yyyy h:mm a').format(classStart)
                    : 'TBA';
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: AdvisingLockedView(
                      title: 'Pre-Advising Locked',
                      message: 'The pre-advising section opens on $openDateStr and closes on $closeDateStr.',
                      icon: Icons.lock_clock,
                    ),
                  ),
                );
              }
            }

            // If a generation is active, show the tracking view
            if (advisingState.generationId != null) {
              return AdvisingGenerationOverviewView(
                genId: advisingState.generationId!,
                activeSem: activeSem,
              );
            }
            return _buildMainPlanningView(activeSem);
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
          error: (err, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: 500,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    AuthErrorUtils.getFriendlyMessage(err),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(color: Colors.redAccent, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainPlanningView(ActiveSemester? activeSem) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF04101E),
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Pick Courses'),
                Tab(text: 'My Drafts'),
                Tab(text: 'Generations'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AdvisingCourseSelectionTab(activeSem: activeSem),
              const AdvisingSavedDraftsTab(),
              const AdvisingGenerationHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionBadge(bool isGenerationActive) {
    final bool isDraftTab = !isGenerationActive && _tabController.index == 1;

    if (isDraftTab) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              'Draft: Capture Allowed',
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 12, color: Color(0xFFEF4444)),
          const SizedBox(width: 4),
          Text(
            'Protected',
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

