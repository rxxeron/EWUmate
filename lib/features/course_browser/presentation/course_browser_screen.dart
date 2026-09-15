import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ewumate/core/models/course_metadata.dart';
import 'package:ewumate/core/utils/course_utils.dart';
import '../../../core/repositories/course_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/widgets/animations/skeleton_loader.dart';
import 'widgets/course_card.dart';
import 'providers/course_browser_providers.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

class CourseBrowserScreen extends ConsumerStatefulWidget {
  const CourseBrowserScreen({super.key});

  @override
  ConsumerState<CourseBrowserScreen> createState() => _CourseBrowserScreenState();
}

class _CourseBrowserScreenState extends ConsumerState<CourseBrowserScreen> {
  late ScrollController _scrollController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(userEnrollmentsProvider);
        ref.invalidate(browserAvailableCoursesProvider);
        ref.invalidate(paginatedCoursesProvider);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.courseBrowserKey,
          steps: OnboardingSteps.courseBrowser,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedCoursesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(courseBrowserTabProvider);
    final scope = ref.watch(selectedSemesterScopeProvider);
    final isUpcoming = scope == SemesterScope.upcoming;

    final currentSemAsync = ref.watch(currentSemCodeProvider);
    final nextSemAsync = ref.watch(nextSemCodeProvider);
    final currentSem = currentSemAsync.valueOrNull ?? '';
    final nextSem = nextSemAsync.valueOrNull ?? '';

    final targetSemAsync = ref.watch(selectedBrowserSemesterCodeProvider);
    final targetSem = targetSemAsync.valueOrNull ?? (isUpcoming ? nextSem : currentSem);

