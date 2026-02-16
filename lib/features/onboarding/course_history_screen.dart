import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'onboarding_repository.dart';
import '../calendar/academic_repository.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/services/azure_functions_service.dart';

class CourseHistoryScreen extends StatefulWidget {
  final bool isEditMode;
  const CourseHistoryScreen({super.key, this.isEditMode = false});

  @override
  State<CourseHistoryScreen> createState() => _CourseHistoryScreenState();
}

class _CourseHistoryScreenState extends State<CourseHistoryScreen> {
  final OnboardingRepository _repo = OnboardingRepository();
  final _supabase = Supabase.instance.client;

  // State
  bool _initializing = false; // Changed from true to avoid flash
  bool _profileLoading = true; // New state to handle initial fetch
  bool _loading = false;
  Timer? _debounce;
  bool _isCurrentSemester = false;

  // Data
  List<Map<String, dynamic>> _catalog = [];
  final Map<String, Map<String, String>> _history = {};
  // New: Store IDs explicitly so we don't lose them when catalog changes
  final Map<String, List<String>> _selectedSectionIds = {};

  final List<String> _allSemesters = [
    "Spring 2023",
    "Summer 2023",
    "Fall 2023",
    "Spring 2024",
    "Summer 2024",
    "Fall 2024",
    "Spring 2025",
    "Summer 2025",
    "Fall 2025",
    "Spring 2026",
    "Summer 2026",
    "Fall 2026"
  ];

  String _runningSemester = "Spring 2026"; // Made non-final, default fallback
  final AcademicRepository _academicRepo = AcademicRepository();

  // Current State
  // String? _admittedSemester;
  String? _currentSemester;
  int _currentIndex = -1;
  String _searchQuery = '';

  // Filter courses based on search query
  // With server-side search, we just show the fetched catalog
  List<Map<String, dynamic>> _getFilteredCourses() {
    return _catalog;
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // 1. Fetch Dynamic Semester Code (e.g. Spring2026)
    final code = await _academicRepo.getCurrentSemesterCode();

    // 2. Format to match UI (Spring 2026)
    String formatted = code;
    if (code.contains("20")) {
      final yearIdx = code.indexOf("20");
      final name = code.substring(0, yearIdx);
      final year = code.substring(yearIdx);
      formatted = "$name $year";
    }

    // 3. Fetch User Profile for Admitted Semester & History
    String? savedSemester;
    Map<String, dynamic>? savedHistory;
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final profileData = await _supabase
          .from('profiles')
          .select('admitted_semester, academic_history')
          .eq('id', user.id)
          .single();

      savedSemester = profileData['admitted_semester']?.toString();
      savedHistory = profileData['academic_history'] as Map<String, dynamic>?;
    }

