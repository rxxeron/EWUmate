import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/models/course_model.dart';
import '../../core/widgets/glass_kit.dart';
import 'course_repository.dart';
import '../calendar/academic_repository.dart';

class CourseBrowserScreen extends StatefulWidget {
  final String? initialSemesterCode;

  const CourseBrowserScreen({super.key, this.initialSemesterCode});

  @override
  State<CourseBrowserScreen> createState() => _CourseBrowserScreenState();
}

class _CourseBrowserScreenState extends State<CourseBrowserScreen> {
  final CourseRepository _courseRepo = CourseRepository();
  final AcademicRepository _academicRepo = AcademicRepository();
  final TextEditingController _searchController = TextEditingController();

  String _semesterCode = '';
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  List<String> _enrolledIds = [];
  bool _loading = true;
  String _error = '';
  bool _canModify = true;
  bool _isLockedBeforeAdvising = false;
  DateTime? _advisingDate;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      // 1. Determine Semester
      if (widget.initialSemesterCode != null) {
        _semesterCode = widget.initialSemesterCode!;
      } else {
        _semesterCode = await _academicRepo.getCurrentSemesterCode();
      }

      // 2. Check Advising Lock (Start Date)
      final advisingDate =
          await _academicRepo.getOnlineAdvisingDate(_semesterCode);
      _advisingDate = advisingDate;

      if (advisingDate != null) {
        if (DateTime.now().isBefore(advisingDate)) {
          _isLockedBeforeAdvising = true;
          // If locked, we stop loading data here?
          // User said "course browser should get blocked".
          // So we return early.
          setState(() => _loading = false);
          return;
        }
      }

      // 3. Check Modification Allowed (End Date)
      final addingDate =
          await _academicRepo.getAddingOfCoursesDate(_semesterCode);
      // Logic: If adding date passed, modification is closed (Read Only)
      // Usually user wants to see courses but not enroll?
      // Assuming existing logic: _canModify handles this.
      _canModify = addingDate == null || DateTime.now().isBefore(addingDate);

