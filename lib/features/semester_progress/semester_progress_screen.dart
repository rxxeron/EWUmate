import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../core/repositories/auth_repository.dart';
import '../../core/services/cache_service.dart';
import '../../core/repositories/course_repository.dart';
import '../../core/providers/scaffold_provider.dart';
import '../../core/providers/academic_providers.dart';
import '../../core/models/semester_course_marks.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ewu_theme_extension.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/primitives/ewu_empty_state.dart';
import '../../core/models/course_metadata.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/refresh_utils.dart';
import '../../core/widgets/onboarding_overlay.dart';
import '../../core/constants/onboarding_steps.dart';
import 'semester_progress_repository.dart';
import 'course_progress_detail_screen.dart';
import 'widgets/course_progress_card.dart';

class SemesterProgressScreen extends ConsumerStatefulWidget {
  const SemesterProgressScreen({super.key});

  @override
  ConsumerState<SemesterProgressScreen> createState() => _SemesterProgressScreenState();
}

class _SemesterProgressScreenState extends ConsumerState<SemesterProgressScreen> {
  Timer? _offlineHeartbeat;
  String? _overrideSemesterCode;

  @override
  void initState() {
    super.initState();
    _offlineHeartbeat = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _pushSyncQueue();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.semesterProgressKey,
          steps: OnboardingSteps.semesterProgress,
        );
      }
    });
  }

  Future<void> _pushSyncQueue() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final cacheService = ref.read(cacheServiceProvider);
    final repo = ref.read(semesterProgressRepositoryProvider);
    final queue = cacheService.getSyncQueue(user.id);
    
    if (queue.isEmpty) return;

    bool anySuccess = false;
    final Set<String> updatedSemesters = {};
    for (final item in queue) {
      if (item['action'] == 'save_course_marks') {
        try {
          final sem = item['semesterCode']?.toString() ?? '';
          await repo.saveCourseMarks(user.id, sem, Map<String, dynamic>.from(item['data']));
          await cacheService.removeQueueItem(user.id, item['data']['course_code']); 
          if (sem.isNotEmpty) updatedSemesters.add(sem);
          anySuccess = true;
        } catch (e) {
          if (kDebugMode) debugPrint('[Offline Sync] Still offline for semester marks');
        }
      }
    }
    
    if (anySuccess && mounted) {
      RefreshUtils.refreshAcademicData(ref);
      for (final sem in updatedSemesters) {
        ref.invalidate(semesterProgressDataProvider(sem));
      }
    }
  }

  @override
  void dispose() {
    _offlineHeartbeat?.cancel();
    super.dispose();
  }

  String _formatSemesterTitle(String raw) {
    return raw.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final allMeta = ref.watch(allCoursesProvider).valueOrNull ?? [];
    final currentSemAsync = ref.watch(currentSemesterCodeProvider);
    final allSemestersAsync = ref.watch(semestersProvider);

    return currentSemAsync.when(
      data: (defaultSemCode) {
        final activeSemCode = _overrideSemesterCode ?? defaultSemCode;
        if (activeSemCode == null) {
          return FullGradientScaffold(
            body: Center(
              child: Text(
                'No active semester found.',
                style: GoogleFonts.sora(color: colors.textSecondary),
              ),
            ),
          );
        }
        
        final user = ref.read(currentUserProvider);
        if (user == null) return const SizedBox.shrink();

        final progressAsync = ref.watch(semesterProgressDataProvider(activeSemCode));

        return FullGradientScaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.menu_rounded, color: colors.textPrimary),
              onPressed: () => ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
            ),
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  'Academic Progress',
                  style: GoogleFonts.sora(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                // Interactive Semester Selector Pill
                GestureDetector(
                  onTap: () => _showSemesterPicker(
                    context, 
                    activeSemCode, 
                    allSemestersAsync.valueOrNull ?? [],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surfaceNavyBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.primaryCyan.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatSemesterTitle(activeSemCode),
                          style: GoogleFonts.sora(
                            color: colors.primaryCyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: colors.primaryCyan,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _pushSyncQueue();
                  RefreshUtils.refreshAcademicData(ref);
                  ref.invalidate(semesterProgressDataProvider(activeSemCode));
                },
              ),
            ],
          ),
          body: progressAsync.when(
            data: (courses) {
              // Calculate status metrics across enrolled courses
              int onTrackCount = 0;
              int atRiskCount = 0;
              int needsAttentionCount = 0;

              for (final c in courses) {
                final safe = Map<String, dynamic>.from(c);
                safe['id'] ??= 'fallback';
                safe['user_id'] ??= user.id;
                safe['semester_code'] ??= activeSemCode;
                safe['course_code'] ??= c['course_code'] ?? '';
                final model = SemesterCourseMarks.fromJson(safe);
                final obtained = model.totalObtained;

                if (obtained >= 60) {
                  onTrackCount++;
                } else if (obtained >= 45) {
                  atRiskCount++;
                } else if (obtained > 0) {
                  needsAttentionCount++;
                } else {
                  // If marks have not been added yet, treat as on track
                  onTrackCount++;
                }
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await _pushSyncQueue();
                  RefreshUtils.refreshAcademicData(ref);
                  ref.invalidate(semesterProgressDataProvider(activeSemCode));
                },
                color: colors.primaryCyan,
                backgroundColor: colors.surfaceNavyBlue,
                child: courses.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: EwuEmptyState(
                              title: 'No Courses Enrolled',
                              subtitle: 'No enrolled courses found for ${_formatSemesterTitle(activeSemCode)}.',
                              icon: Icons.school_outlined,
                              actionLabel: 'Sync Portal Routine',
                              onAction: () async {
                                await _pushSyncQueue();
                                RefreshUtils.refreshAcademicData(ref);
                                ref.invalidate(semesterProgressDataProvider(activeSemCode));
                              },
                            ),
                          ),
                        ),
                      )
                    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // 4 Horizontal Status Metric Chips
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14.0, bottom: 12.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    _buildMetricChip(
                                      colors: colors,
                                      label: 'Total Courses',
                                      value: '${courses.length}',
                                      accentColor: colors.primaryCyan,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildMetricChip(
                                      colors: colors,
                                      label: 'On Track',
                                      value: '$onTrackCount',
                                      accentColor: const Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildMetricChip(
                                      colors: colors,
                                      label: 'At Risk',
                                      value: '$atRiskCount',
                                      accentColor: const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildMetricChip(
                                      colors: colors,
                                      label: 'Needs Attention',
                                      value: '$needsAttentionCount',
                                      accentColor: const Color(0xFFF43F5E),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Section Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Enrolled Courses (${courses.length})',
                                    style: GoogleFonts.sora(
                                      color: colors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Tap to view marks breakdown',
                                    style: GoogleFonts.sora(
                                      color: colors.secondaryText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Course Progress Cards (Responsive 2x2 Grid that grows together)
                          () {
                            final int maxMarksCount = _calculateMaxMarksCount(courses);
                            final double baseRatio = switch (maxMarksCount) {
                              0 => 1.18,
                              1 => 1.08,
                              2 => 0.98,
                              3 => 0.90,
                              4 => 0.83,
                              5 => 0.77,
                              6 => 0.72,
                              7 => 0.67,
                              8 => 0.63,
                              _ => 0.58,
                            };

                            final screenWidth = MediaQuery.sizeOf(context).width;
                            final int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
                            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                            final double effectiveRatio = ((baseRatio * (crossAxisCount == 2 ? 1.0 : 1.15)) / textScale).clamp(0.48, 1.30);

                            return SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: effectiveRatio,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                  final course = courses[index];
                                  final code = course['course_code'] ?? 'Course';
                                  final meta = allMeta.where((m) => m.code == code).firstOrNull;

                                  return FutureBuilder<List<CourseMetadata>>(
                                    future: meta == null
                                        ? ref.read(courseRepositoryProvider).searchCourses(code)
                                        : Future.value([meta]),
                                    builder: (context, metaSnapshot) {
                                      final foundMeta = metaSnapshot.data?.firstOrNull;
                                      return CourseProgressCard(
                                        courseData: course,
                                        courseName: foundMeta?.name ?? 'Loading Subject...',
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CourseProgressDetailScreen(
                                                courseData: course,
                                                semesterCode: activeSemCode,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                childCount: courses.length,
                              ),
                            ),
                          );
                        }(),
                        ],
                      ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: colors.primaryCyan),
            ),
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
          ),
        );
      },
      loading: () => FullGradientScaffold(
        body: Center(child: CircularProgressIndicator(color: colors.primaryCyan)),
      ),
      error: (e, _) => FullGradientScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              AuthErrorUtils.getFriendlyMessage(e),
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required EwuColors colors,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark
              ? accentColor.withValues(alpha: 0.28)
              : colors.borderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  color: colors.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.sora(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateMaxMarksCount(List<Map<String, dynamic>> courses) {
    int maxMarks = 0;
    for (final c in courses) {
      int count = 0;
      final qArr = c['obt_quizzes'];
      if (qArr is List) {
        count += qArr.where((v) => _hasMark(v)).length;
      }
      final sqArr = c['obt_short_quizzes'];
      if (sqArr is List) {
        count += sqArr.where((v) => _hasMark(v)).length;
      }
      for (final key in [
        'obt_mid',
        'obt_final',
        'obt_lab',
        'obt_assignment',
        'obt_presentation',
        'obt_project',
        'obt_viva',
        'obt_attendance',
        'obt_class_performance',
        'obt_term_paper',
        'obt_optional_1',
        'obt_optional_2',
        'obt_optional_3',
      ]) {
        if (_hasMark(c[key])) count++;
      }
      final att = c['attendance'];
      if (att is Map && att.isNotEmpty) {
        count += 1;
      }
      if (count > maxMarks) maxMarks = count;
    }
    return maxMarks;
  }

  bool _hasMark(dynamic val) {
    if (val == null) return false;
    if (val is String) {
      final trimmed = val.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return false;
      return double.tryParse(trimmed) != null;
    }
    if (val is num) return true;
    return false;
  }

  void _showSemesterPicker(
    BuildContext context, 
    String currentCode, 
    List<dynamic> allSemesters,
  ) {
    final colors = context.ewuColors;
    final titles = allSemesters.map((e) => e.title.toString()).toSet().toList();
    if (!titles.contains(currentCode)) {
      titles.insert(0, currentCode);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF09182D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Semester',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ...titles.map((title) {
                final isSelected = title == currentCode;
                return ListTile(
                  title: Text(
                    _formatSemesterTitle(title),
                    style: GoogleFonts.sora(
                      color: isSelected ? colors.primaryCyan : Colors.white,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: colors.primaryCyan)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    setState(() {
                      _overrideSemesterCode = title;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
