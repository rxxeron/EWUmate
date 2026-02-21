import 'package:flutter/material.dart';

import '../../core/models/course_model.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/utils/course_utils.dart';
import '../calendar/academic_repository.dart';
import 'course_repository.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import 'package:go_router/go_router.dart';

class CourseBrowserScreen extends StatefulWidget {
  const CourseBrowserScreen({super.key});

  @override
  State<CourseBrowserScreen> createState() => _CourseBrowserScreenState();
}

class _CourseBrowserScreenState extends State<CourseBrowserScreen> {
  final CourseRepository _courseRepo = CourseRepository();
  final AcademicRepository _academicRepo = AcademicRepository();

  // State
  bool _isLoading = true;
  String _loadingStatus = "Initializing...";
  String _activeSemester = '';

  Map<String, List<Course>> _allCourses = {};
  Map<String, List<Course>> _filteredCourses = {};
  final Set<String> _filters = {'Available'};
  final TextEditingController _searchController = TextEditingController();

  // User-specific data
  Set<String> _completedCourses = {};
  Set<String> _enrolledSections = {};

  @override
  void initState() {
    super.initState();
    _initScreen();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initScreen() async {
    try {
      setState(() {
        _loadingStatus = "Loading user data...";
        _isLoading = true;
      });
      await _loadUserData();

      setState(() => _loadingStatus = "Finding active semester...");
      final config = await _academicRepo.getActiveSemesterConfig();
      final activeSemester = config['active_semester_code'] ?? await _academicRepo.getCurrentSemesterCode();
      
      if (mounted) {
        setState(() {
          _activeSemester = activeSemester;
        });
      }
      
      await _loadCourses();
    } catch (e) {
      debugPrint('Error initializing screen: $e');
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error initializing screen. Please try again.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _courseRepo.fetchUserData();
    if (mounted) {
      setState(() {
        _completedCourses = Set<String>.from(userData['completed_courses'] ?? []);
        _enrolledSections = Set<String>.from(userData['enrolled_sections'] ?? []);
      });
    }
  }

  Future<void> _loadCourses() async {
    if (_activeSemester.isEmpty) return;
    setState(() {
      _isLoading = true;
      _loadingStatus = "Loading courses for $_activeSemester...";
    });
    try {
      final courses = await _courseRepo.fetchCourses(_activeSemester);
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _debugPrintIDs();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not load course data.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _debugPrintIDs() {
    debugPrint('--- DEBUG COURSE IDs ---');
    debugPrint('Enrolled Sections: $_enrolledSections');
    if (_allCourses.containsKey('ICE107')) {
      final sections = _allCourses['ICE107']!;
      for (var s in sections) {
        debugPrint('ICE107 Section: ${s.section}, id: ${s.id}, docId: ${s.docId}');
      }
    } else {
      debugPrint('ICE107 NOT FOUND in _allCourses!');
    }
  }

  void _applyFilters() {
    Map<String, List<Course>> partiallyFiltered = {};
    final query = _searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      _allCourses.forEach((code, sections) {
        if (code.toLowerCase().contains(query) ||
            sections.first.courseName.toLowerCase().contains(query)) {
          partiallyFiltered[code] = sections;
        }
      });
    } else {
      partiallyFiltered = Map.from(_allCourses);
    }

    final Map<String, List<Course>> fullyFiltered = {};

    partiallyFiltered.forEach((code, sections) {
      final isCourseTaken = _completedCourses.contains(code);
      final isCourseEnrolled = sections.any((s) => _enrolledSections.contains(s.docId ?? s.id));
      
      // If it's a search, we want to show all sections of the matched course so they can switch
      if (query.isNotEmpty) {
        fullyFiltered[code] = sections;
        return;
      }
      
      // No filters active? Show all sections.
      if (_filters.isEmpty) {
        fullyFiltered[code] = sections;
        return;
      }

      if (code == 'ICE107') {
        debugPrint('ICE107 Filtering -> isCourseEnrolled: $isCourseEnrolled, isCourseTaken: $isCourseTaken, filters: $_filters');
      }

      // If 'Taken' is active and we are enrolled, we only want to show the ENROLLED section in the Taken view,
      // UNLESS 'Available' is ALSO active, then they're probably looking to switch, so show all.
      // Or if it's completed, show all sections that we took (usually just the one in the past, but we might just show all to indicate "Completed").
      if (_filters.contains('Taken')) {
        if (isCourseTaken) {
          fullyFiltered[code] = sections; 
        } else if (isCourseEnrolled) {
          // Only show the specific sections they are enrolled in
          final enrolledOnly = sections.where((s) => _enrolledSections.contains(s.docId ?? s.id)).toList();
          if (enrolledOnly.isNotEmpty) {
            fullyFiltered[code] = enrolledOnly;
          }
        }
      } 
      else if (_filters.contains('Available')) {
        // If they are enrolled, show all sections so they can switch
        if (isCourseEnrolled) {
          fullyFiltered[code] = sections;
        } 
        // If not enrolled and not taken, show all sections
        else if (!isCourseTaken) {
           fullyFiltered[code] = sections;
        }
      }
    });

    debugPrint('fullyFiltered length after applyFilters: ${fullyFiltered.length}');
    if(mounted) setState(() => _filteredCourses = fullyFiltered);
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_filters.contains(filter)) {
        _filters.remove(filter);
      } else {
        // Make 'Available' and 'Taken' mutually exclusive
        if (filter == 'Available') {
          _filters.remove('Taken');
        } else if (filter == 'Taken') {
          _filters.remove('Available');
        }
        _filters.add(filter);
      }
      _applyFilters();
    });
  }
  
