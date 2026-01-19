import 'package:flutter/material.dart';

import '../../core/widgets/glass_kit.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import 'package:intl/intl.dart';

class AdvisingScreen extends StatefulWidget {
  const AdvisingScreen({super.key});

  @override
  State<AdvisingScreen> createState() => _AdvisingScreenState();
}

class _AdvisingScreenState extends State<AdvisingScreen>
    with SingleTickerProviderStateMixin {
  final AcademicRepository _academicRepo = AcademicRepository();
  final CourseRepository _courseRepo = CourseRepository();

  late TabController _tabController;

  bool _loading = true;
  bool _isLocked = true;
  String _lockMessage = '';

  String _nextSemesterCode = '';

  // Data
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];

  // Manual Plan State
  final List<Course> _selectedSections = [];

  // Generator State
  final Set<String> _selectedCodes = {};

  // Search

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    try {
      final currentCode = await _academicRepo.getCurrentSemesterCode();
      // Simple next semester calculation
      _nextSemesterCode = _calculateNextSemester(currentCode);

      final advisingDate =
          await _academicRepo.getOnlineAdvisingDate(currentCode);

      if (advisingDate != null) {
        final plannerOpenDate = advisingDate.subtract(const Duration(days: 7));
        final now = DateTime.now();

        if (now.isBefore(plannerOpenDate)) {
          _isLocked = true;
          _lockMessage =
              "Planner opens on ${DateFormat('MMM d').format(plannerOpenDate)}.\nAdvising starts on ${DateFormat('MMM d').format(advisingDate)}.";
        } else {
          _isLocked = false;
        }
      } else {
        // Fallback if no date set
        _isLocked = false;
      }

      if (!_isLocked) {
        await _loadCourses();
      }
    } catch (e) {
      debugPrint("Advising Init Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _calculateNextSemester(String current) {
    // Basic rotation logic: Spring -> Summer -> Fall
    final match = RegExp(r'([a-zA-Z]+)(\d{4})').firstMatch(current);
    if (match != null) {
      final season = match.group(1)!;
      final year = int.parse(match.group(2)!);
      if (season.contains('Spring')) return 'Summer$year';
      if (season.contains('Summer')) return 'Fall$year';
      if (season.contains('Fall')) return 'Spring${year + 1}';
    }
    return current; // Fallback
  }

  Future<void> _loadCourses() async {
    // Fetch courses for NEXT semester
    final courses = await _courseRepo.fetchCourses(_nextSemesterCode);
    setState(() {
      _allCourses = courses;
      _filteredCourses = courses;
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCourses = _allCourses;
      } else {
        _filteredCourses = _allCourses
            .where((c) =>
                c.code.toLowerCase().contains(query.toLowerCase()) ||
                c.courseName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // --- Logic: Overlap Check ---
  bool _hasOverlap(Course newCourse) {
    for (final existing in _selectedSections) {
      // 1. Same Course Code? (Can't take two sections of same course usually)
      if (existing.code == newCourse.code) return true;

      // 2. Time Overlap
      if (_checkTimeOverlap(existing, newCourse)) return true;
    }
    return false;
  }

  bool _checkTimeOverlap(Course a, Course b) {
    if (a.day != b.day) return false;

    // Parse times "08:00 AM" -> minutes from midnight
    final startA = _parseTime(a.startTime);
    final endA = _parseTime(a.endTime);
    final startB = _parseTime(b.startTime);
    final endB = _parseTime(b.endTime);

    if (startA == null || endA == null || startB == null || endB == null) {
      // Fallback: Exact string match if parsing fails
      return a.startTime == b.startTime;
    }

    // Overlap if (StartA < EndB) and (StartB < EndA)
    return startA < endB && startB < endA;
  }

  int? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      // Expected format: "hh:mm a" e.g., "08:00 AM"
      final format = DateFormat("hh:mm a");
      // Current date dummy
      // final now = DateTime.now();
      final dt = format.parse(timeStr.trim().toUpperCase());
      return dt.hour * 60 + dt.minute;
    } catch (e) {
      return null;
    }
  }

  void _toggleSection(Course course) {
    final isSelected = _selectedSections.contains(course);

    if (isSelected) {
      setState(() => _selectedSections.remove(course));
    } else {
      // Check Overlap
      if (_hasOverlap(course)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Conflict detected! Overlaps with existing selection or same course.")));
        return;
      }
      setState(() => _selectedSections.add(course));
    }
  }

  void _toggleGeneratorCode(String code) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
      } else {
        _selectedCodes.add(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.cyanAccent))
                      : _isLocked
                          ? _buildLockedView()
                          : _buildPlannerView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Advising Planner",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              if (_nextSemesterCode.isNotEmpty)
                Text(_nextSemesterCode,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: GlassContainer(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock, size: 64, color: Colors.white38),
            const SizedBox(height: 20),
            const Text(
              "Planner Locked",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _lockMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannerView() {
    return Column(
      children: [
        // Tabs
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "Manual Plan"),
            Tab(text: "Smart Generator"),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildManualTab(),
              _buildGeneratorTab(),
            ],
          ),
        )
      ],
    );
  }

  // --- Manual Tab ---

  Widget _buildManualTab() {
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: _search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search courses...",
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),

        // Selected Summary
        if (_selectedSections.isNotEmpty)
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _selectedSections
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text("${c.code}-${c.section}"),
                          backgroundColor: Colors.cyanAccent,
                          onDeleted: () => _toggleSection(c),
                        ),
                      ))
                  .toList(),
            ),
          ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredCourses.length,
            itemBuilder: (context, index) {
              final course = _filteredCourses[index];
              return _buildCourseCard(course, isManual: true);
            },
          ),
        ),
      ],
    );
  }

  // --- Generator Tab ---

  Widget _buildGeneratorTab() {
    // Get unique codes
    final uniqueCodes = _allCourses.map((c) => c.code).toSet().toList();
    uniqueCodes.sort();

    return Column(
      children: [
        // Selection Area
        Container(
          height: MediaQuery.of(context).size.height * 0.35, // Limit height
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Select Subjects (${_selectedCodes.length})",
                  style: const TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: uniqueCodes.length,
                  itemBuilder: (context, index) {
                    final code = uniqueCodes[index];
                    final isSelected = _selectedCodes.contains(code);
                    return GestureDetector(
                      onTap: () => _toggleGeneratorCode(code),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.cyanAccent.withValues(alpha: 0.2)
                                : Colors.white10,
                            border: Border.all(
                                color: isSelected
                                    ? Colors.cyanAccent
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(code,
                                style: const TextStyle(color: Colors.white)),
                            if (isSelected)
                              const Icon(Icons.check,
                                  color: Colors.cyanAccent, size: 16)
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Action Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: (_selectedCodes.isEmpty || _isGenerating)
                  ? null
                  : _runGenerator,
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text("Generate Schedules",
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),

        const Divider(color: Colors.white24),

        // History List
        Expanded(
          child: _generatedHistory.isEmpty
              ? const Center(
                  child: Text("No generated schedules yet.",
                      style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _generatedHistory.length,
                  itemBuilder: (context, index) {
                    final schedule = _generatedHistory[index];
                    return _buildScheduleCard(index, schedule);
                  },
                ),
        )
      ],
    );
  }

  Widget _buildScheduleCard(int index, List<Course> schedule) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Option ${index + 1} (${schedule.length} Courses)",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(
                icon:
                    const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                onPressed: () {
                  setState(() {
                    _generatedHistory.removeAt(index);
                  });
                },
              )
            ],
          ),
          const Divider(color: Colors.white12),
          ...schedule.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                        width: 60,
                        child: Text(c.code,
                            style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text(
                            "Sec ${c.section} • ${c.day} ${c.startTime}",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12))),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: () {
                // Apply this schedule to Manual Plan?
                setState(() {
                  _selectedSections.clear();
                  _selectedSections.addAll(schedule);
                  _tabController.animateTo(0); // Switch to Manual View
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Schedule applied to Manual Plan")));
              },
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24)),
              child: const Text("Use This Schedule",
                  style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  // Generator Result State
  // Storing list of schedules (each schedule is a List<Course>)
  final List<List<Course>> _generatedHistory = [];
  bool _isGenerating = false;

  // Cache for recursion
  Map<String, List<Course>> candidatesCache = {};

  void _runGenerator() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 100)); // UI release

    candidatesCache = {};
    for (var code in _selectedCodes) {
      final sections = _allCourses.where((c) {
        if (c.code != code) return false;
        // Capacity Check: Ignore "0/0"
        if (c.capacity == "0/0" ||
            (c.capacity != null && c.capacity!.endsWith("/0"))) {
          return false;
        }
        return true;
      }).toList();

      if (sections.isNotEmpty) candidatesCache[code] = sections;
    }

    final keys = candidatesCache.keys.toList();
    final results = <List<Course>>[];

    // Recursive Backtracking
    void solve(int idx, List<Course> path) {
      if (results.length >= 10) return;
      // Base Case
      if (idx == keys.length) {
        results.add(List.from(path));
        return;
      }

      final code = keys[idx];
      final possible = candidatesCache[code]!;

      for (var s in possible) {
        // Overlap check
        bool conflict = path.any((p) => _checkTimeOverlap(p, s));
        if (!conflict) {
          path.add(s);
          solve(idx + 1, path);
          path.removeLast();
          if (results.length >= 10) return;
        }
      }
    }

    solve(0, []);

    setState(() {
      _isGenerating = false;
      if (results.isNotEmpty) {
        // Add unique results to history (prepend)
        _generatedHistory.insertAll(0, results);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Generated ${results.length} schedules.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No conflict-free schedules found.")));
      }
    });
  }

  // Update the Tab Build to show history
  // ... (Will do in a separate replacement chunk for the Widget)

  Widget _buildCourseCard(Course course, {required bool isManual}) {
    final isSelected = _selectedSections.contains(course);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: isSelected ? Colors.cyanAccent : Colors.white10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${course.code} - Sec ${course.section}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              if (isManual)
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isSelected,
                    activeTrackColor: Colors.cyanAccent,
                    onChanged: (_) => _toggleSection(course),
                  ),
                )
            ],
          ),
          const SizedBox(height: 8),
          Text(course.courseName,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(course.faculty ?? 'TBA',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13))),
              const Icon(Icons.schedule, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Text("${course.day} ${course.startTime}",
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          )
        ],
      ),
    );
  }
}
