import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/glass_kit.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';

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
  StreamSubscription? _scheduleSubscription;

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
  List<List<Course>> _filteredHistory = [];
  bool _isGenerating = false;
  String _generationStatus = '';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _facultyFilterController = TextEditingController();
  final Set<String> _excludedDays = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => _filterSchedules(_searchController.text));
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _facultyFilterController.dispose();
    _scheduleSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      final currentCode = await _academicRepo.getCurrentSemesterCode();
      _nextSemesterCode = _calculateNextSemester(currentCode);

      final advisingDate = await _academicRepo.getOnlineAdvisingDate(currentCode);

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
    setState(() {
      _filteredHistory = _generatedHistory;
    });
  }

  void _filterSchedules(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredHistory = _generatedHistory;
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final filtered = _generatedHistory.where((schedule) {
      return schedule.any((course) {
        final courseName = course.courseName.toLowerCase();
        final courseCode = course.code.toLowerCase();
        final faculty = course.faculty?.toLowerCase() ?? '';
        return courseName.contains(lowerCaseQuery) ||
            courseCode.contains(lowerCaseQuery) ||
            faculty.contains(lowerCaseQuery);
      });
    }).toList();

    setState(() {
      _filteredHistory = filtered;
    });
  }

  void _runGenerator() async {
    if (_selectedCodes.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _generationStatus = 'Initializing generation...';
      _generatedHistory.clear();
      _filteredHistory.clear();
    });
    _scheduleSubscription?.cancel();

    try {
      final filters = {
        'exclude_faculty': _facultyFilterController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'exclude_days': _excludedDays.toList(),
      };

      final generationId = await _courseRepo.triggerScheduleGeneration(
          _nextSemesterCode, _selectedCodes.toList(), filters);

      if (generationId == null) {
        throw Exception('Failed to start generation process.');
      }

      setState(() {
        _generationStatus = 'Processing... Waiting for schedules.';
      });

      _scheduleSubscription = _courseRepo.streamGeneratedSchedules(generationId).listen((schedules) {
        setState(() {
          _generatedHistory.clear();
          _generatedHistory.addAll(schedules);
          _filterSchedules(_searchController.text);
          _generationStatus = 'Found ${_generatedHistory.length} combinations.';
        });
      }, onError: (err) {
        setState(() {
          _generationStatus = 'An error occurred while streaming results.';
          _isGenerating = false;
        });
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _isGenerating = false;
        _generationStatus = 'Error: ${e.message}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Generation failed: ${e.message}'),
              backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generationStatus = 'An unexpected error occurred.';
      });
    }
  }

  void _cancelGenerator() {
    if (_scheduleSubscription != null) {
      _scheduleSubscription!.cancel();
      _scheduleSubscription = null;
    }
    setState(() {
      _isGenerating = false;
      _generationStatus = 'Generation cancelled.';
    });
  }

  void _clearGeneratedSchedules() async {
    _cancelGenerator();
    await _courseRepo.clearAllGeneratedSchedules();
    if (!mounted) return;
    setState(() {
      _generatedHistory.clear();
      _filteredHistory.clear();
      _generationStatus = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cleared all schedule history.")));
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
                          child: CircularProgressIndicator(color: Colors.cyanAccent))
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
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              if (_nextSemesterCode.isNotEmpty)
                Text(_nextSemesterCode,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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

    Widget _buildManualTab() {
    final courseCodes = _groupedCourses.keys.toList()..sort();
    return Column(
      children: [
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

  Widget _buildGroupedCourseCard(
      String courseCode, String courseName, List<Course> sections) {
    return Card(
      color: Colors.white.withAlpha(10),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(courseCode,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                Text("Section ${section.section}",
                    style:
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildGeneratorTab() {
    _allCourseCodes.sort();

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _buildCourseSelectionList(),
        ),
        _buildFilterControls(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _buildGeneratorActions(),
        ),
        const Divider(color: Colors.white24, height: 16),
        if (_isGenerating || _generatedHistory.isNotEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSearchResultsHeader(),
            ),

        Expanded(
          flex: 3,
          child: _buildResultsView(),
        ),
      ],
    );
  }
  
  Widget _buildCourseSelectionList() {
    return ListView.builder(
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
    );
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

  Widget _buildFilterControls() {
    return ExpansionTile(
      title: const Text("Filters & Options", style: TextStyle(color: Colors.white)),
      leading: const Icon(Icons.filter_list, color: Colors.white),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _facultyFilterController,
            decoration: InputDecoration(
              labelText: 'Exclude Faculty (comma separated)',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withAlpha(20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8.0,
            children: ['Sat', 'Sun', 'Fri'].map((day) {
              final isSelected = _excludedDays.contains(day);
              return FilterChip(
                label: Text('No $day'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _excludedDays.add(day);
                    } else {
                      _excludedDays.remove(day);
                    }
                  });
                },
                selectedColor: Colors.redAccent.withAlpha(150),
                backgroundColor: Colors.white.withAlpha(30),
              );
            }).toList(),
          ),
        )
      ],
    );
  }
  
  Widget _buildGeneratorActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _isGenerating ? Colors.grey : Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _selectedCodes.isEmpty ? null : _runGenerator,
            child: _isGenerating
                ? const Text("Generating...", style: TextStyle(fontWeight: FontWeight.bold))
                : const Text("Generate", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        if (_isGenerating) ...[
            const SizedBox(width: 10),
            IconButton(
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                onPressed: _cancelGenerator, tooltip: 'Cancel'),
        ]
      ],
    );
  }

  Widget _buildSearchResultsHeader() {
    return Column(
      children: [
         Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(_generationStatus, style: const TextStyle(color: Colors.white70)),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search generated schedules...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withAlpha(20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.redAccent),
              onPressed: _clearGeneratedSchedules,
              tooltip: 'Clear All History',
            )
          ],
        ),
      ],
    );
  }

  Widget _buildResultsView() {
      if (_isGenerating && _filteredHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
      }

      if (_filteredHistory.isEmpty) {
          return const Center(
              child: Text('Generated schedules will appear here.',
                  style: TextStyle(color: Colors.white38)));
      }

      return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredHistory.length,
          itemBuilder: (context, index) {
              return _buildScheduleCard(index, _filteredHistory[index]);
          },
      );
  }

  Widget _buildScheduleCard(int index, List<Course> schedule) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Option ${index + 1} (${schedule.length} Courses)",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white12, height: 16),
          ...schedule.map((course) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        children: [
                          Text(
                            'Sec: ${course.section} - ${course.faculty}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          ...course.sessions.map((s) => Text(
                                "${s.type}: ${s.day} ${s.startTime} - ${s.endTime}",
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              )),
                        ],
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
                  _tabController.animateTo(0);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Schedule applied to Manual Plan")));
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
}
