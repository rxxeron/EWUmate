import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/widgets/primitives/ewu_surface_card.dart';
import '../models/advising_guide_models.dart';
import 'advising_guide_notifier.dart';

class AdvisingGuideScreen extends ConsumerStatefulWidget {
  const AdvisingGuideScreen({super.key});

  @override
  ConsumerState<AdvisingGuideScreen> createState() => _AdvisingGuideScreenState();
}

class _AdvisingGuideScreenState extends ConsumerState<AdvisingGuideScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final state = ref.watch(advisingGuideNotifierProvider);
    final notifier = ref.read(advisingGuideNotifierProvider.notifier);

    return FullGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Course Advising Guide',
          style: GoogleFonts.sora(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.primaryCyan),
            tooltip: 'Refresh Advising Data',
            onPressed: () => notifier.loadAdvisingData(forceRefresh: true),
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingView(colors)
          : state.errorMessage != null
              ? _buildErrorView(colors, state.errorMessage!, notifier)
              : _buildContent(context, colors, state, notifier),
    );
  }

  Widget _buildLoadingView(EwuColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.primaryCyan,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing Degree Curriculum & Prerequisites...',
            style: GoogleFonts.sora(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(EwuColors colors, String error, AdvisingGuideNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Advising Guide',
              style: GoogleFonts.sora(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => notifier.loadAdvisingData(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EwuColors colors,
    AdvisingGuideState state,
    AdvisingGuideNotifier notifier,
  ) {
    final data = state.data!;
    final displayedCourses = state.displayedCourses;
    final progressPercent = data.totalDegreeCredits > 0
        ? (data.completedCredits / data.totalDegreeCredits).clamp(0.0, 1.0)
        : 0.0;

    return RefreshIndicator(
      color: colors.primaryCyan,
      backgroundColor: colors.surfaceNavyBlue,
      onRefresh: () => notifier.loadAdvisingData(forceRefresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Degree Curriculum Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _buildHeaderCard(colors, data, progressPercent),
            ),
          ),

          // 2. Search Field
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceNavyBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.borderSubtle,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearchQuery,
                  style: GoogleFonts.sora(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search course code or title (e.g. MAT, ICE)...',
                    hintStyle: GoogleFonts.sora(color: colors.textSecondary, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: colors.primaryCyan, size: 20),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: colors.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // 3. Tab Bar (Eligible, Locked, History, All)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _buildTabBar(colors, state, notifier, data),
            ),
          ),

          // 4. Area Filter Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.availableAreas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final area = state.availableAreas[index];
                  final isSelected = area == state.selectedArea;
                  return ChoiceChip(
                    label: Text(
                      area,
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.black : colors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colors.primaryCyan,
                    backgroundColor: colors.surfaceNavyBlue,
                    side: BorderSide(
                      color: isSelected ? colors.primaryCyan : colors.borderSubtle,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => notifier.setSelectedArea(area),
                  );
                },
              ),
            ),
          ),

          // 5. Results Counter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${displayedCourses.length} ${state.selectedTab == 0 ? "Eligible" : state.selectedTab == 1 ? "Locked" : state.selectedTab == 2 ? "History" : "Curriculum"} Courses',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (state.selectedArea != 'All')
                    Text(
                      state.selectedArea,
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: colors.primaryCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 6. Courses List
          displayedCourses.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(colors, state),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCourseCard(colors, displayedCourses[index]),
                      childCount: displayedCourses.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(EwuColors colors, AdvisingGuideData data, double progressPercent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primaryCyan.withValues(alpha: 0.4)),
                ),
                child: Text(
                  data.programCode,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.primaryCyan,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.programName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Degree progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed Credits',
                style: GoogleFonts.sora(fontSize: 11, color: colors.textSecondary),
              ),
              Text(
                '${data.completedCredits.toStringAsFixed(0)} / ${data.totalDegreeCredits.toStringAsFixed(0)} Cr (${(progressPercent * 100).toStringAsFixed(0)}%)',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 6,
              backgroundColor: colors.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primaryCyan),
            ),
          ),
          const SizedBox(height: 16),

          // Summary Stats Pills
          Row(
            children: [
              _buildStatPill(
                label: 'Eligible',
                count: data.eligibleCount,
                color: const Color(0xFF10B981),
                colors: colors,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                label: 'Locked',
                count: data.lockedCount,
                color: const Color(0xFFEF4444),
                colors: colors,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                label: 'Passed',
                count: data.completedCount,
                color: const Color(0xFF6366F1),
                colors: colors,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                label: 'Enrolled',
                count: data.enrolledCount,
                color: const Color(0xFF0EA5E9),
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required int count,
    required Color color,
    required EwuColors colors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 10,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(
    EwuColors colors,
    AdvisingGuideState state,
    AdvisingGuideNotifier notifier,
    AdvisingGuideData data,
  ) {
    final tabs = [
      {'title': 'Eligible', 'count': data.eligibleCount, 'color': const Color(0xFF10B981)},
      {'title': 'Locked', 'count': data.lockedCount, 'color': const Color(0xFFEF4444)},
      {'title': 'History', 'count': data.completedCount + data.enrolledCount, 'color': const Color(0xFF6366F1)},
      {'title': 'All', 'count': data.totalCurriculumCourses, 'color': colors.primaryCyan},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.borderSubtle,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = state.selectedTab == index;
          final tab = tabs[index];
          final color = tab['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () => notifier.setSelectedTab(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? Border.all(color: color.withValues(alpha: 0.4), width: 1.2) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab['title'] as String,
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? (colors.isDark ? Colors.white : color) : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? color : colors.borderSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${tab['count']}',
                        style: GoogleFonts.sora(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.black : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCourseCard(EwuColors colors, AdvisingCourseItem course) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (course.isEligible) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'ELIGIBLE';
      statusIcon = Icons.check_circle_rounded;
    } else if (course.isLocked) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'LOCKED';
      statusIcon = Icons.lock_rounded;
    } else if (course.isEnrolled) {
      statusColor = const Color(0xFF0EA5E9);
      statusLabel = 'IN PROGRESS';
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = const Color(0xFF6366F1);
      statusLabel = 'COMPLETED';
      statusIcon = Icons.verified_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: EwuSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Course Code + Status Badge + Credits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      course.code,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: course.isCompulsory
                            ? colors.primaryCyan.withValues(alpha: 0.12)
                            : colors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: course.isCompulsory
                              ? colors.primaryCyan.withValues(alpha: 0.3)
                              : colors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        course.isCompulsory ? 'Compulsory' : 'Elective',
                        style: GoogleFonts.sora(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: course.isCompulsory ? colors.primaryCyan : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.sora(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${course.credits.toStringAsFixed(1)} Cr',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Course Name
            Text(
              course.name,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),

            // Area Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: colors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                course.areaName,
                style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Specific Details based on Status
            if (course.isEligible) ...[
              if (course.prerequisites.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Prerequisites met: ',
                      style: GoogleFonts.sora(fontSize: 10, color: colors.textSecondary),
                    ),
                    ...course.fulfilledPrerequisites.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p,
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        )),
                  ],
                )
              else
                Text(
                  'No prerequisites required',
                  style: GoogleFonts.sora(fontSize: 10, color: const Color(0xFF10B981)),
                ),
            ] else if (course.isLocked) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: course.lockReasons.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.close_rounded, size: 13, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r,
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else if (course.isCompleted) ...[
              Row(
                children: [
                  if (course.grade != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Grade: ${course.grade}',
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF818CF8),
                        ),
                      ),
                    ),
                  if (course.semester != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      course.semester!,
                      style: GoogleFonts.sora(fontSize: 10, color: colors.textSecondary),
                    ),
                  ],
                  if (course.isRetakeEligible) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Retake Eligible',
                        style: GoogleFonts.sora(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (course.isEnrolled) ...[
              Row(
                children: [
                  const Icon(Icons.radio_button_checked_rounded, size: 12, color: Color(0xFF0EA5E9)),
                  const SizedBox(width: 4),
                  Text(
                    'Enrolled in current term • Unlocks downstream courses for next semester',
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(EwuColors colors, AdvisingGuideState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: colors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No courses found',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'No courses matching "${state.searchQuery}" in this category.'
                  : 'No courses in this area.',
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
