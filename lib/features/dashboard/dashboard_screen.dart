import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/task.dart';
import '../../core/providers/scaffold_provider.dart';
import '../../core/services/fcm_service.dart';
import '../../core/theme/ewu_theme_extension.dart';
import '../../core/utils/time_utils.dart';
import '../../core/widgets/animations/fade_in_slide.dart';
import '../../core/widgets/animations/skeleton_loader.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/onboarding_overlay.dart';
import '../../core/constants/onboarding_steps.dart';
import '../../core/widgets/playstore_review_dialog.dart';
import '../auth/auth_providers.dart';
import '../tasks/presentation/widgets/add_task_bottom_sheet.dart';
import 'controllers/dashboard_controller.dart';
import 'dashboard_logic.dart';
import 'widgets/dashboard_banner_tray.dart';
import 'widgets/dashboard_exam_timeline.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_overdue_checkpoint.dart';
import 'widgets/dashboard_schedule_timeline.dart';
import 'widgets/dashboard_tasks_preview.dart';
import 'widgets/pending_attendance_widget.dart';
import 'widgets/remote_promo_banner.dart';

/// Clean, modularized DashboardScreen (<250 lines).
/// Delegates data mutations, caching, and background jobs to [DashboardController].
class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSeeAllTasks;

  const DashboardScreen({super.key, this.onSeeAllTasks});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final DashboardController _controller = DashboardController(
    onStateChanged: () {
      if (mounted) setState(() {});
    },
  );

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _controller.refreshDashboard(ref: ref).then((_) {
      _checkAndShowPendingNotifications();
    });
    _showDashboardTutorial();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PlayStoreReviewDialog.checkAndShow(context);
        ref.read(fcmServiceProvider).syncToken();
      }
    });

    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _controller.refreshDashboard(ref: ref, isSilent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _checkAndShowPendingNotifications() {
    if (_controller.state.loadingInit) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final fcmService = ref.read(fcmServiceProvider);
        fcmService.isDashboardStable = true;

        final pending = fcmService.pendingAction;
        if (pending != null) {
          debugPrint("[FCM] Executing pending notification click inside stable Dashboard Screen");
          fcmService.showNotificationPopup(pending.title, pending.body, pending.url);
          fcmService.clearPendingAction();
        }
      }
    });
  }

  void _showDashboardTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingOverlay.show(
        context: context,
        featureKey: OnboardingSteps.dashboardKey,
        steps: OnboardingSteps.dashboard,
      );
    });
  }

  void _showTaskEditor(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTaskBottomSheet(
          existingTask: Task.fromJson(item),
        ),
      ),
    ).then((result) {
      if (result == true) {
        _controller.refreshDashboard(ref: ref);
      }
    });
  }

  Future<void> _markAttendanceForNextClass(ScheduleItem item) async {
    try {
      await _controller.markAttendanceForNextClass(ref: ref, item: item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attended ${item.courseCode} (${item.sessionType})!', style: GoogleFonts.sora()),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not mark attendance: $e', style: GoogleFonts.sora()),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  Future<void> _markSingleAttendance(Map<String, dynamic> item, String status) async {
    try {
      await _controller.markSingleAttendance(ref: ref, item: item, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['course_code']} (${item['session_type']}) marked as ${status == 'joined' ? 'attended' : 'missed'}!'),
            backgroundColor: status == 'joined' ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markMultipleAttendance(List<Map<String, dynamic>> items, String status) async {
    try {
      final count = await _controller.markMultipleAttendance(ref: ref, items: items, status: status);
      if (mounted && count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count session(s) marked as ${status == 'joined' ? 'attended' : 'missed'}!'),
            backgroundColor: status == 'joined' ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _controller.user;
    if (user == null) {
      return const Center(child: Text("Please log in"));
    }

    final state = _controller.state;

    if (state.loadingInit) {
      return Container(
        color: Colors.transparent,
        child: Column(
          children: [
            const EWUmateAppBar(title: "EWUmate", showMenu: true),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    SkeletonLoader(width: double.infinity, height: 100, margin: EdgeInsets.all(20), borderRadius: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonLoader(width: 150, height: 24),
                          SkeletonLoader(width: 100, height: 18),
                        ],
                      ),
                    ),
                    SkeletonLoader(width: double.infinity, height: 140, margin: EdgeInsets.all(20), borderRadius: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: SkeletonLoader(width: 150, height: 24),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SkeletonLoader(width: double.infinity, height: 80, margin: EdgeInsets.only(bottom: 12), borderRadius: 20),
                          SkeletonLoader(width: double.infinity, height: 80, margin: EdgeInsets.only(bottom: 12), borderRadius: 20),
                          SkeletonLoader(width: double.infinity, height: 80, margin: EdgeInsets.only(bottom: 12), borderRadius: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final colors = context.ewuColors;
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final greeting = TimeUtils.getGreeting();

    String displayName = profile?.nickname ?? "";
    if (displayName.isEmpty) {
      displayName = profile?.fullName?.split(' ').first ?? "";
    }
    if (displayName.isEmpty) {
      displayName = user.userMetadata?['full_name']?.toString().split(' ').first ?? "Student";
    }

    final photoUrl = profile?.photoUrl ?? user.userMetadata?['avatar_url'] ?? user.userMetadata?['photoURL'];

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          EWUmateAppBar(
            title: "EWUmate",
            showMenu: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => _controller.refreshDashboard(ref: ref, isSilent: false),
              ),
            ],
          ),
          DashboardHeader(
            greeting: greeting,
            displayName: displayName,
            photoUrl: photoUrl?.toString(),
            email: user.email,
            onAvatarTap: () => ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _controller.refreshDashboard(ref: ref, isSilent: false),
              color: colors.primaryCyan,
              backgroundColor: colors.surfaceNavyBlue,
              child: state.lastValidScheduleData == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              "Unable to connect to EWUmate.\nNo offline data found. Pull to refresh.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FadeInSlide(
                            delay: const Duration(milliseconds: 25),
                            child: DashboardBannerTray(
                              showUpdateBanner: state.showUpdateBanner,
                              updateUrl: state.isPlayStoreUser
                                  ? 'https://play.google.com/store/apps/details?id=com.rxxeron.ewumate'
                                  : (state.customApkUrl.isNotEmpty
                                      ? state.customApkUrl
                                      : 'https://play.google.com/store/apps/details?id=com.rxxeron.ewumate'),
                              onDismissUpdate: () => _controller.dismissUpdateBanner(),
                              showAdvisingBanner: state.showAdvisingBanner,
                              onAdvisingTap: () => context.push('/advising'),
                              semConfig: state.semConfig,
                            ),
                          ),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 75),
                            child: DashboardExamTimeline(
                              tasks: state.tasks,
                              onExamTap: (exam) => _showTaskEditor(exam),
                            ),
                          ),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 150),
                            child: DashboardOverdueCheckpoint(
                              tasks: state.tasks,
                              onComplete: (taskId) => _controller.markTaskCompleted(ref: ref, taskId: taskId),
                              onMiss: (taskId) => _controller.markTaskMissed(ref: ref, taskId: taskId),
                              onReschedule: (task) => _showTaskEditor(task),
                            ),
                          ),
                          const FadeInSlide(
                            delay: Duration(milliseconds: 200),
                            child: RemotePromoBanner(),
                          ),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 250),
                            child: DashboardScheduleTimeline(
                              data: DashboardLogic.processDashboardData(state.lastValidScheduleData!),
                              onScheduleManagerTap: () => context.push('/schedule-manager'),
                              onMarkAttendance: (item) => _markAttendanceForNextClass(item),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 350),
                            child: PendingAttendanceWidget(
                              items: state.pendingAttendanceItems,
                              isSaving: state.isSavingAttendance,
                              onMarkSingle: (item, status) => _markSingleAttendance(item, status),
                              onMarkMultiple: (items, status) => _markMultipleAttendance(items, status),
                            ),
                          ),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 450),
                            child: DashboardTasksPreview(
                              tasks: state.tasks,
                              onSeeAll: widget.onSeeAllTasks ?? () => context.push('/tasks'),
                              onTaskTap: (t) => _showTaskEditor(t),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