      await _loadData();
    } catch (e) {
      debugPrint('[CourseBrowser] Init error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to initialize';
        });
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final userData = await _courseRepo.fetchUserData();
      final courses = await _courseRepo.fetchCourses(_semesterCode);

      // Filter Logic (Same as Advising)
      final lastSemCode = _getPrecedingSemester(_semesterCode);
      final academicResults = userData['academicResults'] ?? [];

      final filteredList = courses.where((c) {
        // Check Capacity
        final capacity = c.capacity ?? "0/0";
        if (capacity == "0/0" || capacity.endsWith("/0")) return false;

        // History Check
        bool isHidden = false;
        bool forceShow = false;

        for (var r in academicResults) {
          if (r['courseCode'] != c.code) continue;

          final sem = r['semesterId'] ?? '';
          final grade = r['grade'] ?? '';

          if (sem == _semesterCode) {
            // If it's the current semester course browser, usually we SHOW enrolled courses?
            // User said "remove current" in ADVISING.
            // But for "Course Browser" (Current Sem), if I am enrolled, I definitely want to see it!
            // "for course browser it should include last semester couse"
            // "courses from previous semesterv than last won't show unless it has a f grade"

            // If I am enrolled in THIS semester, I should see it in Course Browser.
            // So I do NOT hide if sem == _semesterCode.
            forceShow = true;
            continue;
          }

          if (sem == lastSemCode) {
            forceShow = true; // Last semester - Show
          } else if (_isOlder(sem, lastSemCode)) {
            if (grade != 'F') {
              isHidden = true; // Passed in older semester
            }
          }
        }

        if (forceShow) return true;
        if (isHidden) return false;

        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _enrolledIds = List<String>.from(userData['enrolledSections'] ?? []);
          _allCourses = filteredList;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[CourseBrowser] Load error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load courses';
        });
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredCourses = _allCourses;
    } else {
      _filteredCourses = _allCourses.where((c) {
        return c.code.toLowerCase().contains(query) ||
            c.courseName.toLowerCase().contains(query) ||
            (c.faculty?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  // ===== Enrollment Logic =====

  Future<void> _handleCourseAction(Course course) async {
    final isEnrolledExact = _enrolledIds.contains(course.id);
    final enrolledSectionId = _getEnrolledSectionForCode(course.code);

    if (isEnrolledExact) {
      _showDropDialog(course);
    } else if (enrolledSectionId != null) {
      _showChangeSectionDialog(course, enrolledSectionId);
    } else if (_enrolledIds.length < 5) {
      await _attemptEnroll(course);
    } else if (_canModify) {
      _showSwapDialog(course);
    } else {
      _showSnack("Max courses reached. Cannot add more.");
    }
  }

  String? _getEnrolledSectionForCode(String code) {
    for (var id in _enrolledIds) {
      final c = _allCourses.firstWhere((e) => e.id == id,
          orElse: () => Course(id: '', code: '', courseName: ''));
      if (c.id.isNotEmpty && c.code == code) {
        return c.id;
      }
    }
    return null;
  }

  Future<void> _attemptEnroll(Course course) async {
    // Conflict check
    for (final id in _enrolledIds) {
      final existing = _allCourses.firstWhere((c) => c.id == id,
          orElse: () => Course(id: '', code: '', courseName: ''));
      if (existing.id.isEmpty) continue;

      if (_hasConflict(existing, course)) {
        _showSnack("Conflict with ${existing.courseName}", isError: true);
        return;
      }
    }

    try {
      await _courseRepo.toggleEnrolled(course.id, true,
          semesterCode: _semesterCode, courseName: course.courseName);
      setState(() => _enrolledIds.add(course.id));
      _showSnack("Enrolled in ${course.code}");
    } catch (e) {
      _showSnack("Enrollment failed", isError: true);
    }
  }

  Future<void> _dropCourse(String courseId) async {
    try {
      await _courseRepo.toggleEnrolled(courseId, false,
          semesterCode: _semesterCode);
      setState(() => _enrolledIds.remove(courseId));
      _showSnack("Course dropped");
    } catch (e) {
      _showSnack("Drop failed", isError: true);
    }
  }

  bool _hasConflict(Course a, Course b) {
    // Check all sessions of both courses
    for (var sessionA in a.sessions) {
      for (var sessionB in b.sessions) {
        if (sessionA.day == sessionB.day) {
          final startA = _parseTime(sessionA.startTime);
          final endA = _parseTime(sessionA.endTime);
          final startB = _parseTime(sessionB.startTime);
          final endB = _parseTime(sessionB.endTime);
          if (startA < endB && endA > startB) {
            return true;
          }
        }
      }
    }
    return false;
  }

  int _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return -1;
    try {
      final lower = timeStr.toLowerCase().trim();
      bool isPm = lower.contains('pm');
      final clean = lower.replaceAll(RegExp(r'[a-z]'), '').trim();
      final parts = clean.split(':');
      int h = int.parse(parts[0]);
      int m = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPm && h < 12) h += 12;
      if (!isPm && h == 12) h = 0;
      return h * 60 + m;
    } catch (_) {
      return -1;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF1A1A2E),
    ));
  }

  // ===== Dialogs =====

  void _showDropDialog(Course course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text("Drop Course?", style: TextStyle(color: Colors.white)),
        content: Text("Drop ${course.code} - ${course.courseName}?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _dropCourse(course.id);
            },
            child:
                const Text("Drop", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showChangeSectionDialog(Course newSection, String oldSectionId) {
    final oldSection = _allCourses.firstWhere((c) => c.id == oldSectionId,
        orElse: () => Course(id: '', code: '', courseName: ''));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Change Section?",
            style: TextStyle(color: Colors.white)),
        content: Text(
          "Switch from Section ${oldSection.section} to Section ${newSection.section}?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _dropCourse(oldSectionId);
              await _attemptEnroll(newSection);
            },
            child: const Text("Change",
                style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _showSwapDialog(Course newCourse) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text("Swap Course",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Select a course to drop:",
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ..._enrolledIds.map((id) {
                final c = _allCourses.firstWhere((e) => e.id == id,
                    orElse: () => Course(id: '', code: '', courseName: ''));
                if (c.id.isEmpty) return const SizedBox();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("${c.code} - ${c.courseName}",
                      style: const TextStyle(color: Colors.white)),
                  trailing:
                      const Icon(Icons.swap_horiz, color: Colors.cyanAccent),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _dropCourse(id);
                    await _attemptEnroll(newCourse);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Build Methods =====

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      scaffoldKey: GlobalKey<ScaffoldState>(),
      appBar: AppBar(
        title: const Text(
          "Browse Courses",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLockedBeforeAdvising
          ? Center(
              child: GlassContainer(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_clock,
                        size: 64, color: Colors.white38),
                    const SizedBox(height: 16),
                    const Text(
                      "Advising Locked",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Course selection for $_semesterCode is not yet open.",
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    if (_advisingDate != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    Colors.cyanAccent.withValues(alpha: 0.3))),
                        child: Text(
                          "Starts: ${_advisingDate!.day}/${_advisingDate!.month}/${_advisingDate!.year}",
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            )
          : Column(
              children: [
                _buildSearchHeader(),
                Expanded(child: _buildCourseList()),
              ],
            ),
    );
  }

  Widget _buildSearchHeader() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      borderRadius: 24,
      blur: 15,
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Semester",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.cyanAccent.withValues(alpha: 0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _semesterCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _canModify
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _canModify
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _canModify ? "Enrollment Open" : "Enrollment Closed",
                  style: TextStyle(
                    color:
                        _canModify ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search courses...",
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.cyanAccent),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) => setState(() => _applyFilter()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "${_enrolledIds.length}/5",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Grouping Logic ---
  Map<String, List<Course>> get _groupedCourses {
    final Map<String, List<Course>> groups = {};
    for (var c in _filteredCourses) {
      groups.putIfAbsent(c.code, () => []).add(c);
    }
    return groups;
  }

  Widget _buildCourseList() {
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
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                foregroundColor: Colors.cyanAccent,
              ),
              child: const Text("Retry"),
            )
          ],
        ),
      );
    }
    if (_filteredCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? "No courses available"
                  : "No courses found",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    final groups = _groupedCourses.entries.toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.cyanAccent,
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: groups.length,
        itemBuilder: (_, i) => _buildGroupCard(groups[i].key, groups[i].value),
      ),
    );
  }

  Widget _buildGroupCard(String code, List<Course> sections) {
    // Check enrollment status for this code
    final enrolledId = _getEnrolledSectionForCode(code);
    final enrolledSection = enrolledId != null
        ? sections.firstWhere((s) => s.id == enrolledId,
            orElse: () => sections.first)
        : null;

    final first = sections.first;
    final isEnrolled = enrolledSection != null;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 20,
      padding: const EdgeInsets.all(0), // Padding handled inside
      opacity: 0.05,
      onTap: () => _showSectionsSheet(code, sections),
      child: Stack(
        children: [
          // Gradient splash
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isEnrolled ? Colors.green : Colors.cyanAccent)
                        .withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isEnrolled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Sec ${enrolledSection.section}",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  first.courseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.class_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${sections.length} Sections Available",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSectionsSheet(String code, List<Course> sections) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Important for glass effect
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 16, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  code,
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Available Sections",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${sections.length}",
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: sections.length,
                          itemBuilder: (context, index) {
                            final section = sections[index];
                            final isEnrolled =
                                _enrolledIds.contains(section.id);
                            final enrolledInOther = !isEnrolled &&
                                _getEnrolledSectionForCode(code) != null;

                            // Check conflict if not enrolled
                            final hasConflict = !isEnrolled &&
                                !enrolledInOther &&
                                _checkConflictWithEnrolled(section);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: isEnrolled
                                    ? Colors.green.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isEnrolled
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : (hasConflict
                                          ? Colors.redAccent
                                              .withValues(alpha: 0.3)
                                          : Colors.white
                                              .withValues(alpha: 0.05)),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.05),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                "${section.section}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            if (section.faculty?.isNotEmpty ==
                                                true)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Faculty",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                        alpha: 0.4,
                                                      ),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  Text(
                                                    section.faculty!,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        if (isEnrolled)
                                          _buildStatusChip(
                                            "Enrolled",
                                            Colors.green,
                                          )
                                        else if (enrolledInOther)
                                          _buildStatusChip(
                                            "Switch?",
                                            Colors.orangeAccent,
                                          )
                                        else if (hasConflict)
                                          _buildStatusChip(
                                              "Conflict", Colors.red)
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildInfoRow(
                                          Icons.access_time_rounded,
                                          section.sessions
                                              .map(
                                                (s) =>
                                                    "${s.day} ${s.startTime}-${s.endTime}",
                                              )
                                              .join("\n"),
                                        ),
                                        if (section.room?.isNotEmpty ==
                                            true) ...[
                                          const SizedBox(height: 12),
                                          _buildInfoRow(
                                            Icons.location_on_outlined,
                                            section.room!,
                                          ),
                                        ],
                                        if (_canModify) ...[
                                          const SizedBox(height: 16),
                                          _buildActionBtn(
                                            section,
                                            isEnrolled,
                                            enrolledInOther,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
      Course section, bool isEnrolled, bool enrolledInOther) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: isEnrolled
              ? Colors.redAccent.withValues(alpha: 0.1)
              : (enrolledInOther ? Colors.orange : Colors.cyanAccent),
          foregroundColor: isEnrolled
              ? Colors.redAccent
              : (enrolledInOther ? Colors.white : Colors.black),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isEnrolled
                ? const BorderSide(color: Colors.redAccent)
                : BorderSide.none,
          ),
        ),
        onPressed: () async {
          Navigator.pop(context); // Close sheet first
          // Small delay to allow sheet to close smoothly before dialog appears?
          // Not strictly necessary but safe.
          await _handleCourseAction(section);
        },
        child: Text(
          isEnrolled
              ? "Drop Course"
              : (enrolledInOther ? "Switch to this Section" : "Enroll Now"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  bool _checkConflictWithEnrolled(Course target) {
    for (final id in _enrolledIds) {
      final existing = _allCourses.firstWhere((c) => c.id == id,
          orElse: () => Course(id: '', code: '', courseName: ''));
      if (existing.id.isEmpty) continue;
      if (_hasConflict(existing, target)) return true;
    }
    return false;
  }

  // Helper Methods
  String _getPrecedingSemester(String current) {
    if (current.isEmpty) return "";
    final parts = current.split(' ');
    if (parts.length != 2) return current;

    final season = parts[0];
    final year = int.tryParse(parts[1]) ?? 2025;

    if (season == "Spring") return "Fall ${year - 1}";
    if (season == "Summer") return "Spring $year";
    if (season == "Fall") return "Summer $year";
    return current;
  }

  bool _isOlder(String semToCheck, String baseline) {
    if (semToCheck == baseline) return false;
    // Simple lookup/comparison logic or use existing Academic helper
    // For now, simple year comparison
    final p1 = semToCheck.split(' ');
    final p2 = baseline.split(' ');
    if (p1.length != 2 || p2.length != 2) return false;

    final y1 = int.parse(p1[1]);
    final y2 = int.parse(p2[1]);

    if (y1 < y2) return true;
    if (y1 > y2) return false;

    // Same year
    final order = {"Spring": 1, "Summer": 2, "Fall": 3};
    return (order[p1[0]] ?? 0) < (order[p2[0]] ?? 0);
  }
}
