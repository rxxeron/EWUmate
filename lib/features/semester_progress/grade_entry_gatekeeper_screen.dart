import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'semester_repository.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import '../advising/advising_repository.dart';
import '../../core/models/course_model.dart';
import '../../core/utils/course_utils.dart';
import '../../core/widgets/ewumate_app_bar.dart';

class GradeEntryGatekeeperScreen extends StatefulWidget {
  final VoidCallback onTransitionComplete;

  const GradeEntryGatekeeperScreen({
    super.key, 
    required this.onTransitionComplete,
  });

  @override
  State<GradeEntryGatekeeperScreen> createState() => _GradeEntryGatekeeperScreenState();
}

class _GradeEntryGatekeeperScreenState extends State<GradeEntryGatekeeperScreen> {
  final _supabase = Supabase.instance.client;
  final Map<String, String> _grades = {};
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<CourseSummary> _courses = [];
  String _semesterCode = "";
  String _nextSemCode = "";
  bool _isForced = true;
  final _repo = SemesterRepository();
  final _courseRepo = CourseRepository();
  // final _academicRepo = AcademicRepository(); // Removed unused
  final _advisingRepo = AdvisingRepository();

  // Step 0: Enrollment for next semester
  bool _needsEnrollment = false; // true if enrolled_sections_next is empty
  int _currentStep = 1; // 0: Enrollment, 1: Grades
  List<Course> _enrollmentDraft = [];
  Map<String, List<Course>> _availableCourses = {};
  List<String> _filteredCodes = [];
  List<Map<String, dynamic>> _savedSchedules = [];
  final TextEditingController _enrollSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _enrollSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final academicRepo = AcademicRepository();
      final config = await academicRepo.getActiveSemesterConfig().timeout(const Duration(seconds: 4));
      _semesterCode = config['current_semester_code'] ?? 'Spring2026';
      _nextSemCode = config['next_semester_code'] ?? 'Summer2026';

      _courses = await _repo.fetchSemesterSummary(_semesterCode).timeout(const Duration(seconds: 4));
      
      for (var c in _courses) {
        _grades[c.code] = "A"; // Default
      }