    return FullGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Course Browser',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      onChanged: (val) => ref.read(courseSearchQueryProvider.notifier).state = val,
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search course code (e.g. CSE101)...',
                        hintStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryCyan, size: 22),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavyBlue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: AppColors.primaryCyan, size: 20),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Semester Scope Switcher (Active vs Upcoming)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavyBlue.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildScopeButton(
                      title: 'Active Term',
                      subtitle: currentSem.isNotEmpty ? CourseUtils.cleanSemester(currentSem) : 'Current',
                      icon: Icons.calendar_month_rounded,
                      isActive: !isUpcoming,
                      onTap: () {
                        if (isUpcoming) {
                          ref.read(selectedSemesterScopeProvider.notifier).state = SemesterScope.active;
                          ref.invalidate(browserAvailableCoursesProvider);
                          ref.invalidate(userEnrollmentsProvider);
                          ref.invalidate(userEnrollmentDetailsProvider);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildScopeButton(
                      title: 'Upcoming Term',
                      subtitle: nextSem.isNotEmpty ? CourseUtils.cleanSemester(nextSem) : 'Next',
                      icon: Icons.bookmark_add_rounded,
                      isActive: isUpcoming,
                      onTap: () {
                        if (!isUpcoming) {
                          ref.read(selectedSemesterScopeProvider.notifier).state = SemesterScope.upcoming;
                          ref.invalidate(browserAvailableCoursesProvider);
                          ref.invalidate(userEnrollmentsProvider);
                          ref.invalidate(userEnrollmentDetailsProvider);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // 3. Filter Tabs (Segmented Glass Pills)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavyBlue.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabChip('Available', activeTab == 'available')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabChip(
                      isUpcoming ? 'Upcoming Planned' : 'Taken', 
                      activeTab == 'taken' || (isUpcoming && activeTab == 'upcoming planned'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // 4. Semester Context Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GlassContainer(
              borderRadius: 14,
              borderColor: isUpcoming 
                  ? Colors.tealAccent.withValues(alpha: 0.3)
                  : AppColors.primaryCyan.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isUpcoming ? Colors.tealAccent : AppColors.primaryCyan).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isUpcoming ? Icons.auto_awesome_rounded : Icons.calendar_today_rounded, 
                      color: isUpcoming ? Colors.tealAccent : AppColors.primaryCyan, 
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUpcoming
                              ? 'Upcoming: ${CourseUtils.cleanSemester(targetSem)}'
                              : 'Active: ${CourseUtils.cleanSemester(targetSem)}',
                          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          isUpcoming
                              ? 'Tap Select on any course section to view details & save to upcoming enrollments.'
                              : 'Browse offerings & manage your enrolled classes.',
                          style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 5. Results List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(browserAvailableCoursesProvider);
                ref.invalidate(userEnrollmentsProvider);
                ref.invalidate(courseSearchResultProvider);
                ref.read(paginatedCoursesProvider.notifier).build();
              },
              color: AppColors.primaryCyan,
              backgroundColor: AppColors.surfaceNavyBlue,
              child: (activeTab == 'available') 
                  ? _buildAvailableList(targetSem) 
                  : _buildTakenList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF04101E) : Colors.white70,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      color: isActive ? const Color(0xFF04101E) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(
                      color: isActive ? const Color(0xFF04101E).withValues(alpha: 0.8) : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label.toLowerCase().contains('upcoming') || label.toLowerCase() == 'taken') {
          ref.read(courseBrowserTabProvider.notifier).state = 'taken';
        } else {
          ref.read(courseBrowserTabProvider.notifier).state = 'available';
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive) ...[
              const Icon(Icons.check_rounded, size: 16, color: Color(0xFF04101E)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.sora(
                color: isActive ? const Color(0xFF04101E) : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableList(String targetSem) {
    final searchQuery = ref.watch(courseSearchQueryProvider);

    if (searchQuery.isNotEmpty) {
      final searchResult = ref.watch(courseSearchResultProvider);
      return searchResult.when(
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: AppColors.secondaryText.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text('No courses found matching "$searchQuery"', style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: courses.length,
            itemBuilder: (context, index) => CourseCard(
              key: ValueKey(courses[index].code),
              course: courses[index],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
        error: (e, _) => Center(child: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora(color: Colors.redAccent))),
      );
    }

    final availableCourses = ref.watch(filteredAvailableCoursesProvider);
    return availableCourses.when(
      data: (courses) {
        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off_rounded, size: 48, color: AppColors.secondaryText.withValues(alpha: 0.6)),
                const SizedBox(height: 12),
                Text('No courses match your active filters.', style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 14)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: courses.length,
          itemBuilder: (context, index) => CourseCard(
            key: ValueKey(courses[index].code),
            course: courses[index],
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: CardSkeleton(),
        ),
      ),
      error: (e, _) => Center(child: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora(color: Colors.redAccent))),
    );
  }

  Widget _buildTakenList() {
    final user = ref.watch(currentUserProvider);
    final scope = ref.watch(selectedSemesterScopeProvider);
    final isUpcoming = scope == SemesterScope.upcoming;

    if (user == null) {
      return Center(
        child: Text('Please log in to view taken courses.', style: GoogleFonts.sora(color: AppColors.secondaryText)),
      );
    }

    final enrollmentsAsync = ref.watch(userEnrollmentsProvider);

    return enrollmentsAsync.when(
      data: (enrolledCodes) {
        if (enrolledCodes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUpcoming ? Icons.bookmark_border_rounded : Icons.school_outlined, 
                    size: 48, 
                    color: AppColors.secondaryText.withValues(alpha: 0.6)
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUpcoming 
                        ? 'No upcoming courses selected yet.\nBrowse courses in the Available tab and tap Select to save your upcoming section!'
                        : 'No enrolled courses recorded.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<List<CourseMetadata>>(
          future: _getEnrolledMetas(enrolledCodes),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan));
            }
            final metas = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: metas.length,
              itemBuilder: (context, index) => CourseCard(
                key: ValueKey(metas[index].code),
                course: metas[index],
                isEnrolledView: true,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      error: (e, _) => Center(child: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora(color: Colors.redAccent))),
    );
  }

  Future<List<CourseMetadata>> _getEnrolledMetas(List<String> codes) async {
    final repo = ref.read(courseRepositoryProvider);
    final List<CourseMetadata> metas = [];
    for (var code in codes) {
      final results = await repo.searchCourses(code);
      final match = results.firstWhere(
        (c) => CourseUtils.areEquivalent(c.code, code), 
        orElse: () => results.isNotEmpty ? results.first : null as dynamic
      );
      metas.add(match);
    }
    return metas;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(courseBrowserFilterProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C192E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Courses',
                  style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(courseBrowserFilterProvider.notifier).state = CourseBrowserFilter();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.sora(color: AppColors.primaryCyan, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Credit Units',
              style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: ['1.0', '1.5', '3.0', '4.0'].map((c) {
                final isSelected = filter.credits == c;
                return ChoiceChip(
                  label: Text(
                    '$c Cr',
                    style: GoogleFonts.sora(
                      color: isSelected ? const Color(0xFF04101E) : Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    ref.read(courseBrowserFilterProvider.notifier).update((s) => s.copyWith(credits: val ? c : null, clearCredits: !val));
                  },
                  selectedColor: AppColors.primaryCyan,
                  backgroundColor: AppColors.surfaceNavyBlue,
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryCyan : Colors.white.withValues(alpha: 0.1),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Apply Filters',
                  style: GoogleFonts.sora(
                    color: const Color(0xFF04101E),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

