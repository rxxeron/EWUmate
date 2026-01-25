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
  List<String> _allCourseCodes = [];
  Map<String, List<Course>> _groupedCourses = {};

  // Manual Plan State
  final List<Course> _selectedSections = [];

  // Generator State
  final Set<String> _selectedCodes = {};
  final List<List<Course>> _generatedHistory = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    try {
      final currentCode = await _academicRepo.getCurrentSemesterCode();
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
        _isLocked = false;
      }

      if (!_isLocked) {
        await _loadInitialData();
      }
    } catch (e) {
      debugPrint("Advising Init Error: $e");
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error initializing advising data. Please try again later."),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _loadInitialData() async {
    _allCourseCodes = await _courseRepo.fetchAllCourseCodes();
    _groupedCourses = await _courseRepo.fetchCourses(_nextSemesterCode);
    final loadedSchedules = await _courseRepo.loadGeneratedSchedules(_nextSemesterCode);
    if(mounted) {
      setState(() {
        _generatedHistory.addAll(loadedSchedules);
      });
    }
  }

  // --- Logic: Overlap Check ---
  bool _hasOverlap(Course newCourse) {
    for (final existing in _selectedSections) {
      if (existing.code == newCourse.code) return true;
      for (final newSession in newCourse.sessions) {
        for (final existingSession in existing.sessions) {
          if (_checkTimeOverlap(newSession, existingSession)) return true;
        }
      }
    }
    return false;
  }

  bool _checkTimeOverlap(CourseSession a, CourseSession b) {
    if (a.day == b.day) {
       final startA = _parseTime(a.startTime);
      final endA = _parseTime(a.endTime);
      final startB = _parseTime(b.startTime);
      final endB = _parseTime(b.endTime);

      if (startA != null && endA != null && startB != null && endB != null) {
        return startA < endB && startB < endA;
      }
    }
    return false;
  }

  int? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final format = DateFormat("hh:mm a");
      return format.parse(timeStr.trim().toUpperCase()).millisecondsSinceEpoch;
    } catch (e) {
      debugPrint("Error parsing time: $timeStr, Error: $e");
      return null;
    }
  }

  void _toggleSection(Course course) {
    final isSelected = _selectedSections.any((c) => c.id == course.id);

    if (isSelected) {
      setState(() =>
          _selectedSections.removeWhere((c) => c.id == course.id));
    } else {
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
       backgroundColor: const Color(0xFF0F2027),
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
    final courseCodes = _groupedCourses.keys.toList()..sort();
    return Column(
      children: [
        // Selected Summary
        if (_selectedSections.isNotEmpty)
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _selectedSections
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text("${c.code} - ${c.section}"),
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
            itemCount: courseCodes.length,
            itemBuilder: (context, index) {
              final courseCode = courseCodes[index];
              final sections = _groupedCourses[courseCode]!;
              final courseName = sections.first.courseName;

              return _buildGroupedCourseCard(courseCode, courseName, sections);
            },
          ),
        ),
      ],
    );
  }

  // --- Generator Tab ---
  Widget _buildGeneratorTab() {
    _allCourseCodes.sort();

    return Column(
      children: [
        // Course Selection
        Expanded(
          flex: 2, // Gives more space to the course list
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _allCourseCodes.length,
            itemBuilder: (context, index) {
              final code = _allCourseCodes[index];
              final isSelected = _selectedCodes.contains(code);
              return CheckboxListTile(
                title: Text(code, style: const TextStyle(color: Colors.white)),
                value: isSelected,
                onChanged: (val) => _toggleGeneratorCode(code),
                activeColor: Colors.cyanAccent,
                checkColor: Colors.black,
                side: const BorderSide(color: Colors.white38),
                 controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
        
        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : const Text("Generate",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              if (_generatedHistory.isNotEmpty) IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                onPressed: _clearGeneratedSchedules,
                tooltip: 'Clear Generated Schedules',
              )
            ],
          ),
        ),
        
        const Divider(color: Colors.white24, height: 32),

        // Generated Schedules View
        Expanded(
          flex: 3, // Gives more space to the results
          child: _generatedHistory.isEmpty 
              ? const Center(
                  child: Text('Generated schedules will appear here.',
                      style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _generatedHistory.length,
                  itemBuilder: (context, index) {
                    return _buildScheduleCard(index, _generatedHistory[index]);
                  },
                ),
        ),
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
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          ...schedule.map((course) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 70,
                        child: Text(course.code,
                            style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: course.sessions.map((s) => Text(
                          "${s.type}: ${s.day} ${s.startTime} - ${s.endTime}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedSections.clear();
                  _selectedSections.addAll(schedule);
                  _tabController.animateTo(0); // Switch to Manual View
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Schedule applied to Manual Plan")));
              },
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.cyanAccent)),
              child: const Text("Use This Schedule",
                  style: TextStyle(color: Colors.cyanAccent)),
            ),
          )
        ],
      ),
    );
  }


  Widget _buildGroupedCourseCard(
      String courseCode, String courseName, List<Course> sections) {
    return Card(
      color: Colors.white.withAlpha(10),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(courseCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(courseName, style: const TextStyle(color: Colors.white70)),
        children: sections.map((section) => _buildCourseSection(section)).toList(),
      ),
    );
  }

  Widget _buildCourseSection(Course section) {
    final isSelected = _selectedSections.any((c) => c.id == section.id);
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       decoration: BoxDecoration(
         color: isSelected ? Colors.cyanAccent.withAlpha(20) : Colors.transparent,
       ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Section ${section.section}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...section.sessions.map((sessionInfo) {
                  return Text(
                    "${sessionInfo.type}: ${sessionInfo.day} ${sessionInfo.startTime} - ${sessionInfo.endTime} (${sessionInfo.faculty})",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  );
                }),
              ],
            ),
          ),
          Switch(
            value: isSelected,
            onChanged: (_) => _toggleSection(section),
            activeTrackColor: Colors.cyanAccent.withAlpha(100),
            inactiveTrackColor: Colors.white10,
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.cyanAccent;
                }
                return Colors.white60;
            }),
          ),
        ],
      ),
    );
  }

  // --- Generator Logic ---
  void _runGenerator() async {
    setState(() => _isGenerating = true);
    final List<List<Course>> results = [];

    try {
      final candidates = await _courseRepo.fetchCoursesByCode(
          _nextSemesterCode, _selectedCodes.toList());

      void solve(int courseIndex, List<Course> currentSchedule) {
        if (results.length >= 5) return; // Limit to 5 results for performance

        if (courseIndex == _selectedCodes.length) {
          results.add(List.from(currentSchedule));
          return;
        }

        final code = _selectedCodes.elementAt(courseIndex);
        final sectionsForCourse = candidates[code] ?? [];

        for (final section in sectionsForCourse) {
          bool hasConflict = currentSchedule.any((scheduled) => _checkSectionOverlap(scheduled, section));
          
          if (!hasConflict) {
            currentSchedule.add(section);
            solve(courseIndex + 1, currentSchedule);
            currentSchedule.removeLast();
          }
        }
      }

      solve(0, []);

      _generatedHistory.clear();
      _generatedHistory.addAll(results);
      await _courseRepo.saveGeneratedSchedules(_nextSemesterCode, _generatedHistory);
      
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(results.isEmpty ? "No conflict-free schedules found." : "Generated ${results.length} schedules.")));
      }

    } catch (e) {
      debugPrint("Error running generator: $e");
       if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("An error occurred while generating schedules."), backgroundColor: Colors.redAccent,));
       }
    } finally {
       if(mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
  
  void _clearGeneratedSchedules() async {
    await _courseRepo.clearGeneratedSchedules(_nextSemesterCode);
    if (!mounted) return; // Guard against async gaps
    setState(() {
      _generatedHistory.clear();
    });
     ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cleared generated schedules.")));
  }

  bool _checkSectionOverlap(Course a, Course b) {
    for (final sessionA in a.sessions) {
      for (final sessionB in b.sessions) {
        if (_checkTimeOverlap(sessionA, sessionB)) {
          return true;
        }
      }
    }
    return false;
  }
}
