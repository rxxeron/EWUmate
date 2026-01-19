import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/glass_kit.dart';

import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';

class NextSemesterScreen extends StatefulWidget {
  const NextSemesterScreen({super.key});

  @override
  State<NextSemesterScreen> createState() => _NextSemesterScreenState();
}

class _NextSemesterScreenState extends State<NextSemesterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AcademicRepository _academicRepo = AcademicRepository();
  final CourseRepository _courseRepo = CourseRepository();

  bool _loading = true;
  String _currentSemCode = '';
  DateTime? _gradeSubmissionDate;
  bool _isLockedByDate = false;

  // Step 1 Data
  List<Map<String, dynamic>> _currentCourses = []; // {code, name, grade}
  final List<String> _gradeOptions = [
    'A+',
    'A',
    'A-',
    'B+',
    'B',
    'B-',
    'C+',
    'C',
    'C-',
    'D+',
    'D',
    'F',
    'W',
    'I'
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Identify Current Semester
      _currentSemCode = await _academicRepo.getCurrentSemesterCode();
      if (_currentSemCode.isEmpty) _currentSemCode = "Spring2026"; // Fallback

      if (_currentSemCode.isEmpty) _currentSemCode = "Spring2026"; // Fallback

      // Check Grade Submission Date
      _gradeSubmissionDate =
          await _academicRepo.getFinalGradeSubmissionDate(_currentSemCode);
      if (_gradeSubmissionDate != null) {
        if (DateTime.now().isBefore(_gradeSubmissionDate!)) {
          _isLockedByDate = true;
        }
      }

      // 3. Fetch Enrolled Courses for Current Sem (for grading)
      // We can fetch from 'schedule' collection
      final scheduleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(_currentSemCode.replaceAll(' ', ''))
          .get();

      if (scheduleDoc.exists) {
        final data = scheduleDoc.data()!;
        final enrolled = List<String>.from(data['enrolledSections'] ?? []);
        // Fetch details for these sections? Or just use what we have?
        // We need course names.
        if (enrolled.isNotEmpty) {
          final courses =
              await _courseRepo.fetchCoursesByIds(_currentSemCode, enrolled);
          _currentCourses = courses
              .map((c) => {
                    'code': c.code,
                    'name': c.courseName,
                    'credits': c.credits,
                    'grade': 'A', // Default
                  })
              .toList();
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error init transition: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _submitGrades() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final historyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('course_history');

      for (var c in _currentCourses) {
        final doc = historyRef.doc(); // New entry
        batch.set(doc, {
          'courseCode': c['code'],
          'courseName': c['name'],
          'grade': c['grade'],
          'semester': _currentSemCode,
          'credits': c['credits'] ?? 3.0,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Grades Submitted!
      // Redirect to Course Browser (which should now unlock)
      if (mounted) {
        context.go('/courses');
      }
    } catch (e) {
      debugPrint("Error saving grades: $e");
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Removed _loadNextSemesterCourses, _searchNextCourses, _finishEnrollment...

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: AppBar(
        title: const Text("Next Semester Setup",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _buildStep1FinalizeGrades(),
    );
  }

  // --- Step 1: Finalize Grades ---

  Widget _buildStep1FinalizeGrades() {
    if (_isLockedByDate) {
      return Center(
        child: GlassContainer(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock,
                  size: 64, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              const Text(
                "Grade Submission Locked",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "You can finalize your results after the final grade submission date.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              if (_gradeSubmissionDate != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    "Opens on: ${_gradeSubmissionDate!.day}/${_gradeSubmissionDate!.month}/${_gradeSubmissionDate!.year}",
                    style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                child: const Text("Return to Dashboard",
                    style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Finalize Results",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your final grades for $_currentSemCode to proceed.",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          if (_currentCourses.isEmpty)
            const GlassContainer(
              padding: EdgeInsets.all(20),
              child: Text("No courses found for this semester.",
                  style: TextStyle(color: Colors.white)),
            )
          else
            ..._currentCourses.map((c) => _buildGradeCard(c)),
          const SizedBox(height: 30),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _currentCourses.isEmpty
                  ? () {
                      // If no courses, just proceed
                      context.go('/courses');
                    }
                  : (_canSubmitGrades() ? _submitGrades : null),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _canSubmitGrades() ? Colors.cyanAccent : Colors.white10,
                foregroundColor:
                    _canSubmitGrades() ? Colors.black : Colors.white38,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Submit & Continue",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  bool _canSubmitGrades() {
    if (_currentCourses.isEmpty) return true;
    return _currentCourses.every((c) => c['grade'] != null);
  }

  Widget _buildGradeCard(Map<String, dynamic> course) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course['code'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16)),
                Text(course['name'],
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.black26, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: course['grade'],
                dropdownColor: const Color(0xFF1A1A2E),
                items: _gradeOptions
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g,
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    course['grade'] = val;
                  });
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
