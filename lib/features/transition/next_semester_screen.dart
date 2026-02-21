import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Added for haptics
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/animations/fade_in_slide.dart';
import '../../core/widgets/animations/loading_shimmer.dart';

import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import '../advising/advising_repository.dart';
import '../results/results_repository.dart';
import '../../core/models/course_model.dart';

class NextSemesterScreen extends StatefulWidget {
  const NextSemesterScreen({super.key});

  @override
  State<NextSemesterScreen> createState() => _NextSemesterScreenState();
}

class _NextSemesterScreenState extends State<NextSemesterScreen> {
  final _supabase = Supabase.instance.client;
  final AcademicRepository _academicRepo = AcademicRepository();
  final CourseRepository _courseRepo = CourseRepository();
  final AdvisingRepository _advisingRepo = AdvisingRepository();
  final ResultsRepository _resultsRepo = ResultsRepository();

  bool _loading = true;
  String _currentSemCode = '';
  DateTime? _gradeSubmissionDate;
  bool _isLockedByDate = false;
  bool _debugBypass = false;
  String _nextSemCode = '';

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

  // Steps: 1: Enrollment, 2: Grades
  int _currentStep = 1; 
  List<Course> _plannedCourses = [];
  Map<String, List<Course>> _availableCourses = {}; // For manual search
  List<String> _filteredAvailableCodes = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _savedSchedules = []; // From advising favorites
  bool _enrollmentLocked = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final config = await _academicRepo.getActiveSemesterConfig();
      _currentSemCode = config['current_semester_code'] ?? 'Spring2026';
      _nextSemCode = config['next_semester_code'] ?? 'Summer2026';

      // Load universal grade scale and metadata
      await _resultsRepo.fetchAcademicProfile(); // Trigger metadata load
  
      final window = await _academicRepo.getGradeSubmissionWindow();
      _gradeSubmissionDate = window['start'];
      
      if (_gradeSubmissionDate != null) {
        if (DateTime.now().isBefore(_gradeSubmissionDate!)) {
          _isLockedByDate = true;
        }
      } else {
        // Fallback to calendar parsing if active_semester has no start date
        _gradeSubmissionDate = await _academicRepo.getFinalGradeSubmissionDate(_currentSemCode);
        if (_gradeSubmissionDate != null && DateTime.now().isBefore(_gradeSubmissionDate!)) {
          _isLockedByDate = true;
        }
      }
 
      // Fetch enrolled sections from profile
      final profileData = await _supabase
          .from('profiles')
          .select('enrolled_sections, enrolled_sections_next, favorite_schedules')
          .eq('id', user.id)
          .single();
 
      final enrolled =
          List<String>.from(profileData['enrolled_sections'] ?? []);

      // Check if next semester enrollment is already finalized
      final nextEnrollment =
          List<String>.from(profileData['enrolled_sections_next'] ?? []);
      if (nextEnrollment.isNotEmpty && nextEnrollment.first != 'DROPPED') {
        _enrollmentLocked = true;
        _plannedCourses = await _advisingRepo.validateSchedule(_nextSemCode, nextEnrollment);
      }

      // Use favorite schedules from the single profile fetch
      final allFavs = List<dynamic>.from(profileData['favorite_schedules'] ?? []);
      _savedSchedules = allFavs
          .where((f) => f['semester'] == _nextSemCode)
          .map((f) => Map<String, dynamic>.from(f))
          .toList();

      // Pre-load available courses for Step 1 (Enrollment)
      await _loadAvailableCourses();

      if (_enrollmentLocked) {
        _currentStep = 2;
      }