      final profile = await _supabase.from('profiles')
          .select('force_grade_entry, enrolled_sections_next, favorite_schedules')
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 4));
          
      _isForced = profile['force_grade_entry'] ?? false;

      // Check if enrollment for next semester is needed
      final nextEnrollment = List<String>.from(profile['enrolled_sections_next'] ?? []);
      if (nextEnrollment.isEmpty) {
        _needsEnrollment = true;
        _currentStep = 0;

        // Load available courses for the next semester
        try {
          final raw = await _courseRepo.fetchCourses(_nextSemCode).timeout(const Duration(seconds: 6));
          _availableCourses = {};
          raw.forEach((code, sections) {
            final available = sections.where((s) => CourseUtils.isAvailable(s.capacity)).toList();
            if (available.isNotEmpty) {
              _availableCourses[code] = available;
            }
          });
          _filteredCodes = _availableCourses.keys.toList()..sort();
        } catch (e) {
          debugPrint('Error loading next sem courses: $e');
        }

        // Load saved favorites
        final allFavs = List<dynamic>.from(profile['favorite_schedules'] ?? []);
        _savedSchedules = allFavs
            .where((f) => f['semester'] == _nextSemCode)
            .map((f) => Map<String, dynamic>.from(f))
            .toList();
      } else {
        _currentStep = 1;
      }

    } catch (e) {
      debugPrint('Error loading gatekeeper data: $e');
      // If forced, we MUST try to show something, otherwise navigate back or to dashboard
      if (!_isForced && mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipSemester() async {
    setState(() => _isSubmitting = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Mark as dropped
      await _supabase.from('profiles').update({
        'enrolled_sections_next': ['DROPPED'],
      }).eq('id', user.id);

      setState(() {
        _needsEnrollment = false;
        _currentStep = 1;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _finalizeGatekeeperEnrollment() async {
    if (_enrollmentDraft.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final ids = _enrollmentDraft.map((c) => c.id).toList();
      await _supabase.from('profiles').update({
        'enrolled_sections_next': ids,
      }).eq('id', user.id);

      setState(() {
        _needsEnrollment = false;
        _currentStep = 1;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    
    final success = await _repo.submitFinalGradesAndTransition(
      _semesterCode, 
      _grades
    );

    if (success) {
      widget.onTransitionComplete();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to transition. Please try again.')),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: EWUmateAppBar(
        title: _currentStep == 0 ? "Next Semester Setup" : "Semester Completed!",
        showBack: !_isForced,
        onBack: _isForced ? null : () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.purple.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _currentStep == 0
                ? _buildEnrollmentStep()
                : _buildGradeStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          "Before entering grades, set up your enrollment for $_nextSemCode — or skip if you're not enrolling.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 20),

        // Import from Favorites
        if (_savedSchedules.isNotEmpty && _enrollmentDraft.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Import from Saved Schedules",
                    style: GoogleFonts.outfit(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 8),
                ..._savedSchedules.map((fav) {
                  final ids = List<String>.from(fav['sectionIds'] ?? []);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.bookmark, color: Colors.orangeAccent, size: 20),
                    title: Text("${ids.length} courses",
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                    trailing: TextButton(
                      onPressed: () async {
                        final courses = await _advisingRepo.validateSchedule(_nextSemCode, ids);
                        if (courses.isNotEmpty && mounted) {
                          setState(() => _enrollmentDraft = courses);
                        }
                      },
                      child: const Text("Import"),
                    ),
                  );
                }),
              ],
            ),
          ),

        // Search and add
        TextField(
          controller: _enrollSearchController,
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (q) {
            setState(() {
              _filteredCodes = _availableCourses.keys
                  .where((k) => k.toLowerCase().contains(q.toLowerCase()))
                  .toList()..sort();
            });
          },
        ),
        const SizedBox(height: 8),

        // Draft display
        if (_enrollmentDraft.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _enrollmentDraft.map((c) => Chip(
                label: Text(c.code, style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onDeleted: () => setState(() => _enrollmentDraft.removeWhere((x) => x.id == c.id)),
              )).toList(),
            ),
          ),

        // Course list
        Expanded(
          child: _enrollSearchController.text.isNotEmpty
            ? ListView.builder(
                itemCount: _filteredCodes.length,
                itemBuilder: (context, idx) {
                  final code = _filteredCodes[idx];
                  final sections = _availableCourses[code]!;
                  return ExpansionTile(
                    title: Text(code,
                        style: GoogleFonts.outfit(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    children: sections.map((s) => ListTile(
                      dense: true,
                      title: Text("Sec ${s.section} • ${s.faculty}",
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                      trailing: TextButton(
                        onPressed: () {
                          if (_enrollmentDraft.any((c) => c.code == s.code)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Course already added!")));
                            return;
                          }
                          setState(() {
                            _enrollmentDraft.add(s);
                            _enrollSearchController.clear();
                          });
                        },
                        child: const Text("Add"),
                      ),
                    )).toList(),
                  );
                },
              )
            : const Center(
                child: Text("Search to add courses, or import from saved schedules above.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38)),
              ),
        ),

        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _skipSemester,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orangeAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent)
                    : Text("Skip Semester",
                        style: GoogleFonts.outfit(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        )),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _enrollmentDraft.isEmpty || _isSubmitting
                      ? null
                      : _finalizeGatekeeperEnrollment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text("Confirm & Continue",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          "To unlock your next semester and schedule, please enter your final grades for $_semesterCode.",
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.builder(
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              final course = _courses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.code,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            course.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      dropdownColor: Colors.grey[900],
                      value: _grades[course.code],
                      underline: const SizedBox(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blueAccent,
                      ),
                      items: _repo.availableGrades.map((g) => 
                        DropdownMenuItem(value: g, child: Text(g))
                      ).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _grades[course.code] = val);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  "Submit & Start Next Semester",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
