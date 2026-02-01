import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_kit.dart';

import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import '../advising/advising_repository.dart';
import '../../core/models/course_model.dart';

class NextSemesterScreen extends StatefulWidget {
  const NextSemesterScreen({super.key});

  @override
  State<NextSemesterScreen> createState() => _NextSemesterScreenState();
}

class _NextSemesterScreenState extends State<NextSemesterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AcademicRepository _academicRepo = AcademicRepository();
  final CourseRepository _courseRepo = CourseRepository();
  final AdvisingRepository _advisingRepo = AdvisingRepository();

  bool _loading = true;
  String _currentSemCode = '';
  DateTime? _gradeSubmissionDate;
  bool _isLockedByDate = false;

  // Step 1 Data (Grades)
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

  // Step 2 Data (Enrollment)
  int _currentStep = 1; // 1: Grades, 2: Enrollment
  List<Course> _plannedCourses = [];
  Map<String, List<Course>> _availableCourses = {}; // For manual search
  List<String> _filteredAvailableCodes = [];
  String _nextSemCode = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      _currentSemCode = await _academicRepo.getCurrentSemesterCode();
      if (_currentSemCode.isEmpty) _currentSemCode = "Spring2026";

      _gradeSubmissionDate =
          await _academicRepo.getFinalGradeSubmissionDate(_currentSemCode);
      if (_gradeSubmissionDate != null) {
        if (DateTime.now().isBefore(_gradeSubmissionDate!)) {
          _isLockedByDate = true;
        }
      }

      final scheduleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(_currentSemCode.replaceAll(' ', ''))
          .get();

      if (scheduleDoc.exists) {
        final data = scheduleDoc.data()!;
        final enrolled = List<String>.from(data['enrolledSections'] ?? []);
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

  String _calculateNextSemester(String current) {
    final match = RegExp(r'([a-zA-Z]+)(\d{4})').firstMatch(current);
    if (match != null) {
      final season = match.group(1)!;
      final year = int.parse(match.group(2)!);
      if (season.contains('Spring')) return 'Summer$year';
      if (season.contains('Summer')) return 'Fall$year';
      if (season.contains('Fall')) return 'Spring${year + 1}';
    }
    return current;
  }

  Future<void> _submitGrades() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      // FETCH V2: Get history from academic_data/profile
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('academic_data')
          .doc('profile')
          .get();
      
      final data = profileDoc.data() ?? {};

      // Update courseHistory (Map)
      final existingHistory =
          Map<String, dynamic>.from(data['courseHistory'] ?? {});
      final newTermResults = <String, String>{};
      final newCompleted = List<String>.from(data['completedCourses'] ?? []);

      for (var c in _currentCourses) {
        final code = c['code'].toString();
        final grade = c['grade'].toString();
        newTermResults[code] = grade;

        if (grade != 'W' && grade != 'I' && grade != 'F') {
          if (!newCompleted.contains(code)) {
            newCompleted.add(code);
          }
        }
      }

      existingHistory[_currentSemCode] = newTermResults;

      // UPDATE V2: Save to academic_data/profile subcollection
      final profileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('academic_data')
          .doc('profile');

      await profileRef.set({
        'courseHistory': existingHistory,
        'completedCourses': newCompleted,
      }, SetOptions(merge: true));

      // Clear Root Enrollment (to signal semester end)
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'enrolledSections': [], 
      });

      _nextSemCode = _calculateNextSemester(_currentSemCode);
      final planIds = await _advisingRepo.getManualPlanIds(_nextSemCode);

      if (planIds.isNotEmpty) {
        _plannedCourses =
            await _advisingRepo.validateSchedule(_nextSemCode, planIds);
      }

      // Pre-load available courses for manual search in Step 2
      final rawCourses = await _courseRepo.fetchCourses(_nextSemCode);
      _availableCourses = {};
      rawCourses.forEach((code, sections) {
        final available = sections.where((s) {
          final cap = s.capacity ?? "0/0";
          try {
            final parts = cap.split('/');
            if (parts.length == 2) {
              final enr = int.parse(parts[0]);
              final tot = int.parse(parts[1]);
              return tot > 0 && enr < tot;
            }
          } catch (_) {}
          return false;
        }).toList();
        if (available.isNotEmpty) _availableCourses[code] = available;
      });
      _filteredAvailableCodes = _availableCourses.keys.toList()..sort();

      setState(() {
        _currentStep = 2;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error saving grades: $e");
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _finalizeEnrollment() async {
    setState(() => _loading = true);
    try {
      await _advisingRepo.finalizeEnrollment(_nextSemCode);
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Enrollment Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
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
          : (_currentStep == 1
              ? _buildStep1FinalizeGrades()
              : _buildStep2Enrollment()),
    );
  }

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
                    "Opens on: ${DateFormat('dd/MM/yyyy').format(_gradeSubmissionDate!)}",
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
          const Text("Finalize Results",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text("Enter your final grades for $_currentSemCode to proceed.",
              style: const TextStyle(color: Colors.white70)),
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_currentCourses.isEmpty || _canSubmitGrades())
                  ? _submitGrades
                  : null,
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

  Widget _buildStep2Enrollment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Finalize Enrollment",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text("Review your planned courses for $_nextSemCode.",
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          _buildSearchAndAdd(),
          const SizedBox(height: 20),
          if (_plannedCourses.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("No planned courses found for this semester.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/advising'),
                    child: const Text("Go to Advising Planner"),
                  )
                ],
              ),
            )
          else ...[
            ..._plannedCourses.map((c) => _buildPlannedCourseCard(c)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _finalizeEnrollment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Finalize My Enrollment",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlannedCourseCard(Course course) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(course.code,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      fontSize: 18)),
              Text("Sec: ${course.section}",
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 4),
          Text(course.courseName,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Divider(color: Colors.white12),
          ...course.sessions.map((s) => Text(
                "${s.type}: ${s.day} ${s.startTime} - ${s.endTime}",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              )),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _plannedCourses.removeWhere((c) => c.id == course.id);
                });
                _syncPlanner();
              },
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 18),
              label: const Text("Remove",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchAndAdd() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search more courses...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: _filterSearch,
        ),
        if (_searchController.text.isNotEmpty)
          Container(
            height: 200,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: _filteredAvailableCodes.length,
              itemBuilder: (context, idx) {
                final code = _filteredAvailableCodes[idx];
                final sections = _availableCourses[code]!;
                return ExpansionTile(
                  title: Text(code,
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold)),
                  children: sections
                      .map((s) => ListTile(
                            title: Text("Section ${s.section} - ${s.faculty}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            trailing: TextButton(
                              child: const Text("Add"),
                              onPressed: () => _addPlannedSection(s),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ),
      ],
    );
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredAvailableCodes = _availableCourses.keys
          .where((k) => k.toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort();
    });
  }

  void _addPlannedSection(Course s) {
    // Overlap Check (Simplified)
    for (var existing in _plannedCourses) {
      if (existing.code == s.code) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Course already added!")));
        return;
      }
      // Conflict Check
      for (var s1 in s.sessions) {
        for (var s2 in existing.sessions) {
          if (s1.day == s2.day &&
              _timesOverlap(
                  s1.startTime, s1.endTime, s2.startTime, s2.endTime)) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Conflict with ${existing.code}!")));
            return;
          }
        }
      }
    }
    setState(() {
      _plannedCourses.add(s);
      _searchController.clear();
      _filteredAvailableCodes = _availableCourses.keys.toList()..sort();
    });
    _syncPlanner();
  }

  void _syncPlanner() async {
    final ids = _plannedCourses.map((c) => c.id).toList();
    await _advisingRepo.saveManualPlan(_nextSemCode, ids);
  }

  bool _timesOverlap(String s1, String e1, String s2, String e2) {
    try {
      final format = DateFormat("hh:mm a");
      final start1 = format.parse(s1).millisecondsSinceEpoch;
      final end1 = format.parse(e1).millisecondsSinceEpoch;
      final start2 = format.parse(s2).millisecondsSinceEpoch;
      final end2 = format.parse(e2).millisecondsSinceEpoch;
      return start1 < end2 && start2 < end1;
    } catch (_) {
      return false;
    }
  }
}