      if (enrolled.isNotEmpty) {
        final courses =
            await _courseRepo.fetchCourses(_currentSemCode); // Use fetchCourses for list
        final list = await _courseRepo.fetchCoursesByIds(_currentSemCode, enrolled);
        _currentCourses = list
            .map((c) => {
                  'code': c.code,
                  'name': c.courseName,
                  'credits': c.credits,
                  'grade': 'A', // Default
                })
            .toList();
      }
 
      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint("[NextSemester] Error init: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAvailableCourses() async {
    try {
      debugPrint("[NextSemester] Loading courses for $_nextSemCode");
      final rawCourses = await _courseRepo.fetchCourses(_nextSemCode, allowMetadataFallback: false);
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
      debugPrint("[NextSemester] Loaded ${_availableCourses.length} available courses");
    } catch (e) {
      debugPrint("[NextSemester] Error loading courses: $e");
    }
  }


  Future<void> _submitGrades() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final academicData = await _supabase
          .from('academic_data')
          .select('semesters, completed_courses')
          .eq('user_id', user.id)
          .maybeSingle();

      // Update academic history
      final rawSemesters = academicData?['semesters'];
      List<dynamic> semestersList = [];

      if (rawSemesters is List) {
        semestersList = List<dynamic>.from(rawSemesters);
      } else if (rawSemesters is Map) {
        // Convert Map format used by onboarding to List expected by app
        rawSemesters.forEach((key, value) {
          semestersList.add({
            'semesterName': key,
            'courses': (value as Map).entries.map((e) => {
              'code': e.key,
              'grade': e.value,
            }).toList(),
          });
        });
      }

      final newTermResults = <String, dynamic>{
        'semesterName': _currentSemCode,
        'courses': _currentCourses.map((c) {
          final grade = c['grade'].toString();
          return {
            'code': c['code'],
            'title': c['name'],
            'credits': c['credits'],
            'grade': grade,
            'point': ResultsRepository.getGradePoint(grade),
          };
        }).toList(),
      };

      final newCompleted =
          List<String>.from(academicData?['completed_courses'] ?? []);

      for (var c in _currentCourses) {
        final code = c['code'].toString();
        final grade = c['grade'].toString();

        if (grade != 'W' && grade != 'I' && grade != 'F') {
          if (!newCompleted.contains(code)) {
            newCompleted.add(code);
          }
        }
      }

      // Check if semester already exists, replace if so, else append
      final existingIdx = semestersList.indexWhere((s) => s['semesterName'] == _currentSemCode);
      if (existingIdx != -1) {
        semestersList[existingIdx] = newTermResults;
      } else {
        semestersList.add(newTermResults);
      }

      // Update Academic Data
      await _supabase.from('academic_data').upsert({
        'user_id': user.id,
        'semesters': semestersList,
        'completed_courses': newCompleted,
        'last_updated': DateTime.now().toIso8601String(),
      });

      // Update Profile (Clear current enrollment)
      await _supabase.from('profiles').update({
        'enrolled_sections': [],
      }).eq('id', user.id);

      final planIds = await _advisingRepo.getManualPlanIds(_nextSemCode);

      if (planIds.isNotEmpty) {
        _plannedCourses =
            await _advisingRepo.validateSchedule(_nextSemCode, planIds);
      }

