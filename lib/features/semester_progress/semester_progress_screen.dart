import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/repositories/auth_repository.dart';
import '../../core/services/cache_service.dart';
import '../../core/repositories/course_repository.dart';
import '../../core/providers/scaffold_provider.dart';
import '../../core/providers/academic_providers.dart';
import 'semester_progress_repository.dart';
import '../../core/models/course_metadata.dart';
import '../../core/utils/error_utils.dart';
import 'course_progress_detail_screen.dart';
import 'widgets/course_progress_card.dart';
import '../../core/utils/refresh_utils.dart';

class SemesterProgressScreen extends ConsumerStatefulWidget {
  const SemesterProgressScreen({super.key});

  @override
  ConsumerState<SemesterProgressScreen> createState() => _SemesterProgressScreenState();
}

class _SemesterProgressScreenState extends ConsumerState<SemesterProgressScreen> {
  Timer? _offlineHeartbeat;

  @override
  void initState() {
    super.initState();
    _offlineHeartbeat = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _pushSyncQueue();
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

  @override
  Widget build(BuildContext context) {
    final allMeta = ref.watch(allCoursesProvider).valueOrNull ?? [];
    final currentSemAsync = ref.watch(currentSemesterCodeProvider);

    return currentSemAsync.when(
      data: (semCode) {
        if (semCode == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: Text('No active semester found.', style: TextStyle(color: Colors.white))),
          );
        }
        
        final user = ref.read(currentUserProvider);
        if (user == null) return const SizedBox.shrink();

        final progressAsync = ref.watch(semesterProgressDataProvider(semCode));

        return progressAsync.when(
          data: (courses) {
            return Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              appBar: AppBar(
                title: Column(
                  children: [
                    const Text(
                      'Academic Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      semCode,
                      style: const TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
                ),
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  await _pushSyncQueue();
                  RefreshUtils.refreshAcademicData(ref);
                  ref.invalidate(semesterProgressDataProvider(semCode));
                },
                color: Colors.cyanAccent,
                backgroundColor: const Color(0xFF1E293B),
                child: courses.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: const Center(child: Text('No courses enrolled this semester.', style: TextStyle(color: Colors.white54))),
                        ),
                      )
                    : CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: (0.68 / MediaQuery.textScalerOf(context).scale(1.0)).clamp(0.5, 0.68),
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
                                            await Navigator.push(context, MaterialPageRoute(
                                              builder: (context) => CourseProgressDetailScreen(
                                                courseData: course,
                                                semesterCode: semCode,
                                              ),
                                            ));
                                            // UI will refresh automatically because it watches semesterProgressDataProvider
                                          },
                                        );
                                      }
                                    );
                                  },
                                  childCount: courses.length,
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            );
          },
          loading: () => Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(title: const Text('Academic Progress'), backgroundColor: Colors.transparent, elevation: 0),
            body: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          ),
          error: (e, _) => Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(title: const Text('Academic Progress'), backgroundColor: Colors.transparent, elevation: 0),
            body: Center(child: Text(AuthErrorUtils.getFriendlyMessage(e), style: const TextStyle(color: Colors.redAccent))),
          ),
        );
      },
      loading: () => const Scaffold(backgroundColor: Color(0xFF0F172A), body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent))),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              AuthErrorUtils.getFriendlyMessage(e),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

}
