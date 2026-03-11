import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/ewumate_app_bar.dart';

import '../../core/widgets/glass_kit.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import '../../core/utils/course_utils.dart';
import 'advising_repository.dart';
import '../../core/widgets/animations/loading_shimmer.dart';
import '../../core/widgets/animations/fade_in_slide.dart';
import '../../core/widgets/onboarding_overlay.dart';

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
  StreamSubscription? _configSub;

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

  bool _isManualMode = false;
  Map<String, List<Course>> _allCoursesManual = {}; // All sections for manual choice
  List<Course> _manualDraft = []; // Selected sections in manual mode

  List<dynamic>? _lastValidSavedData;
  bool _isDeleting = false;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController
        .addListener(() => _filterSchedules(_searchController.text));
    _setupConfigStream();
    _showTutorial();
  }

  void _showTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingOverlay.show(
        context: context,
        featureKey: 'advising_planner_main',
        steps: [
          const OnboardingStep(
            title: "Plan Your Semester",
            description: "Advising can be stressful. Use this tool to plan your next semester's courses without the headache of manual time matching.",
            icon: Icons.auto_awesome_motion_rounded,
          ),
          const OnboardingStep(
            title: "Automated Generator",
            description: "Select the courses you want to take, and our engine will find every possible conflict-free combination for you.",
            icon: Icons.bolt_rounded,
          ),
          const OnboardingStep(
            title: "Manual Mode",
            description: "Prefer hand-picking? Use Manual Mode to select specific sections and build your perfect schedule yourself.",
            icon: Icons.touch_app_rounded,
          ),
          const OnboardingStep(
            title: "7-Day Governance",
            description: "To ensure accuracy, the planner opens 7 days before the official advising session starts. Stay ahead of the curve!",
            icon: Icons.timer_rounded,
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _facultyFilterController.dispose();
    _scheduleSubscription?.cancel();
    _savedSchedulesSubscription?.cancel();
    _configSub?.cancel();
    super.dispose();
  }

  void _setupConfigStream() {
    _configSub?.cancel();
    _configSub = _academicRepo.streamActiveSemesterConfig().listen((config) async {
      final currentCode = config['current_semester_code'] ?? 'Spring2026';
      
      if (mounted) {
        setState(() {
          _nextSemesterCode = _calculateNextSemester(currentCode);
        });
      }

      final advisingDateStr = config['online_advising_date'] ?? 
          await _academicRepo.getOnlineAdvisingDate(currentCode).then((d) => d?.toIso8601String());
      
      if (advisingDateStr != null) {
        final advisingDate = DateTime.parse(advisingDateStr);
        final plannerOpenDate = advisingDate.subtract(const Duration(days: 7));
        final now = DateTime.now();

        bool locked = now.isBefore(plannerOpenDate);
        String msg = "Planner opens on ${DateFormat('MMM d').format(plannerOpenDate)}.\nAdvising starts on ${DateFormat('MMM d').format(advisingDate)}.";

        if (mounted) {
          setState(() {
            _isLocked = locked;
            _lockMessage = msg;
            if (!locked && _allCourseCodes.isEmpty) {
              _loadInitialData();
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLocked = true;
            _lockMessage = "Advising details are pending. Please check back later.";
          });
        }
      }
      
      if (mounted) setState(() => _loading = false);
    });
  }

  String _calculateNextSemester(String current) {
    final match = RegExp(r'([a-zA-Z]+)\s*(\d{4})').firstMatch(current);
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
 
    // Load all courses for manual mode (Upcoming Semester)
    try {
      final raw = await _courseRepo.fetchCourses(_nextSemesterCode, allowMetadataFallback: false);
      _allCoursesManual = {};
      raw.forEach((code, sections) {
        final available =
            sections.where((s) => CourseUtils.isAvailable(s.capacity)).toList();
        if (available.isNotEmpty) {
          _allCoursesManual[code] = available;
        }
      });
      
      // Sync automated codes with available sections
      _allCourseCodes = _allCoursesManual.keys.toList();
      _filteredCourseCodes = List.from(_allCourseCodes)..sort();
    } catch (e) {
      debugPrint("Error loading manual courses: $e");
    }
 
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
    _setupScheduleListener();

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
    HapticFeedback.mediumImpact();

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
        setState(() {
          _isGenerating = false;
          _generationStatus = 'Generation pending backend implementation.';
        });
        return;
      }

      setState(() {
        _generationStatus = 'Processing... Waiting for results.';
      });
      _setupScheduleListener(generationId: generationId);
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generationStatus = 'Error occurred: $e';
      });
    }
  }

  void _setupScheduleListener({String? generationId}) {
    _scheduleSubscription?.cancel();
    final stream = generationId != null
        ? _courseRepo.streamGeneratedSchedules(generationId)
        : _courseRepo.streamLatestGeneratedSchedules();

    _scheduleSubscription = stream.listen((result) {
      if (mounted) {
        setState(() {
          final schedules = result.combinations;
          _generatedHistory = schedules;
          if (_searchController.text.isEmpty) {
            _filteredHistory = List.from(schedules);
          } else {
            _filterSchedules(_searchController.text);
          }

          if (_isGenerating) {
            if (result.status == 'completed') {
              _isGenerating = false;
              _generationStatus = schedules.isNotEmpty
                  ? "Found ${schedules.length} combinations."
                  : "No valid combinations found with these filters.";
            } else if (result.status == 'failed') {
              _isGenerating = false;
              _generationStatus =
                  "Generation failed. Please try different courses or filters.";
            }
          } else if (schedules.isNotEmpty) {
            _generationStatus =
                "Latest saved schedule (${schedules.length} options)";
          }
        });
      }
    });
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
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(
            5,
            (index) => const LoadingShimmer(
              width: double.infinity,
              height: 80,
              margin: EdgeInsets.only(bottom: 16),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        EWUmateAppBar(
          title: "Advising Planner",
          showBack: true,
        ),
        Expanded(
            child: _isLocked ? _buildLockedView() : _buildPlannerView()),
      ],
    );
  }

  // Removed manual _buildHeader as it's replaced by EWUmateAppBar

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
    return StreamBuilder<List<dynamic>>(
      stream: _advisingRepo.getFavoriteSchedulesStream(_nextSemesterCode),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _lastValidSavedData = snapshot.data;
        }

        if (_lastValidSavedData == null) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => LoadingShimmer.card(margin: const EdgeInsets.only(bottom: 16)),
          );
        }

        final items = _lastValidSavedData!;

        if (items.isEmpty) {
          return const Center(
            child: Text(
              "No saved schedules yet.\nBookmark options from the Generator tab.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        return Column(
          children: [
            if (snapshot.hasError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: Colors.redAccent.withValues(alpha: 0.1),
                child: const Text("Offline - Showing cached data", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 10)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${items.length} Saved Combinations",
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text("Clear All", style: TextStyle(fontSize: 12)),
                    onPressed: _showClearAllConfirmation,
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withAlpha(200)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final data = items[index];
                  final sectionIds = List<String>.from(data['sectionIds'] ?? []);
                  final id = data['id'];
                  final dateStr = data['createdAt'] ?? '';

                  return FutureBuilder<List<Course>>(
                    future: _advisingRepo.validateSchedule(_nextSemesterCode, sectionIds),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LoadingShimmer(
                          width: double.infinity,
                          height: 120,
                          margin: EdgeInsets.only(bottom: 16),
                        );
                      }

                      final courses = snapshot.data!;
                      if (courses.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final hasFull = courses.any((c) => !CourseUtils.isAvailable(c.capacity));
                      return _buildSavedScheduleCard(id, dateStr, courses, hasFull: hasFull);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Saved?"),
        content: const Text("This will remove all bookmarked combinations for this semester. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: _isDeleting ? null : () async {
              HapticFeedback.mediumImpact();
              setState(() => _isDeleting = true);
              await _advisingRepo.clearAllFavoriteSchedules(_nextSemesterCode);
              if (mounted) {
                setState(() => _isDeleting = false);
                Navigator.pop(ctx);
                _showSnack("All saved schedules cleared.");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: _isDeleting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Saved Plan?"),
        content: const Text("Are you sure you want to delete this bookmark?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: _isDeleting ? null : () async {
              HapticFeedback.selectionClick();
              setState(() {
                _isDeleting = true;
                // Optimistic: remove from last valid data to hide immediately
                _lastValidSavedData?.removeWhere((item) => item['id'] == docId);
              });
              await _advisingRepo.deleteFavoriteSchedule(docId);
              if (mounted) {
                setState(() => _isDeleting = false);
                Navigator.pop(ctx);
                _showSnack("Deleted.");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: _isDeleting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedScheduleCard(
      String docId, String dateStr, List<Course> schedule, {bool hasFull = false}) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Saved Plan • $dateStr",
                      style: const TextStyle(
                          color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  if (hasFull)
                    const Text("Contains FULL or CLOSED sections",
                        style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(docId),
                tooltip: "Remove Bookmark",
              )
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          ...schedule.map((course) {
            final available = CourseUtils.isAvailable(course.capacity);
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 70,
                        child: Text(course.code,
                            style: TextStyle(
                                color: available ? Colors.cyanAccent : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sec ${course.section} • ${course.faculty}${course.capacity != null ? " • Cap: ${course.capacity}" : ""}${!available ? " (FULL)" : ""}',
                            style: TextStyle(
                                color: available ? Colors.white : Colors.redAccent.withAlpha(200),
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
              );
          }),
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

    final bool showSelector = !_isGenerating && _generatedHistory.isEmpty;

    return Column(
      children: [
        if (showSelector) ...[
          // Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _modeButton("Manual", _isManualMode, () {
                    setState(() {
                      _isManualMode = true;
                      _generatorSearchQuery = '';
                    });
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _modeButton("Automated", !_isManualMode, () {
                    setState(() {
                      _isManualMode = false;
                      _generatorSearchQuery = '';
                    });
                  }),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (val) {
                setState(() => _generatorSearchQuery = val);
              },
              decoration: InputDecoration(
                hintText: _isManualMode
                    ? 'Search Current Sections...'
                    : 'Search Course Metadata...',
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
            child:
                _isManualMode ? _buildManualSelector() : _buildAutomatedSelector(),
          ),

          if (!_isManualMode) _buildFilterControls(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _isManualMode
                ? _buildManualDraftActions()
                : _buildGeneratorActions(),
          ),
        ],

        const Divider(color: Colors.white24, height: 16),
        if (_isGenerating || _generatedHistory.isNotEmpty || (_isManualMode && _manualDraft.isNotEmpty))
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
 
  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: active ? Colors.cyanAccent.withAlpha(40) : Colors.white.withAlpha(10),
        borderRadius: 8,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.cyanAccent : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildAutomatedSelector() {
    var displayList = _filteredCourseCodes;
    if (_generatorSearchQuery.isNotEmpty) {
      displayList = _filteredCourseCodes
          .where((c) =>
              CourseUtils.normalizeCode(c).contains(CourseUtils.normalizeCode(_generatorSearchQuery)))
          .toList();
    }
    displayList.sort();
 
    return ListView.builder(
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
    );
  }
 
  Widget _buildManualSelector() {
    var codes = _allCoursesManual.keys.toList();
    if (_generatorSearchQuery.isNotEmpty) {
      codes = codes.where((c) => CourseUtils.normalizeCode(c).contains(CourseUtils.normalizeCode(_generatorSearchQuery))).toList();
    }
    codes.sort();
 
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: codes.length,
      itemBuilder: (context, index) {
        final code = codes[index];
        final sections = _allCoursesManual[code]!;
        
        final isPicked = _manualDraft.any((c) => CourseUtils.normalizeCode(c.code) == CourseUtils.normalizeCode(code));
 
        return ExpansionTile(
          title: Text(code, style: TextStyle(color: isPicked ? Colors.cyanAccent : Colors.white)),
          leading: Icon(Icons.school, color: isPicked ? Colors.cyanAccent : Colors.white54),
          children: sections.map((s) {
             final isThisSectionPicked = _manualDraft.any((c) => c.id == s.id);
             return ListTile(
               title: Text("Section ${s.section} - ${s.faculty}", style: const TextStyle(color: Colors.white, fontSize: 13)),
               subtitle: Text(s.sessions.map((sess) => "${sess.day} ${sess.startTime}").join(", "), style: const TextStyle(color: Colors.white54, fontSize: 11)),
               trailing: isThisSectionPicked 
                 ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                 : TextButton(
                    onPressed: () => _addSectionToManual(s),
                    child: const Text("Pick"),
                   ),
             );
          }).toList(),
        );
      },
    );
  }
 
  Widget _buildManualDraftActions() {
    return Column(
      children: [
        if (_manualDraft.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "${_manualDraft.length} courses drafted",
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_manualDraft.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withAlpha(50),
                foregroundColor: Colors.redAccent,
              ),
              onPressed: () => setState(() => _manualDraft.clear()),
              child: const Text("Clear Draft"),
            ),
          )
      ],
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
 
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
 
  void _addSectionToManual(Course section) {
    // 1. Check if course already in draft (normalized)
    final normNew = CourseUtils.normalizeCode(section.code);
    final existingIndex = _manualDraft.indexWhere(
        (c) => CourseUtils.normalizeCode(c.code) == normNew);
 
    if (existingIndex != -1) {
      _showSnack("Already have a section for ${section.code}");
      return;
    }
 
    // 2. Removed 5 course limit
 
    // 3. Time Clash Check
    for (final existing in _manualDraft) {
      for (final s1 in section.sessions) {
        for (final s2 in existing.sessions) {
          if (s1.day == s2.day &&
              _timesOverlap(s1.startTime, s1.endTime, s2.startTime, s2.endTime)) {
            _showSnack("Time Clash with ${existing.code} on ${s1.day}!");
            return;
          }
        }
      }
    }
 
    setState(() {
      _manualDraft.add(section);
    });
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
    final canGenerate = _selectedCodes.isNotEmpty;

    return Column(
      children: [
        if (_selectedCodes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "${_selectedCodes.length} courses selected",
              style: const TextStyle(
                color: Colors.cyanAccent,
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
 
    final List<List<Course>> allCombos = [];
    
    // Add manual draft if it has 3-5 courses
    if (_manualDraft.isNotEmpty) {
      allCombos.add(_manualDraft);
    }
 
    // Add generated ones, but filter for availability
    final availableHistory = _filteredHistory.where((schedule) {
      return schedule.every((s) => CourseUtils.isAvailable(s.capacity));
    }).toList();
 
    allCombos.addAll(availableHistory);
 
    if (allCombos.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Combinations will appear here.',
              style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 10),
          const Text('(Select courses/sections)',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
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
      itemCount: allCombos.length,
      itemBuilder: (context, index) {
        final combo = allCombos[index];
        final isManual = combo == _manualDraft;
        String cardLabel;
        if (isManual) {
          cardLabel = "My Manual Draft";
        } else {
          final offset = allCombos.contains(_manualDraft) ? 0 : 1;
          cardLabel = "Option ${index + offset}";
        }

        return _buildScheduleCard(
          index, 
          combo, 
          label: cardLabel,
        );
      },
    );
  }
 
  Widget _buildScheduleCard(int index, List<Course> schedule, {String? label}) {
    // Check if this option is already saved (by comparing section IDs)
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
              Text(label ?? "Option ${index + 1} (${schedule.length} Courses)",
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
                            'Sec ${course.section} • ${course.faculty}${course.capacity != null ? " • Cap: ${course.capacity}" : ""}',
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
