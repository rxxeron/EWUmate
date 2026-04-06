import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ewumate_v2/core/models/course_metadata.dart';
import 'package:ewumate_v2/core/providers/academic_providers.dart';
import 'package:ewumate_v2/core/utils/course_utils.dart';
import '../../../core/repositories/course_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/widgets/animations/skeleton_loader.dart';
import 'widgets/course_card.dart';
import 'providers/course_browser_providers.dart';

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
            child: TextField(
              onChanged: (val) => ref.read(courseSearchQueryProvider.notifier).state = val,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by course code or name...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
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
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      );
    }

    final availableCourses = ref.watch(browserAvailableCoursesProvider);
    return availableCourses.when(
      data: (courses) {
        if (courses.isEmpty) return const Center(child: Text('No courses offered in this track for the upcoming semester.', style: TextStyle(color: Colors.grey)));
        
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
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
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
      error: (e, _) => Center(child: Text('Error fetching enrollments: $e')),
    );
  }

  Future<List<CourseMetadata>> _getEnrolledMetas(List<String> codes) async {
    final repo = ref.read(courseRepositoryProvider);
    final List<CourseMetadata> metas = [];
    for (var code in codes) {
      final results = await repo.searchCourses(code);
      // Use CourseUtils for absolute precision in matching 3-digit vs 4-digit codes
      final match = results.firstWhere(
        (c) => CourseUtils.areEquivalent(c.code, code), 
        orElse: () => results.isNotEmpty ? results.first : null as dynamic
      );
      if (match != null) metas.add(match);
    }
    return metas;
  }
}
