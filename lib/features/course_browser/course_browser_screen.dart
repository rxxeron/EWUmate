import 'package:flutter/material.dart';

import '../../core/models/course_model.dart';
import '../../core/widgets/glass_kit.dart';
import '../calendar/academic_repository.dart';
import 'course_repository.dart';

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
  List<String> _semesters = [];
  String _selectedSemester = '';

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

      setState(() => _loadingStatus = "Finding current semester...");
      final currentSemester = await _academicRepo.getCurrentSemesterCode();
      final semesters = _generateSemesterList(currentSemester);
      
      if (mounted) {
        setState(() {
          _semesters = semesters;
          _selectedSemester = currentSemester;
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
        _completedCourses = Set<String>.from(userData['completedCourses'] ?? []);
        _enrolledSections = Set<String>.from(userData['enrolledSections'] ?? []);
      });
    }
  }

  List<String> _generateSemesterList(String currentSemester) {
    // This logic might need to be adjusted based on actual semester code formats
    final List<String> semesters = [currentSemester];
    String tempSemester = currentSemester;
    for (int i = 0; i < 6; i++) {
       final match = RegExp(r'([a-zA-Z]+)(\d{4})').firstMatch(tempSemester);
        if (match != null) {
          String season = match.group(1)!;
          int year = int.parse(match.group(2)!);
          if (season == 'Spring') {
            tempSemester = 'Fall${year - 1}';
          } else if (season == 'Summer') {
            tempSemester = 'Spring$year';
          } else { // Fall
            tempSemester = 'Summer$year';
          }
          semesters.add(tempSemester);
        }
    }
    return semesters;
  }

  Future<void> _loadCourses() async {
    if (_selectedSemester.isEmpty) return;
    setState(() {
      _isLoading = true;
      _loadingStatus = "Loading courses for $_selectedSemester...";
    });
    try {
      final courses = await _courseRepo.fetchCourses(_selectedSemester);
      if (mounted) {
        setState(() {
          _allCourses = courses;
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
      final filteredSections = sections.where((section) {
        final isTaken = _completedCourses.contains(section.code);
        final isEnrolled = _enrolledSections.contains(section.id);
        
        if (isEnrolled) return true; 

        bool matchesFilter = false;
        if (_filters.contains('Available') && !isTaken) {
          matchesFilter = true;
        }
        if (_filters.contains('Taken') && isTaken) {
          matchesFilter = true;
        }
        return matchesFilter;
      }).toList();

      if (filteredSections.isNotEmpty) {
        fullyFiltered[code] = filteredSections;
      }
    });
    
    if(mounted) setState(() => _filteredCourses = fullyFiltered);
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_filters.contains(filter)) {
        _filters.remove(filter);
      } else {
        _filters.add(filter);
      }
      _applyFilters();
    });
  }
  
  void _toggleEnrollment(Course course, bool enroll) async {
    if (!mounted) return;

    final originalEnrolled = Set<String>.from(_enrolledSections);

    setState(() {
      if (enroll) {
        _enrolledSections.add(course.id);
      } else {
        _enrolledSections.remove(course.id);
      }
      _applyFilters();
    });

    try {
      await _courseRepo.toggleEnrolled(
        course.id,
        enroll,
        semesterCode: _selectedSemester,
        courseName: course.courseName,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            if (_semesters.isNotEmpty) _buildSemesterDropdown(),
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
        ),
      ),
    );
  }

  Widget _buildHeader() {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
           GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 15),
          const Text('Course Browser', 
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
  
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

  Widget _buildSemesterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(15),
        ),
        child: DropdownButton<String>(
          value: _selectedSemester,
          items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (value) {
            if (value != null && value != _selectedSemester) {
              setState(() => _selectedSemester = value);
              _loadCourses();
            }
          },
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: const Color(0xFF203A43),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    final courseCodes = _filteredCourses.keys.toList()..sort();
    if (courseCodes.isEmpty && !_isLoading) {
      return const Center(child: Text('No courses found for the selected criteria.', style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: courseCodes.length,
      itemBuilder: (context, index) {
        final code = courseCodes[index];
        final sections = _filteredCourses[code]!;
        final courseName = sections.first.courseName;
        final isTaken = _completedCourses.contains(code);
        final isEnrolled = sections.any((s) => _enrolledSections.contains(s.id));

        return _buildCourseCard(code, courseName, sections, isTaken, isEnrolled);
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
        children: sections.map((section) => _buildSectionTile(section)).toList(),
      ),
    );
  }

  Widget _buildSectionTile(Course section) {
    final isCourseTaken = _completedCourses.contains(section.code);
    final isEnrolled = _enrolledSections.contains(section.id);
    final canEnroll = !isCourseTaken && !isEnrolled;

    return ListTile(
      title: Text('Section ${section.section}', style: const TextStyle(color: Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: section.sessions.map((s) => Text('${s.day} ${s.startTime}-${s.endTime} (${s.faculty})', style: const TextStyle(color: Colors.white70))).toList(),
      ),
      trailing: canEnroll
          ? ElevatedButton(
            onPressed: () => _toggleEnrollment(section, true),
            child: const Text('Enroll'),
            )
          : isEnrolled
              ? ElevatedButton(
                onPressed: () => _toggleEnrollment(section, false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Drop'),
                )
              : null,
    );
  }
}
