import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/semester_progress_models.dart';
import '../calendar/academic_repository.dart';
import 'semester_progress_repository.dart';
import '../../core/widgets/glass_kit.dart';
import 'course_marks_screen.dart';

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
  String _semesterCode = '';
  // Map of CourseCode -> CourseProgressData (basic info)
  Map<String, CourseProgressData> _coursesMap = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // 1. Get Semester
      _semesterCode = await _academicRepo.getCurrentSemesterCode();
      final safeSem = _semesterCode.replaceAll(' ', '');

      // 2. Get User Enrolled
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final enrolledIds = List<String>.from(
        userDoc.data()?['enrolledSections'] ?? [],
      );

      // 3. Fetch Course Info
      final Map<String, CourseProgressData> courses = {};
      final coursesCollection = _firestore.collection('courses_$safeSem');

      for (final sectionId in enrolledIds) {
        try {
          final doc = await coursesCollection.doc(sectionId).get();
          if (doc.exists) {
            final data = doc.data()!;
            final code = data['code']?.toString() ?? sectionId;
            courses[code] = CourseProgressData(
              code: code,
              name: data['courseName']?.toString() ?? '',
              section: data['section']?.toString() ?? '',
            );
          }
        } catch (e) {
          debugPrint("Error loading course info $sectionId: $e");
        }
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
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

    return FullGradientScaffold(
      body: StreamBuilder<List<CourseMarks>>(
        stream: _progressRepo.getSemesterProgressStream(_semesterCode),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final marksList = snapshot.data ?? [];

          // Merge stream data with course info
          // We display all enrolled courses. If marks entry exists in stream, use it.
          // If not, use empty CourseMarks.
          final displayList = _coursesMap.values.map((courseInfo) {
            final existingMarks = marksList.cast<CourseMarks?>().firstWhere(
                  (m) => m?.courseCode == courseInfo.code,
                  orElse: () => null,
                );

            return existingMarks ??
                CourseMarks(
                  courseCode: courseInfo.code,
                  courseName: courseInfo.name,
                  distribution: MarkDistribution(),
                  obtained: ObtainedMarks(),
                );
          }).toList();

          if (displayList.isEmpty) {
            return const Center(
              child: Text(
                "No courses enrolled",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text(
                  "Academic Progress",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: false,
                backgroundColor: Colors.transparent,
                floating: true,
                pinned: true,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Text(
                    _semesterCode,
                    style: TextStyle(
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final marks = displayList[index];
                  return _buildCourseCard(marks);
                }, childCount: displayList.length),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
            ],
          );
        },
      ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(20),
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
            ],
          ],
        ),
      ),
    );
  }
}
