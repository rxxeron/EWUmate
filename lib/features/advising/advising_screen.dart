import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/glass_kit.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import 'advising_repository.dart';

class AdvisingScreen extends StatefulWidget {
  const AdvisingScreen({super.key});

  @override
  State<AdvisingScreen> createState() => _AdvisingScreenState();
}

class _AdvisingScreenState extends State<AdvisingScreen>
    with SingleTickerProviderStateMixin {
  final AcademicRepository _academicRepo = AcademicRepository();
  final CourseRepository _courseRepo = CourseRepository();
  final AdvisingRepository _advisingRepo = AdvisingRepository();

  late TabController _tabController;
  StreamSubscription? _scheduleSubscription;
  StreamSubscription? _savedSchedulesSubscription;

  bool _loading = true;
  bool _isLocked = true;
  String _lockMessage = '';

  String _nextSemesterCode = '';

  // Data
  List<String> _allCourseCodes = [];
  List<String> _filteredCourseCodes = [];
  // Generator State
  final Set<String> _selectedCodes = {};
  List<List<Course>> _generatedHistory = [];
  List<List<Course>> _filteredHistory = [];
  bool _isGenerating = false;
  String _generationStatus = '';

  // Saved Schedules State
  List<Map<String, dynamic>> _savedSchedules = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _facultyFilterController =
      TextEditingController();
  final Set<String> _excludedDays = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController
        .addListener(() => _filterSchedules(_searchController.text));
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _facultyFilterController.dispose();
    _scheduleSubscription?.cancel();
    _savedSchedulesSubscription?.cancel();
    super.dispose();
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
          content:
              Text("Error initializing advising data. Please try again later."),
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
    _filteredCourseCodes = List.from(_allCourseCodes)..sort();

    // Listen to Saved Schedules
    _savedSchedulesSubscription?.cancel();
    _savedSchedulesSubscription = _advisingRepo
        .getFavoriteSchedulesStream(_nextSemesterCode)
        .listen((data) {
      if (mounted) {
        setState(() {
          _savedSchedules = data;
        });
      }
    });

    // Persistent Generated History
    _scheduleSubscription?.cancel();
    _scheduleSubscription =
        _courseRepo.streamLatestGeneratedSchedules().listen((schedules) {
      if (mounted) {
        setState(() {
          // Keep existing unless new data is empty or different?
          // streamLatestGeneratedSchedules returns the latest doc.
          // We overwrite local state with what's in cloud.
          _generatedHistory = schedules;
          if (_searchController.text.isEmpty) {
            _filteredHistory = List.from(schedules);
          } else {
            _filterSchedules(_searchController.text);
          }
          if (_isGenerating && schedules.isNotEmpty) {
            _isGenerating = false;
            _generationStatus = "Found ${schedules.length} combinations.";
          } else if (!_isGenerating && schedules.isNotEmpty) {
            _generationStatus =
                "Latest saved schedule (${schedules.length} options)";
          }
        });
      }
    });

    setState(() {});
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
        // For testing/mocking when backend is missing
        setState(() {
          _isGenerating = false;
          _generationStatus = 'Generation pending backend implementation.';
        });
        return;
      }

      setState(() {
        _generationStatus = 'Processing... Waiting for results.';
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generationStatus = 'Error occurred: $e';
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

  void _savePlanOption(List<Course> schedule) async {
    try {
      final ids = schedule.map((e) => e.id).toList();
      await _advisingRepo.saveManualPlan(_nextSemesterCode, ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Enrollment choice saved! Please finalize it in the Next Semester screen.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
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
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Generator"),
            Tab(text: "Saved"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneratorTab(),
              _buildSavedTab(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSavedTab() {
    if (_savedSchedules.isEmpty) {
      return const Center(
        child: Text(
          "No saved schedules yet.\nBookmark options from the Generator tab.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedSchedules.length,
      itemBuilder: (context, index) {
        final data = _savedSchedules[index];
        final sectionIds = List<String>.from(data['sectionIds'] ?? []);
        final id = data['id'];
        final dateStr = data['createdAt'] ?? '';

        // We need to fetch/resolve the Course objects for display
        // Since we don't have them in the 'data' map immediately, we can use a FutureBuilder
        // calling repository validateSchedule.

        return FutureBuilder<List<Course>>(
          future: _advisingRepo.validateSchedule(_nextSemesterCode, sectionIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)));
            }

            final courses = snapshot.data!;
            if (courses.isEmpty) {
              return const SizedBox.shrink(); // Invalid saved item
            }

            return _buildSavedScheduleCard(id, dateStr, courses);
          },
        );
      },
    );
  }

  Widget _buildSavedScheduleCard(
      String docId, String dateStr, List<Course> schedule) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Saved Plan • $dateStr",
                  style: const TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white38),
                onPressed: () => _advisingRepo.deleteFavoriteSchedule(docId),
              )
            ],
          ),
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
                            'Sec ${course.section} • ${course.faculty}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          ...course.sessions.map((s) => Text(
                                "${s.type}: ${s.day} ${s.startTime} - ${s.endTime}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
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
            child: ElevatedButton(
              onPressed: () => _savePlanOption(schedule),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black),
              child: const Text("Enroll in this Saved Plan",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  String _generatorSearchQuery = '';

  Widget _buildGeneratorTab() {
    // Filter logic for the list
    var displayList = _filteredCourseCodes;
    if (_generatorSearchQuery.isNotEmpty) {
      displayList = _filteredCourseCodes
          .where((c) =>
              c.toLowerCase().contains(_generatorSearchQuery.toLowerCase()))
          .toList();
    }
    displayList.sort(); // Keep sorted

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            onChanged: (val) {
              setState(() => _generatorSearchQuery = val);
            },
            decoration: InputDecoration(
              hintText: 'Search Course (e.g. CSE101)',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withAlpha(20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),

        // Selection List
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final code = displayList[index];
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

  void _toggleGeneratorCode(String code) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
      } else {
        if (_selectedCodes.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Maximum 5 courses allowed.")),
          );
          return;
        }
        _selectedCodes.add(code);
      }
    });
  }

  Widget _buildFilterControls() {
    return ExpansionTile(
      title: const Text("Filters & Options",
          style: TextStyle(color: Colors.white)),
      leading: const Icon(Icons.filter_list, color: Colors.white),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _facultyFilterController,
            decoration: InputDecoration(
              labelText: 'Exclude Faculty (comma separated)',
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
              filled: true,
              fillColor: Colors.white.withAlpha(20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8.0,
            children:
                ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
              final isSelected = _excludedDays.contains(day);
              return FilterChip(
                label: Text(day, style: const TextStyle(fontSize: 12)),
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
    final canGenerate =
        _selectedCodes.length >= 3 && _selectedCodes.length <= 5;

    return Column(
      children: [
        if (_selectedCodes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "${_selectedCodes.length} courses selected (Need 3-5)",
              style: TextStyle(
                color: canGenerate ? Colors.cyanAccent : Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: (_isGenerating || !canGenerate)
                        ? Colors.grey
                        : Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed:
                    (!canGenerate || _isGenerating) ? null : _runGenerator,
                child: _isGenerating
                    ? const Text("Generating...",
                        style: TextStyle(fontWeight: FontWeight.bold))
                    : const Text("Generate Combinations",
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (_isGenerating) ...[
              const SizedBox(width: 10),
              IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: _cancelGenerator,
                  tooltip: 'Cancel'),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildSearchResultsHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(_generationStatus,
              style: const TextStyle(color: Colors.white70)),
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
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
      return const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent));
    }

    if (_filteredHistory.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Generated schedules will appear here.',
              style: TextStyle(color: Colors.white38)),
          if (_generatedHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filteredHistory = _generatedHistory;
                });
              },
              child: const Text("Show History"),
            )
          ]
        ],
      ));
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
    // Check if this option is already saved (by comparing section IDs)
    // Naive check: if any saved schedule has same set of IDs
    final currentIds = schedule.map((e) => e.id).toSet();
    final isSaved = _savedSchedules.any((saved) {
      final savedIds = List<String>.from(saved['sectionIds'] ?? []).toSet();
      return savedIds.length == currentIds.length &&
          savedIds.containsAll(currentIds);
    });

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
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.cyanAccent : Colors.white54),
                onPressed: () {
                  if (isSaved) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Already saved in Saved tab!")));
                  } else {
                    _advisingRepo.saveFavoriteSchedule(
                        _nextSemesterCode, schedule.map((e) => e.id).toList());
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Saved to favorites!")));
                  }
                },
              )
            ],
          ),
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
                            'Sec ${course.section} • ${course.faculty} • Cap: ${course.capacity}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          ...course.sessions.map((s) => Text(
                                "${s.type}: ${s.day} ${s.startTime} - ${s.endTime}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
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
            child: ElevatedButton(
              onPressed: () => _savePlanOption(schedule),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black),
              child: const Text("Enroll in this Option",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