  void _toggleEnrollment(Course course, bool enroll) async {
    if (!mounted) return;

    // --- TIME CONFLICT CHECK ---
    if (enroll) {
      // Build a list of currently enrolled courses to check against.
      // We skip any sections that belong to the SAME course code, because 
      // when switching, the old section will be dropped anyway.
      List<Course> currentlyEnrolledCourses = [];
      _filteredCourses.forEach((code, sections) {
        if (code == course.code) return; // Skip the course being switched
        
        for (var s in sections) {
          if (_enrolledSections.contains(s.docId ?? s.id)) {
            currentlyEnrolledCourses.add(s);
          }
        }
      });

      final conflictCourse = CourseUtils.hasTimeConflict(currentlyEnrolledCourses, course);
      if (conflictCourse != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Time conflict with ${conflictCourse.code} (${conflictCourse.courseName}).'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ));
        }
        return; // Abort enrollment
      }
    }

    final originalEnrolled = Set<String>.from(_enrolledSections);

    setState(() {
      if (enroll) {
        // Switching logic: remove any other sections of the same course first
        final sections = _allCourses[course.code] ?? [];
        for (var s in sections) {
          _enrolledSections.remove(s.docId ?? s.id);
        }
        _enrolledSections.add(course.docId ?? course.id);
      } else {
        _enrolledSections.remove(course.docId ?? course.id);
      }
      _applyFilters();
    });

    try {
      await _courseRepo.toggleEnrolled(
        course.docId ?? course.id,
        enroll,
        semesterCode: _activeSemester,
        courseName: course.courseName,
        courseCode: course.code,
      );
      if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(enroll ? 'Enrolled in ${course.code}' : 'Dropped ${course.code}'),
        backgroundColor: enroll ? Colors.green : Colors.red,
      ));
    } catch (e) {
      debugPrint('Error toggling enrollment: $e');
      if (mounted) {
        setState(() {
          _enrolledSections = originalEnrolled;
          _applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EWUmateAppBar(
          title: 'Course Browser',
          showBack: true,
        ),
        _buildSearchBar(),
        _buildFilterChips(),
        if (_activeSemester.isNotEmpty) _buildSemesterHeader(),
        Expanded(
          child: _isLoading
              ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.cyanAccent),
                  const SizedBox(height: 15),
                  Text(_loadingStatus, style: const TextStyle(color: Colors.white70)),
                ],
              ))
              : _buildCourseList(),
        ),
      ],
    );
  }

  // Removed manual _buildHeader as it's replaced by EWUmateAppBar
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by course code or name...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withAlpha(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          )
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: ['Available', 'Taken'].map((filter) {
          final isSelected = _filters.contains(filter);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => _toggleFilter(filter),
              backgroundColor: Colors.white.withAlpha(20),
              selectedColor: Colors.cyanAccent,
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
              checkmarkColor: Colors.black,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSemesterHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Text(
              "Active Semester: $_activeSemester", 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    final courseCodes = _filteredCourses.keys.toList()..sort();
    if (courseCodes.isEmpty && !_isLoading) {
      return const Center(
          child: Text('No courses found for the selected criteria.',
              style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: courseCodes.length,
      itemBuilder: (context, index) {
        final code = courseCodes[index];
        final sections = _filteredCourses[code]!;
        if (sections.isEmpty) return const SizedBox.shrink();
        
        final courseName = sections.first.courseName;
        final isTaken = _completedCourses.contains(code);
        final isEnrolled = sections.any((s) => _enrolledSections.contains(s.docId ?? s.id));

        return _buildCourseCard(
            code, courseName, sections, isTaken, isEnrolled);
      },
    );
  }

  Widget _buildCourseCard(String code, String name, List<Course> sections, bool isTaken, bool isEnrolled) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      child: ExpansionTile(
        title: Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(name, style: const TextStyle(color: Colors.white70)),
        trailing: isEnrolled 
            ? const Chip(label: Text('Enrolled'), backgroundColor: Colors.green) 
            : isTaken 
                ? const Chip(label: Text('Taken'), backgroundColor: Colors.blueGrey)
                : null,
        children: sections.map((section) => _buildSectionTile(section, sections)).toList(),
      ),
    );
  }

  Widget _buildSectionTile(Course section, List<Course> allSections) {
    final isCourseTaken = _completedCourses.contains(section.code);
    
    final isEnrolledInThis = _enrolledSections.contains(section.docId ?? section.id);
                             
    final isEnrolledInAnother = !isEnrolledInThis && allSections.any((s) => _enrolledSections.contains(s.docId ?? s.id));

    return ListTile(
      title: Text('Section ${section.section}', style: TextStyle(color: Colors.white, fontWeight: isEnrolledInThis ? FontWeight.bold : FontWeight.normal)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: section.sessions.map((s) => Text('${s.day} ${s.startTime}-${s.endTime} (${s.faculty})', style: const TextStyle(color: Colors.white70))).toList(),
      ),
      trailing: isEnrolledInThis
          ? ElevatedButton.icon(
              onPressed: () => _toggleEnrollment(section, false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              label: const Text('Drop'),
            )
          : isEnrolledInAnother
              ? ElevatedButton.icon(
                  onPressed: () => _toggleEnrollment(section, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Switch'),
                )
              : isCourseTaken
                  ? const Chip(label: Text('Completed'), backgroundColor: Colors.blueGrey)
                  : ElevatedButton.icon(
                      onPressed: () => _toggleEnrollment(section, true),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Enroll'),
                    ),
    );
  }
}
