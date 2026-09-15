import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/utils/course_utils.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/refresh_utils.dart';
import 'widgets/course_history/course_history_header_card.dart';
import 'widgets/course_history/course_history_course_list.dart';
import 'widgets/course_history/course_history_grade_dialog.dart';
import 'widgets/course_history/course_history_sync_overlay.dart';
import 'widgets/course_history/course_history_bottom_bar.dart';

class CourseHistoryScreen extends ConsumerStatefulWidget {
  final bool isEditMode;
  final String? admittedSemester;
  const CourseHistoryScreen({
    super.key, 
    this.isEditMode = false,
    this.admittedSemester,
  });

  @override
  ConsumerState<CourseHistoryScreen> createState() =>
      _CourseHistoryScreenState();
}

class _CourseHistoryScreenState extends ConsumerState<CourseHistoryScreen> {
  // State
  bool _profileLoading = true;
  bool _loading = false;
  bool _isSyncing = false;
  Timer? _debounce;
  bool _isCurrentSemester = false;

  // Data
  List<Map<String, dynamic>> _catalog = [];
  final Map<String, Map<String, String>> _history = {};
  final Map<String, List<String>> _selectedSectionIds = {};
  final Map<String, Map<String, dynamic>> _selectedCoursesMetadata = {};
  List<String> _allSemesters = [];
  String _runningSemester = "";

