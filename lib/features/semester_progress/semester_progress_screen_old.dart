import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/semester_progress_models.dart';
import '../calendar/academic_repository.dart';
import 'semester_progress_repository.dart';
import '../../core/widgets/glass_kit.dart';
import 'course_marks_screen.dart';

/// Semester Progress Screen - Shows enrolled courses with marks and progress
/// Rebuilt with direct Firestore access, no caching
/// Validation: obtained marks ≤ distribution marks; hide progress if no distribution
class SemesterProgressScreen extends StatefulWidget {
  const SemesterProgressScreen({super.key});

  @override
  State<SemesterProgressScreen> createState() => _SemesterProgressScreenState();
}

class _SemesterProgressScreenState extends State<SemesterProgressScreen> {
  final SemesterProgressRepository _progressRepo = SemesterProgressRepository();
  final AcademicRepository _academicRepo = AcademicRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String _error = '';
  String _semesterCode = '';
  List<CourseProgressData> _courses = [];
  List<CourseMarks> _progressData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Simple, direct data loading from Firestore
  Future<void> _loadData() async {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _loading = false;
        _error = 'Please log in to view semester progress';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // 1. Get semester code
      _semesterCode = await _academicRepo.getCurrentSemesterCode();
      final safeSem = _semesterCode.replaceAll(' ', '');
      debugPrint('[SemesterProgress] Semester: $safeSem');

      // 2. Get user's enrolled sections
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists) {
        setState(() {
          _loading = false;
          _courses = [];
        });
        return;
      }

      final enrolledIds = List<String>.from(
        userDoc.data()?['enrolledSections'] ?? [],
      );
      debugPrint('[SemesterProgress] Enrolled sections: ${enrolledIds.length}');

      // 3. Fetch course details from courses collection
      _courses = [];
      final coursesCollection = _firestore.collection('courses_$safeSem');
      for (final sectionId in enrolledIds) {
        try {
          final courseDoc = await coursesCollection.doc(sectionId).get();
          if (courseDoc.exists) {
            final data = courseDoc.data()!;
            _courses.add(
              CourseProgressData(
                code: data['code']?.toString() ?? sectionId,
                name: data['courseName']?.toString() ?? '',
                section: data['section']?.toString() ?? '',
              ),
            );
          }
        } catch (e) {
          debugPrint('[SemesterProgress] Error fetching course $sectionId: $e');
        }
      }

      // 4. Fetch marks data
      _progressData = await _progressRepo.fetchSemesterProgress(_semesterCode);
      debugPrint(
        '[SemesterProgress] Loaded ${_progressData.length} marks entries',
      );

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e, stack) {
      debugPrint('[SemesterProgress] Error: $e\n$stack');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load semester progress';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.cyanAccent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: Text(
                "Semester Progress ($_semesterCode)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.transparent,
              floating: true,
            ),
            if (_courses.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    "No enrolled courses found",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final course = _courses[index];
                  final marks = _progressData.firstWhere(
                    (m) => m.courseCode == course.code,
                    orElse: () => CourseMarks(
                      courseCode: course.code,
                      courseName: course.name,
                      distribution: MarkDistribution(),
                      obtained: ObtainedMarks(),
                    ),
                  );
                  return _buildCourseCard(course, marks);
                }, childCount: _courses.length),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseProgressData course, CourseMarks marks) {
    // Check if distribution data is available
    final hasDistribution = marks.totalPossible > 0;

    // Calculate progress only if distribution exists
    final percentage = hasDistribution ? marks.totalObtained : 0.0;
    final progress = hasDistribution ? (percentage / 100).clamp(0.0, 1.0) : 0.0;
    final predictedGrade = hasDistribution ? marks.predictedGrade : '--';

    // Color based on grade or gray if no distribution
    Color gradeColor;
    if (!hasDistribution) {
      gradeColor = Colors.grey;
    } else if (percentage >= 80) {
      gradeColor = Colors.greenAccent;
    } else if (percentage >= 60) {
      gradeColor = Colors.cyanAccent;
    } else if (percentage >= 40) {
      gradeColor = Colors.orangeAccent;
    } else {
      gradeColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseMarksScreen(
                courseCode: course.code,
                courseName: course.name,
                semesterCode: _semesterCode,
              ),
            ),
          );
        },
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        course.name,
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
                        "${percentage.toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: gradeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        predictedGrade,
                        style: TextStyle(color: gradeColor, fontSize: 12),
                      ),
                    ] else ...[
                      const Text(
                        "No marks",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const Text(
                        "Set distribution",
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // Only show progress bar if distribution is available
            if (hasDistribution) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple model for course progress display
class CourseProgressData {
  final String code;
  final String name;
  final String section;

  CourseProgressData({
    required this.code,
    required this.name,
    this.section = '',
  });
}
