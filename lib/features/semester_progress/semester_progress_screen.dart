import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/auth_repository.dart';
import '../semester_progress/semester_summary_providers.dart';
import '../../core/repositories/course_repository.dart';
import '../../core/providers/scaffold_provider.dart';
import '../../core/providers/academic_providers.dart';
import 'semester_progress_repository.dart';
import 'course_progress_detail_screen.dart';
import 'widgets/course_progress_card.dart';

class SemesterProgressScreen extends ConsumerStatefulWidget {
  const SemesterProgressScreen({super.key});

  @override
  ConsumerState<SemesterProgressScreen> createState() => _SemesterProgressScreenState();
}

class _SemesterProgressScreenState extends ConsumerState<SemesterProgressScreen> {
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
        
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(
            ref.read(currentUserProvider)!.id, 
            semCode
          ),
          builder: (context, snapshot) {
            final courses = snapshot.data ?? [];
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

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
              body: isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : courses.isEmpty
                  ? const Center(child: Text('No courses enrolled this semester.', style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        final code = course['course_code'] ?? 'Course';
                        final meta = allMeta.where((m) => m.code == code).firstOrNull;

                        return CourseProgressCard(
                          courseData: course,
                          courseName: meta?.name ?? 'Loading Subject...',
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => CourseProgressDetailScreen(
                                courseData: course,
                                semesterCode: semCode,
                              ),
                            ));
                            // Refresh if needed
                            setState(() {});
                          },
                        );
                      },
                    ),
            );
          },
        );
      },
      loading: () => const Scaffold(backgroundColor: Color(0xFF0F172A), body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent))),
      error: (e, _) => Scaffold(backgroundColor: Color(0xFF0F172A), body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red)))),
    );
  }
}