  // Current State
  String? _admittedSemester;
  String? _currentSemester;
  int _currentIndex = -1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.admittedSemester != null) {
      _currentSemester = widget.admittedSemester;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    if (_currentSemester == null) return;
    setState(() => _loading = true);
    try {
      final catalog = await ref
          .read(onboardingRepositoryProvider)
          .fetchCourseCatalog(
            semester: _currentSemester,
            isCurrent: _isCurrentSemester,
            searchQuery: _searchQuery,
          );
      if (mounted) {
        setState(() {
          _catalog = catalog;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    }
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = val;
      _loadCatalog();
    });
  }

  void _confirmAdmittedSemester(String semester) {
    setState(() {
      _currentSemester = semester;
      _currentIndex = _allSemesters.indexOf(semester);

      String clean(String s) =>
          s.replaceAll(' ', '').replaceAll('_', '').toLowerCase();
      _isCurrentSemester = (clean(semester) == clean(_runningSemester));
      _catalog = [];
    });
    _loadCatalog();
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
        final cleanRunning = _runningSemester.trim().toLowerCase();
        final cleanNext = nextSem.trim().toLowerCase();
        _isCurrentSemester = (cleanNext == cleanRunning);
        _catalog = [];
      });
      await _loadCatalog();
    } else {
      _finishOnboarding();
    }
  }

  List<Map<String, dynamic>> _collectEnrolledDetails() {
    final currentSemMap = _history[_runningSemester] ?? {};
    final details = <Map<String, dynamic>>[];

    for (final selection in currentSemMap.keys) {
      final meta = _selectedCoursesMetadata[selection];

      if (meta != null) {
        details.add({
          'id': meta['id'],
          'code': (meta['code'] ?? meta['course_code'] ?? selection).toString(),
          'name': (meta['name'] ?? meta['course_name'] ?? selection).toString(),
          'section': (meta['section'] ?? meta['section_number'] ?? '').toString(),
          'time': (meta['time'] ?? meta['schedule_data'] ?? '').toString(),
        });
      } else {
        final code = selection.contains('_Sec')
            ? selection.split('_Sec').first
            : selection;
        details.add({'code': code, 'name': code, 'section': '', 'time': ''});
      }
    }
    return details;
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSyncing = true);
    try {
      final currentSemMap = _history[_runningSemester] ?? {};
      final List<String> enrolledIds = [];

      for (final selection in currentSemMap.keys) {
        if (_selectedSectionIds.containsKey(selection)) {
          enrolledIds.addAll(_selectedSectionIds[selection]!);
          continue;
        }
        final match =
            _catalog.where((c) {
              final key = _isCurrentSemester
                  ? "${c['code']}_Sec${c['section']}"
                  : c['code'].toString();
              return key == selection;
            }).firstOrNull ??
            {};

        if (match.containsKey('allIds')) {
          enrolledIds.addAll(List<String>.from(match['allIds']));
        } else if (match.containsKey('id')) {
          enrolledIds.add(match['id']);
        }
      }

      await ref
          .read(onboardingRepositoryProvider)
          .saveCourseHistory(
            _history,
            enrolledIds,
            _runningSemester,
            enrolledCourseDetails: _collectEnrolledDetails(),
          );

      if (!widget.isEditMode) {
        await ref.read(onboardingRepositoryProvider).completeOnboarding();
      }

      if (mounted) {
        if (widget.isEditMode) {
          RefreshUtils.refreshAcademicData(ref);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Degree progress updated!")),
          );
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : AuthErrorUtils.getFriendlyMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _profileLoading = true);
    try {
      final config = await ref
          .read(onboardingRepositoryProvider)
          .getActiveSemesterConfig();
      final semesterType = config['track']?.toString() ?? 'tri_semester';
      final results = await Future.wait<dynamic>([
        ref
            .read(onboardingRepositoryProvider)
            .getAllSemesters(semesterType: semesterType),
        ref.read(onboardingRepositoryProvider).fetchUserProfile(),
        ref.read(onboardingRepositoryProvider).fetchCompletedCourses(),
        ref.read(onboardingRepositoryProvider).fetchActiveEnrollments(),
      ]);

      final allSems = results[0] as List<String>;
      final profileData = results[1] as Map<String, dynamic>;
      final completedCourses = results[2] as List<Map<String, dynamic>>;
      final activeEnrollments = results[3] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _runningSemester = (config['current_semester_code'] ?? "Summer2026")
              .toString();
          _allSemesters = allSems;
          if (!_allSemesters.contains(_runningSemester)) {
            _allSemesters.add(_runningSemester);
          }

          _history.clear();
          _selectedSectionIds.clear();

          for (var row in completedCourses) {
            final semRaw = row['semester_code'] as String;
            final sem = CourseUtils.cleanSemester(semRaw);

            final code = row['course_code'] as String;
            final grade = (row['grade'] ?? "Ongoing").toString();

            if (!_history.containsKey(sem)) _history[sem] = {};
            _history[sem]![code] = grade;
          }

          for (var row in activeEnrollments) {
            final code = row['course_code'] as String;
            final sectionNum = row['section']?.toString() ?? '';
            final sectionId = row['section_id']?.toString() ?? '';
            final semRaw = (row['semester_code'] ?? _runningSemester).toString();
            final sem = CourseUtils.cleanSemester(semRaw);

            if (!_history.containsKey(sem)) _history[sem] = {};

            if (sem.toLowerCase() == _runningSemester.toLowerCase()) {
              final selectionKey = sectionNum.isNotEmpty ? "${code}_Sec$sectionNum" : code;
              _history[sem]![selectionKey] = "Ongoing";
              if (sectionId.isNotEmpty) {
                _selectedSectionIds[selectionKey] = [sectionId];
              }
              _selectedCoursesMetadata[selectionKey] = {
                'id': sectionId,
                'code': code,
                'section': sectionNum,
              };
            } else {
              _history[sem]![code] = "Ongoing";
            }
          }

          if (widget.admittedSemester != null && widget.admittedSemester!.isNotEmpty) {
            _admittedSemester = widget.admittedSemester;
          } else {
            _admittedSemester = (profileData['admitted_semester'] ?? "").toString();
          }

          if (widget.isEditMode && _admittedSemester == _runningSemester) {
            _profileLoading = false;
            Future.delayed(Duration.zero, () {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text("Notice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: const Text("You have no academic history to edit yet!", style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text("OK", style: TextStyle(color: Colors.cyanAccent)),
                      )
                    ],
                  ),
                );
              }
            });
            return;
          }

          final programName =
              (profileData['department_name'] ??
                      profileData['program_code'] ??
                      "")
                  .toString()
                  .toLowerCase();

          final actualAdmission = _admittedSemester ?? '';
          final isFallAdmitted = actualAdmission.toLowerCase().contains('fall');

          if (!widget.isEditMode &&
              programName.contains("pharmacy") &&
              _admittedSemester != null &&
              _admittedSemester!.toLowerCase().startsWith("fall")) {
            final year = _admittedSemester!.replaceAll(RegExp(r'[^0-9]'), '');
            final forcedSummer = "Summer$year";

            if (!_allSemesters.contains(forcedSummer)) {
              final fallIdx = _allSemesters.indexOf(_admittedSemester!);
              if (fallIdx != -1) {
                _allSemesters.insert(fallIdx, forcedSummer);
              } else {
                _allSemesters.add(forcedSummer);
              }
            }
            _admittedSemester = forcedSummer;
          }

          final isForcedSummer = programName.contains("pharmacy") && (_admittedSemester?.toLowerCase().contains('summer') ?? false);

          if (!isForcedSummer && semesterType == 'bi_semester' && (_admittedSemester?.toLowerCase().contains('summer') ?? false)) {
            final yearMatch = RegExp(r'\d{4}').firstMatch(_admittedSemester!);
            final year = yearMatch?.group(0) ?? '2026';
            _admittedSemester = 'Spring$year';
          }

          if (_admittedSemester != null && !_allSemesters.contains(_admittedSemester)) {
            _allSemesters.add(_admittedSemester!);
          }
          if (!_allSemesters.contains(_runningSemester)) {
            _allSemesters.add(_runningSemester);
          }

          _allSemesters.sort((a, b) {
            final reg = RegExp(r'^([a-zA-Z]+)(\d{4})$');
            final matchA = reg.firstMatch(a);
            final matchB = reg.firstMatch(b);
            if (matchA != null && matchB != null) {
              final yearA = int.parse(matchA.group(2)!);
              final yearB = int.parse(matchB.group(2)!);
              if (yearA != yearB) return yearA.compareTo(yearB);
              int getSeasonWeight(String s) {
                final season = s.toLowerCase();
                if (season.contains('spring')) return 1;
                if (season.contains('summer')) return 2;
                if (season.contains('fall')) return 3;
                return 4;
              }
              return getSeasonWeight(matchA.group(1)!).compareTo(getSeasonWeight(matchB.group(1)!));
            }
            return a.compareTo(b);
          });

          String clean(String s) => CourseUtils.cleanSemester(s);

          final admIdx = _allSemesters.indexWhere((s) => clean(s) == clean(_admittedSemester ?? ''));
          final runIdx = _allSemesters.indexWhere((s) => clean(s) == clean(_runningSemester));

          if (runIdx != -1) {
            _runningSemester = _allSemesters[runIdx];
          }

          if (admIdx != -1 && runIdx != -1) {
            final startIndex = admIdx;
            final endIndex = (runIdx > admIdx) ? runIdx : admIdx;
            _allSemesters = _allSemesters.sublist(startIndex, endIndex + 1);
          } else if (runIdx != -1) {
            _allSemesters = _allSemesters.sublist(0, runIdx + 1);
          }

          if (semesterType == 'bi_semester') {
            if (!isFallAdmitted) {
              _allSemesters = _allSemesters.where((s) => !s.toLowerCase().contains('summer')).toList();
            } else {
              bool summerFound = false;
              _allSemesters = _allSemesters.where((s) {
                if (s.toLowerCase().contains('summer')) {
                  if (summerFound) return false;
                  summerFound = true;
                  return true;
                }
                return true;
              }).toList();
            }
          }

          if (widget.isEditMode) {
            if (_allSemesters.isNotEmpty) {
              _confirmAdmittedSemester(_allSemesters.first);
            }
          } else {
            final matchIdx = _allSemesters.indexWhere((s) {
              final cleaned = clean(s);
              return cleaned.isNotEmpty && cleaned == clean(_admittedSemester ?? '');
            });

            if (matchIdx != -1) {
              _confirmAdmittedSemester(_allSemesters[matchIdx]);
            } else if (_allSemesters.isNotEmpty) {
              _confirmAdmittedSemester(_allSemesters.first);
            } else {
              _confirmAdmittedSemester(_runningSemester);
            }
          }
          _profileLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _profileLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      final parts = timeStr.split(' ');
      final hm = parts[0].split(':');
      int h = int.parse(hm[0]);
      int m = int.parse(hm[1]);
      if (parts.length > 1) {
        if (parts[1].toUpperCase() == 'PM' && h < 12) h += 12;
        if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
      }
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  bool _hasTimeConflict(List<dynamic> sched1, List<dynamic> sched2) {
    for (final s1 in sched1) {
      if (s1 is! Map) continue;
      final day1 = s1['day']?.toString() ?? '';
      final start1 = _parseTimeToMinutes(
        s1['startTime']?.toString() ?? s1['start_time']?.toString() ?? '',
      );
      final end1 = _parseTimeToMinutes(
        s1['endTime']?.toString() ?? s1['end_time']?.toString() ?? '',
      );
      if (day1.isEmpty || start1 == 0 || end1 == 0) continue;

      for (final s2 in sched2) {
        if (s2 is! Map) continue;
        final day2 = s2['day']?.toString() ?? '';
        final start2 = _parseTimeToMinutes(
          s2['startTime']?.toString() ?? s2['start_time']?.toString() ?? '',
        );
        final end2 = _parseTimeToMinutes(
          s2['endTime']?.toString() ?? s2['end_time']?.toString() ?? '',
        );
        if (day2.isEmpty || start2 == 0 || end2 == 0) continue;

        bool dayOverlap = false;
        for (int i = 0; i < day1.length; i++) {
          if (day2.contains(day1[i]) && day1[i].trim().isNotEmpty) {
            dayOverlap = true;
            break;
          }
        }

        if (dayOverlap && start1 < end2 && start2 < end1) {
          return true;
        }
      }
    }
    return false;
  }

  String? _getPassedGrade(String courseCode) {
    if (_history.isEmpty) return null;
    final cleanCurrent = CourseUtils.cleanSemester(_currentSemester ?? '');
    for (final sem in _history.keys) {
      if (sem == cleanCurrent) continue;
      final semCourses = _history[sem]!;
      for (final prevKey in semCourses.keys) {
        final baseCode = prevKey.contains('_Sec')
            ? prevKey.split('_Sec').first
            : prevKey;
        if (baseCode == courseCode) {
          final existingGrade = semCourses[prevKey];
          if (existingGrade != 'F' &&
              existingGrade != 'W' &&
              existingGrade != 'I' &&
              existingGrade != 'R') {
            return existingGrade.toString();
          }
        }
      }
    }
    return null;
  }

  void _addCourse(Map<String, dynamic> course) async {
    if (_currentSemester == null) return;
    final code = course['code'] as String;
    final sectionRaw = (course['section'] ?? '').toString();
    final selectionKey = _isCurrentSemester ? "${code}_Sec$sectionRaw" : code;

    for (final sem in _history.keys) {
      if (sem == _currentSemester) continue;
      final semCourses = _history[sem]!;
      for (final prevKey in semCourses.keys) {
        final baseCode = prevKey.contains('_Sec')
            ? prevKey.split('_Sec').first
            : prevKey;
        if (baseCode == code) {
          final existingGrade = semCourses[prevKey];
          if (existingGrade != 'F' &&
              existingGrade != 'W' &&
              existingGrade != 'I' &&
              existingGrade != 'R') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "You already passed $code in $sem with grade: $existingGrade.",
                  ),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }
            return;
          }
        }
      }
    }

    final cleanCurrent = CourseUtils.cleanSemester(_currentSemester ?? '');
    final currentMap = _history[cleanCurrent] ?? {};

    if (currentMap.containsKey(selectionKey)) {
      setState(() {
        currentMap.remove(selectionKey);
        _selectedSectionIds.remove(selectionKey);
      });
      return;
    }

    if (_isCurrentSemester) {
      final newSchedule = course['schedule'] as List<dynamic>? ?? [];
      for (final existingKey in currentMap.keys) {
        if (existingKey.startsWith("${code}_Sec")) continue;

        final existingCourse = _catalog.firstWhere((c) {
          final cCode = c['code'];
          final cSec = (c['section'] ?? '').toString();
          return "${cCode}_Sec$cSec" == existingKey;
        }, orElse: () => {});

        if (existingCourse.isNotEmpty) {
          final existingSchedule =
              existingCourse['schedule'] as List<dynamic>? ?? [];
          if (_hasTimeConflict(newSchedule, existingSchedule)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Time conflict: $code overlaps with ${existingCourse['code']}.",
                  ),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        }
      }

      final existingKeys = currentMap.keys
          .where((k) => k.startsWith("${code}_Sec"))
          .toList();
      for (final k in existingKeys) {
        currentMap.remove(k);
        _selectedSectionIds.remove(k);
      }
    }

    String grade = "Ongoing";
    if (!_isCurrentSemester) {
      final g = await CourseHistoryGradeDialog.show(
        context: context,
        ref: ref,
        courseCode: code,
        currentSemester: _currentSemester ?? '',
      );
      if (g == null) return;
      grade = g;
    }

    setState(() {
      final cleanCurrent = CourseUtils.cleanSemester(_currentSemester ?? '');
      currentMap[selectionKey] = grade;
      _history[cleanCurrent] = currentMap;

      final List<String> ids = [];
      if (course.containsKey('allIds')) {
        ids.addAll(List<String>.from(course['allIds']));
      } else if (course.containsKey('id')) {
        ids.add(course['id']);
      }
      _selectedSectionIds[selectionKey] = ids;
      _selectedCoursesMetadata[selectionKey] = Map<String, dynamic>.from(course);
    });
  }

  void _removeCourse(String key) {
    setState(() {
      final cleanCurrent = CourseUtils.cleanSemester(_currentSemester ?? '');
      _history[cleanCurrent]?.remove(key);
      _selectedSectionIds.remove(key);
      _selectedCoursesMetadata.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanCurrent = CourseUtils.cleanSemester(_currentSemester ?? '');
    final currentMap = _history[cleanCurrent] ?? {};

    return FullGradientScaffold(
      appBar: AppBar(
        title: widget.isEditMode
            ? DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentSemester,
                  dropdownColor: const Color(0xFF0D2342),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryCyan),
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  items: _allSemesters
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(CourseUtils.prettifySemesterCode(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _confirmAdmittedSemester(val);
                  },
                ),
              )
            : Column(
                children: [
                  Text(
                    "ACADEMIC HISTORY",
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: AppColors.primaryCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CourseUtils.prettifySemesterCode(
                      (_currentSemester == null || _currentSemester!.isEmpty) 
                          ? "Syncing Term..." 
                          : _currentSemester!
                    ),
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Auto-Fetch from Portal",
            icon: const Icon(Icons.cloud_sync_rounded, color: AppColors.primaryCyan),
            onPressed: () async {
              await context.push('/portal-sync');
              _loadInitialData();
            },
          ),
        ],
      ),
      body: _profileLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    CourseHistoryHeaderCard(
                      isCurrentSemester: _isCurrentSemester,
                      currentSemester: _currentSemester,
                      currentMap: currentMap,
                      onTapGrade: (key, code) async {
                        final newGrade = await CourseHistoryGradeDialog.show(
                          context: context,
                          ref: ref,
                          courseCode: code,
                          currentSemester: _currentSemester ?? '',
                        );
                        if (newGrade != null) {
                          setState(() {
                            _history[_currentSemester!]![key] = newGrade;
                          });
                        }
                      },
                      onRemoveCourse: _removeCourse,
                    ),
                    _buildSearchField(),
                    Expanded(
                      child: CourseHistoryCourseList(
                        loading: _loading,
                        catalog: _catalog,
                        isCurrentSemester: _isCurrentSemester,
                        currentSemester: _currentSemester,
                        history: _history,
                        getPassedGrade: _getPassedGrade,
                        onAddCourse: _addCourse,
                      ),
                    ),
                  ],
                ),
                if (_isSyncing) const CourseHistorySyncOverlay(),
              ],
            ),
      bottomNavigationBar: CourseHistoryBottomBar(
        isEditMode: widget.isEditMode,
        isCurrentSemester: _isCurrentSemester,
        onAction: widget.isEditMode
            ? _finishOnboarding
            : (_isCurrentSemester ? _finishOnboarding : _nextSemester),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Search course code...",
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.cyanAccent,
                  ),
                )
              : const Icon(Icons.search, color: Colors.cyanAccent),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
