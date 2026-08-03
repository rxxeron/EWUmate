import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ewumate/core/models/course_metadata.dart';
import 'package:ewumate/core/utils/course_utils.dart';
import '../../../core/repositories/course_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/widgets/animations/skeleton_loader.dart';
import 'widgets/course_card.dart';
import 'providers/course_browser_providers.dart';
import '../../../core/utils/error_utils.dart';

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
      // Logic for pagination if needed in future
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(courseBrowserTabProvider);
    final currentSemAsync = ref.watch(currentSemCodeProvider);
    final nextSemAsync = ref.watch(nextSemCodeProvider);
    
    final currentSem = currentSemAsync.valueOrNull ?? '';
    final nextSem = nextSemAsync.valueOrNull ?? '';
    final activeSemDisplay = activeTab == 'taken' ? currentSem : nextSem;

    return Scaffold(
      backgroundColor: const Color(0xFF16202A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Course Browser', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => ref.read(courseSearchQueryProvider.notifier).state = val,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search course code...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                      filled: true,
                      fillColor: const Color(0xFF1E2836).withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2836).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Color(0xFF00E5FF)),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 2. Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildTabChip('Available', activeTab == 'available'),
                const SizedBox(width: 12),
                _buildTabChip('Taken', activeTab == 'taken'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 3. Active Semester Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2836).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   Icon(Icons.calendar_month, color: Color(0xFF00E5FF), size: 18),
                   const SizedBox(width: 12),
                   Text(
                     'Active: $currentSem',
                     style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.w600),
                   ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Results List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(browserAvailableCoursesProvider);
                ref.invalidate(userEnrollmentsProvider);
                ref.invalidate(courseSearchResultProvider);
                ref.read(paginatedCoursesProvider.notifier).build();
              },
              color: const Color(0xFF00E5FF),
              backgroundColor: const Color(0xFF1E2836),
              child: activeTab == 'available' 
                  ? _buildAvailableList(currentSem) 
                  : _buildTakenList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () => ref.read(courseBrowserTabProvider.notifier).state = label.toLowerCase(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00E5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          children: [
            if (isActive) ...[
              const Icon(Icons.check, size: 16, color: Colors.black),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
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
            return const Center(child: Text('No courses found.', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: courses.length,
            itemBuilder: (context, index) => CourseCard(
              key: ValueKey(courses[index].code),
              course: courses[index],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
        error: (e, _) => Center(child: Text(AuthErrorUtils.getFriendlyMessage(e), style: const TextStyle(color: Colors.red))),
      );
    }

    final availableCourses = ref.watch(filteredAvailableCoursesProvider);
    return availableCourses.when(
      data: (courses) {
        if (courses.isEmpty) return const Center(child: Text('No courses match your filters.', style: TextStyle(color: Colors.grey)));
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: courses.length,
          itemBuilder: (context, index) => CourseCard(
            key: ValueKey(courses[index].code),
            course: courses[index],
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: CardSkeleton(),
        ),
      ),
      error: (e, _) => Center(child: Text(AuthErrorUtils.getFriendlyMessage(e), style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildTakenList() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('Please log in.'));

    final enrollmentsAsync = ref.watch(userEnrollmentsProvider);
    final allCoursesAsync = ref.watch(paginatedCoursesProvider); // Use paginated as a base if small, or Search

    return enrollmentsAsync.when(
      data: (enrolledCodes) {
        if (enrolledCodes.isEmpty) {
          return const Center(child: Text('No enrolled courses currently.', style: TextStyle(color: Colors.grey)));
        }

        return FutureBuilder<List<CourseMetadata>>(
          future: _getEnrolledMetas(enrolledCodes),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
            }
            final metas = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
      error: (e, _) => Center(child: Text(AuthErrorUtils.getFriendlyMessage(e))),
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
      backgroundColor: const Color(0xFF1E2836),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Advanced Filters', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  ref.read(courseBrowserFilterProvider.notifier).state = CourseBrowserFilter();
                  Navigator.pop(context);
                },
                child: const Text('Reset', style: TextStyle(color: Color(0xFF00E5FF))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('By Credits', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: ['1.0', '1.5', '3.0', '4.0'].map((c) {
              final isSelected = filter.credits == c;
              return ChoiceChip(
                label: Text(c),
                selected: isSelected,
                onSelected: (val) {
                  ref.read(courseBrowserFilterProvider.notifier).update((s) => s.copyWith(credits: val ? c : null, clearCredits: !val));
                },
                selectedColor: const Color(0xFF00E5FF),
                labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                backgroundColor: const Color(0xFF16202A),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