    if (mounted) {
      setState(() {
        _runningSemester = formatted;
        if (!_allSemesters.contains(_runningSemester)) {
          _allSemesters.add(_runningSemester);
        }

        // Restore History
        if (savedHistory != null) {
          savedHistory.forEach((sem, courses) {
            if (courses is Map) {
              final courseMap = Map<String, String>.from(
                courses.map(
                    (key, value) => MapEntry(key.toString(), value.toString())),
              );
              _history[sem] = courseMap;
            }
          });
        }

        if (savedSemester != null && _allSemesters.contains(savedSemester)) {
          _confirmAdmittedSemester(savedSemester);
          _initializing = false; // Skip prompt
        } else {
          _initializing = true; // Must select
        }
        _profileLoading = false;
      });
      if (_currentSemester != null) _loadCatalog();
    }
  }

  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    final catalog = await _repo.fetchCourseCatalog(
        semester: _currentSemester,
        isCurrent: _isCurrentSemester,
        searchQuery: _searchQuery);
    if (mounted) {
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = val;
      _loadCatalog();
    });
  }

  // --- Logic ---

  void _confirmAdmittedSemester(String semester) {
    setState(() {
      _currentSemester = semester;
      _currentIndex = _allSemesters.indexOf(semester);
      _initializing = false;
      _isCurrentSemester = (semester == _runningSemester);
      _catalog = []; // Clear current
    });
    _loadCatalog(); // Trigger load
  }

  void _nextSemester() async {
    if (_currentSemester == _runningSemester) {
      _finishOnboarding();
      return;
    }

    int nextIndex = _currentIndex + 1;
    if (nextIndex < _allSemesters.length) {
      final nextSem = _allSemesters[nextIndex];

      setState(() {
        _currentIndex = nextIndex;
        _currentSemester = nextSem;
        _searchQuery = "";
        _isCurrentSemester = (nextSem == _runningSemester);
        _catalog = []; // Clear

        if (_isCurrentSemester) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Now select courses for current semester"),
              duration: Duration(seconds: 2)));
        }
      });
      await _loadCatalog();
    } else {
      _finishOnboarding();
    }
  }

  /// Collects course details (name, section, schedule) for current semester enrollments
  List<Map<String, dynamic>> _collectEnrolledDetails() {
    final currentSemMap = _history[_runningSemester] ?? {};
    final details = <Map<String, dynamic>>[];

    for (final selection in currentSemMap.keys) {
      // Try to find matching catalog entry
      final match = _catalog.firstWhere(
        (c) {
          final key = _isCurrentSemester
              ? "${c['code']}_Sec${c['section']}"
              : c['code'].toString();
          return key == selection;
        },
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        details.add({
          'code': (match['code'] ?? selection).toString(),
          'name': (match['name'] ?? match['code'] ?? selection).toString(),
          'section': (match['section'] ?? '').toString(),
          'time': (match['time'] ?? '').toString(),
        });
      } else {
        // Extract code from selection key (e.g. "CSE101_Sec1" → "CSE101")
        final code = selection.contains('_Sec')
            ? selection.split('_Sec').first
            : selection;
        details.add({'code': code, 'name': code, 'section': '', 'time': ''});
      }
    }
    return details;
  }

  Future<void> _finishOnboarding() async {
    try {
      // Collect enrolled section IDs for the dashboard
      final currentSemMap = _history[_runningSemester] ?? {};
      final List<String> enrolledIds = [];

      for (final selection in currentSemMap.keys) {
        // Priority 1: Check explicit ID storage
        if (_selectedSectionIds.containsKey(selection)) {
          enrolledIds.addAll(_selectedSectionIds[selection]!);
          continue;
        }

        // Priority 2: Fallback to Catalog Lookup (e.g. restored data)
        final match = _catalog.firstWhere(
          (c) {
            final key = _isCurrentSemester
                ? "${c['code']}_Sec${c['section']}"
                : c['code'].toString();
            return key == selection;
          },
          orElse: () => {},
        );

        if (match.containsKey('allIds')) {
          enrolledIds.addAll(List<String>.from(match['allIds']));
        } else if (match.containsKey('id')) {
          enrolledIds.add(match['id']);
        }
      }

      await _repo.saveCourseHistory(
        _history,
        enrolledIds,
        _runningSemester,
        enrolledCourseDetails: _collectEnrolledDetails(),
      );

      // Trigger server-side CGPA recalculation (Azure Function)
      try {
        await AzureFunctionsService().recalculateStats();
        debugPrint('[Onboarding] CGPA recalculation triggered successfully');
      } catch (e) {
        debugPrint('[Onboarding] CGPA recalc failed (non-blocking): $e');
        // Non-blocking: onboarding continues even if Azure is not yet deployed
      }

      if (mounted) {
        if (widget.isEditMode) {
          Navigator.pop(context); // Return to Degree Progress
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Degree progress updated!")));
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Error saving data")));
      }
    }
  }

  void _addCourse(Map<String, dynamic> course) async {
    if (_currentSemester == null) return;

    final code = course['code'] as String;
    final selectionKey =
        _isCurrentSemester ? "${course['code']}_Sec${course['section']}" : code;
    final currentMap = _history[_currentSemester!] ?? {};

    if (currentMap.length >= 5 && !currentMap.containsKey(selectionKey)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Max 15 credits (approx 5 courses) allowed.")));
      return;
    }

    // Capture IDs immediately
    final List<String> ids = [];
    if (course.containsKey('allIds')) {
      ids.addAll(List<String>.from(course['allIds']));
    } else if (course.containsKey('id')) {
      ids.add(course['id']);
    }
    _selectedSectionIds[selectionKey] = ids;

    String grade = "Ongoing";
    if (!_isCurrentSemester) {
      final g = await _showGradeDialog(code);
      if (g == null) return;
      grade = g;
    }

    setState(() {
      currentMap[selectionKey] = grade;
      _history[_currentSemester!] = currentMap;
    });
  }

  void _removeCourse(String code) {
    setState(() {
      _history[_currentSemester!]?.remove(code);
      _selectedSectionIds.remove(code);
    });
  }

  Future<String?> _showGradeDialog(String code) {
    final grades = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "D", "F"];
    return showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
              title: Text("Grade for $code"),
              children: grades
                  .map((g) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, g),
                        child: Center(
                            child: Text(g,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
                      ))
                  .toList(),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final String nickname = user?.email?.split('@').first ?? "Student";

    // 1. Initial Prompt with Personalization & Gradient
    if (_profileLoading) {
      return const FullGradientScaffold(
          body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent)));
    }

    if (_initializing) {
      return FullGradientScaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.school_rounded,
                  size: 80, color: Colors.cyanAccent),
              const SizedBox(height: 24),
              Text(
                "$nickname, welcome to EWUmate!",
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Let's get your profile set up.\nPlease select your admitted semester at EWU.",
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ..._allSemesters.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GlassContainer(
                      borderRadius: 12,
                      color: Colors.white.withValues(alpha: 0.05),
                      borderColor: Colors.white.withValues(alpha: 0.1),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _confirmAdmittedSemester(s),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child: Text(s,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyanAccent))),
                          ),
                        ),
                      ),
                    ),
                  ))
            ],
          ),
        ),
      );
    }

    final currentMap = _history[_currentSemester] ?? {};

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          _isCurrentSemester ? "Current Semester" : "$_currentSemester",
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: GlassContainer(
          borderRadius: 16,
          color: Colors.cyanAccent.withValues(alpha: 0.1),
          borderColor: Colors.cyanAccent,
          onTap: _nextSemester,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isCurrentSemester
                      ? "FINISH REGISTRATION"
                      : "CONTINUE TO NEXT SEMESTER",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.cyanAccent,
                      letterSpacing: 1.2),
                ),
                const SizedBox(width: 8),
                Icon(_isCurrentSemester ? Icons.check : Icons.arrow_forward,
                    color: Colors.cyanAccent),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            color: _isCurrentSemester
                ? Colors.greenAccent.withValues(alpha: 0.1)
                : Colors.blueAccent.withValues(alpha: 0.1),
            borderColor: _isCurrentSemester
                ? Colors.greenAccent.withValues(alpha: 0.3)
                : Colors.blueAccent.withValues(alpha: 0.3),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isCurrentSemester)
                    const Text("Courses for Current Session",
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18))
                  else
                    Text("History: $_currentSemester",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.cyanAccent)),
                  const SizedBox(height: 4),
                  Text(
                      _isCurrentSemester
                          ? "Select courses you are taking now."
                          : "Tap a course below to select it.",
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const Text(
                      "You can find courses by code or name using search.",
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 16),
                  if (currentMap.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentMap.entries.map((e) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                // Edit Grade Interaction
                                // We pass the code (key) to dialog?
                                // Logic: e.key is "CSE101" or "CSE101_Sec1".
                                // Just pass explicit code if possible, or use key.
                                // _showGradeDialog expects clean code for title but returns grade.
                                final g = await _showGradeDialog(e.key);
                                if (g != null) {
                                  setState(() {
                                    currentMap[e.key] = g;
                                    _history[_currentSemester!] = currentMap;
                                  });
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                      backgroundColor: Colors.black26,
                                      radius: 10,
                                      child: Text(e.value.substring(0, 1),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white))),
                                  const SizedBox(width: 8),
                                  Text(e.key,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeCourse(e.key),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.white70),
                              ),
                            )
                          ],
                        );
                      }).toList(),
                    )
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: "Search Codes (e.g. ICE204)...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.cyanAccent)))
                            : const Icon(Icons.search,
                                color: Colors.cyanAccent),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.white10)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.white10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.cyanAccent)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05)),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.cyanAccent))
                      : _getFilteredCourses().isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off_rounded,
                                        size: 48, color: Colors.white24),
                                    SizedBox(height: 16),
                                    Text(
                                      "No courses found.\nTry a different code or check your spelling.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white38),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _getFilteredCourses().length,
                              itemBuilder: (ctx, i) {
                                final filtered = _getFilteredCourses();
                                final c = filtered[i];
                                final code = c['code']?.toString() ?? "???";
                                final selectionKey = _isCurrentSemester
                                    ? "${c['code']}_Sec${c['section']}"
                                    : code;
                                final isAdded =
                                    currentMap.containsKey(selectionKey);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: GlassContainer(
                                    opacity: 0.1,
                                    borderRadius: 12,
                                    onTap: () => _addCourse(c),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(code,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.cyanAccent,
                                                        fontSize: 16)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    c['name']?.toString() ?? "",
                                                    style: const TextStyle(
                                                        color: Colors.white70)),
                                                if (_isCurrentSemester &&
                                                    c.containsKey('section'))
                                                  Text(
                                                      "Sec: ${c['section']} | ${c['time']}",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .cyanAccent
                                                              .withValues(
                                                                  alpha: 0.8))),
                                              ],
                                            ),
                                          ),
                                          isAdded
                                              ? const Icon(Icons.check_circle,
                                                  color: Colors.greenAccent)
                                              : const Icon(
                                                  Icons.add_circle_outline,
                                                  color: Colors.white38),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