      if (mounted) {
        context.go('/dashboard');
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

  Future<void> _finalizeEnrollment() async {
    HapticFeedback.mediumImpact(); // Added haptics
    setState(() => _loading = true);
    try {
      // Save to enrolled_sections_next for the upcoming semester
      final ids = _plannedCourses.map((c) => c.id).toList();
      await _supabase.from('profiles').update({
        'enrolled_sections_next': ids,
      }).eq('id', _supabase.auth.currentUser!.id);

      await _advisingRepo.finalizeEnrollment(_nextSemCode);
      
      // Instead of going to dashboard, move to Step 2 (Grades)
      setState(() {
        _currentStep = 2;
        _loading = false;
      });
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
    return Column(
      children: [
        const EWUmateAppBar(
          title: "Next Semester Setup",
          showBack: true,
        ),
        _loading
            ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
            : Expanded(
                child: Column(
                  children: [
                    _buildStepIndicator(),
                    Expanded(
                      child: FadeInSlide(
                        key: ValueKey(_currentStep),
                        child: _currentStep == 1
                            ? _buildStep2Enrollment()
                            : (_isLockedByDate && !_debugBypass
                                ? _buildLockedByDate()
                                : _buildStep1FinalizeGrades()),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
 
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
      child: Row(
        children: [
          _stepDot(1, "Enrollment", _currentStep >= 1),
          Expanded(child: Container(height: 2, color: _currentStep >= 2 ? Colors.cyanAccent : Colors.white12)),
          _stepDot(2, "Grades", _currentStep >= 2),
        ],
      ),
    );
  }
 
  Widget _stepDot(int step, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? Colors.cyanAccent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: active ? Colors.cyanAccent : Colors.white24, width: 2),
          ),
          alignment: Alignment.center,
          child: Text("$step", style: TextStyle(color: active ? Colors.black : Colors.white38, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 10)),
      ],
    );
  }
 
  Widget _buildLockedByDate() {
    return Center(
      child: GlassContainer(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onLongPress: () {
                setState(() => _debugBypass = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Developer Bypass Activated")),
                );
              },
              child: const Icon(Icons.lock_clock,
                  size: 64, color: Colors.orangeAccent),
            ),
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
 
  Widget _buildStep1FinalizeGrades() {
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
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.black26, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
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
                  HapticFeedback.lightImpact();
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
    if (_enrollmentLocked) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enrollment Finalized ✅",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent)),
            const SizedBox(height: 8),
            Text("Your enrollment for $_nextSemCode is locked.",
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ..._plannedCourses.map((c) => _buildPlannedCourseCard(c)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _currentStep = 2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Continue to Finalize Results",
                    style: TextStyle(color: Colors.cyanAccent)),
              ),
            ),
          ],
        ),
      );
    }

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

          // Import from Favorites
          if (_savedSchedules.isNotEmpty && _plannedCourses.isEmpty)
            GlassContainer(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              borderColor: Colors.orangeAccent.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Import from Saved Schedules",
                      style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  ..._savedSchedules.map((fav) {
                    final ids = List<String>.from(fav['sectionIds'] ?? []);
                    final createdAt = fav['createdAt'] ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bookmark, color: Colors.orangeAccent),
                      title: Text("${ids.length} courses",
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text(createdAt.substring(0, 10),
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: TextButton(
                        onPressed: () async {
                          final courses = await _advisingRepo.validateSchedule(_nextSemCode, ids);
                          if (courses.isNotEmpty && mounted) {
                            setState(() => _plannedCourses = courses);
                            _syncPlanner();
                          }
                        },
                        child: const Text("Import"),
                      ),
                    );
                  }),
                ],
              ),
            ),

          _buildSearchAndAdd(),
          const SizedBox(height: 20),
          if (_plannedCourses.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("No planned courses found for this semester.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.go('/advising'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text("Go to Advising Planner", style: TextStyle(fontSize: 13)),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      fontSize: 16)),
              Text("Sec: ${course.section}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(course.courseName,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Divider(color: Colors.white12, height: 16),
          ...course.sessions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  "${s.type}: ${s.day} ${s.startTime} - ${s.endTime}",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              )),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _plannedCourses.removeWhere((c) => c.id == course.id);
                });
                _syncPlanner();
              },
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 16),
              label: const Text("Remove",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
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
            height: 400,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredAvailableCodes.length,
              itemBuilder: (context, idx) {
                final code = _filteredAvailableCodes[idx];
                final sections = _availableCourses[code]!;
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    visualDensity: VisualDensity.compact,
                    title: Text(code,
                        style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    children: sections
                        .map((s) => ListTile(
                              dense: true,
                              title: Text("Section ${s.section} - ${s.faculty}",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12)),
                              trailing: TextButton(
                                child: const Text("Add", style: TextStyle(fontSize: 12)),
                                onPressed: () => _addPlannedSection(s),
                              ),
                            ))
                        .toList(),
                  ),
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
    HapticFeedback.lightImpact();
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
