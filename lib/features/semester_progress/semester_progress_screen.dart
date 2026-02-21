import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/semester_progress_models.dart';
import '../../core/models/course_model.dart';
import '../calendar/academic_repository.dart';
import '../course_browser/course_repository.dart';
import 'semester_progress_repository.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/utils/course_utils.dart';
import 'course_marks_screen.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/animations/loading_shimmer.dart';
import '../../core/widgets/animations/fade_in_slide.dart';

class SemesterProgressScreen extends StatefulWidget {
  const SemesterProgressScreen({super.key});

  @override
  State<SemesterProgressScreen> createState() => _SemesterProgressScreenState();
}

class _SemesterProgressScreenState extends State<SemesterProgressScreen> {
  final SemesterProgressRepository _progressRepo = SemesterProgressRepository();
  final AcademicRepository _academicRepo = AcademicRepository();
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String _semesterCode = '';
  // Map of CourseCode -> CourseProgressData (basic info)
  Map<String, CourseProgressData> _coursesMap = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Get Semester (Cached)
      _semesterCode = await _academicRepo.getCurrentSemesterCode();

      // 2. Get User Enrolled sections (Cached)
      final profileData = await CourseRepository().fetchUserData();
      final enrolledIds = List<String>.from(profileData['enrolled_sections'] ?? []);

      if (enrolledIds.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // 3. Fetch Course Info (Cached)
      final List<Course> enrolledCourses = await CourseRepository().fetchCoursesByIds(
        _semesterCode,
        enrolledIds,
      );

      final Map<String, CourseProgressData> courses = {};
      for (var item in enrolledCourses) {
        courses[item.code] = CourseProgressData(
          code: item.code,
          name: item.courseName,
          section: item.section,
        );
      }

      if (mounted) {
        setState(() {
          _coursesMap = courses;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Init error: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        children: [
          const EWUmateAppBar(title: "Academic Progress", showMenu: true),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => LoadingShimmer.card(),
            ),
          ),
        ],
      );
    }

    if (_semesterCode.isEmpty) {
      return const Center(
        child: Text(
          "Unable to determine semester",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return StreamBuilder<List<CourseMarks>>(
      stream: _progressRepo.getSemesterProgressStream(_semesterCode),
      builder: (context, snapshot) {
          if (snapshot.hasError) {
             debugPrint("ProgressStream Error: ${snapshot.error}");
          }

          final marksList = snapshot.data ?? [];

          // Merge stream data with course info
          // We display all enrolled courses. If marks entry exists in stream, use it.
          // If not, use empty CourseMarks.
          final displayList = _coursesMap.values.map((courseInfo) {
            final existingMarks = marksList.cast<CourseMarks?>().where(
                  (m) => m?.courseCode == courseInfo.code,
                ).firstOrNull;

            return existingMarks ??
                CourseMarks(
                  courseCode: courseInfo.code,
                  courseName: courseInfo.name,
                  distribution: MarkDistribution(),
                  obtained: ObtainedMarks(),
                );
          }).toList();

          return Column(
            children: [
              EWUmateAppBar(
              title: "Academic Progress",
              showMenu: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      _semesterCode,
                      style: TextStyle(
                        color: Colors.cyanAccent.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (displayList.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            "No courses enrolled",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.7,
                          ),
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final marks = displayList[index];
                            return FadeInSlide(
                              delay: Duration(milliseconds: index * 50),
                              child: _buildCourseCard(marks),
                            );
                          }, childCount: displayList.length),
                        ),
                      ),
                    ],
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
              ),
            ],
          );
        },
      );
  }

  Widget _buildCourseCard(CourseMarks marks) {
    final hasDistribution = marks.totalPossible > 0;
    final totalObtained = marks.totalObtained;
    final progress =
        hasDistribution ? (totalObtained / 100).clamp(0.0, 1.0) : 0.0;
    final predictedGrade = hasDistribution ? marks.predictedGrade : '--';

    Color gradeColor;
    if (!hasDistribution) {
      gradeColor = Colors.grey;
    } else if (totalObtained >= 80) {
      gradeColor = Colors.greenAccent;
    } else if (totalObtained >= 60) {
      gradeColor = Colors.cyanAccent;
    } else if (totalObtained >= 40) {
      gradeColor = Colors.orangeAccent;
    } else {
      gradeColor = Colors.redAccent;
    }

    return GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseMarksScreen(
                semesterCode: _semesterCode,
                courseCode: marks.courseCode,
                courseName: marks.courseName,
              ),
            ),
          );
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marks.courseCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      if (marks.courseName.isNotEmpty)
                        Text(
                          marks.courseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasDistribution) ...[
                      Text(
                        "${totalObtained.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: gradeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          predictedGrade,
                          style: TextStyle(
                            color: gradeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ] else
                      const Text(
                        "Setup",
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (hasDistribution) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.black26,
                  valueColor: AlwaysStoppedAnimation(gradeColor),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${marks.totalPossible.toStringAsFixed(0)} Max",
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    if (marks.obtained.mid != null)
                      _buildMarkRow("Mid Term", marks.obtained.mid, marks.distribution.mid),
                    if (marks.obtained.assignment != null)
                      _buildMarkRow("Assignment", marks.obtained.assignment, marks.distribution.assignment),
                    ...marks.obtained.quizzes.asMap().entries.map((e) => 
                      _buildMarkRow("Quiz ${e.key + 1}", e.value, null)),
                    ...marks.obtained.shortQuizzes.asMap().entries.map((e) => 
                      _buildMarkRow("S. Quiz ${e.key + 1}", e.value, null)),
                    if (marks.obtained.presentation != null)
                      _buildMarkRow("Presentation", marks.obtained.presentation, marks.distribution.presentation),
                    if (marks.obtained.viva != null)
                      _buildMarkRow("Viva", marks.obtained.viva, marks.distribution.viva),
                    if (marks.obtained.lab != null)
                      _buildMarkRow("Lab", marks.obtained.lab, marks.distribution.lab),
                    if (marks.obtained.attendance != null)
                      _buildMarkRow("Attendance", marks.obtained.attendance, marks.distribution.attendance),
                  ],
                ),
              ),
            ],
          ],
        ),
    );
  }

  Widget _buildMarkRow(String label, double? value, double? max) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          Text(
            max != null 
              ? "${value.toStringAsFixed(1)}/${max.toStringAsFixed(0)}"
              : value.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
