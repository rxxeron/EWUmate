import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'onboarding_repository.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/utils/course_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseHistoryScreen extends ConsumerStatefulWidget {
  final bool isEditMode;
  const CourseHistoryScreen({super.key, this.isEditMode = false});

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
  List<String> _allSemesters = [];
  String _runningSemester = "Loading...";

  // Current State
  String? _admittedSemester;
  String? _currentSemester;
  int _currentIndex = -1;
  String _searchQuery = '';

  List<Map<String, dynamic>> _getFilteredCourses() {
    return _catalog;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
      if (mounted) setState(() => _loading = false);
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
      final cleanRunning = _runningSemester.trim().toLowerCase();
      final cleanCurrent = semester.trim().toLowerCase();
      _isCurrentSemester = (cleanCurrent == cleanRunning);
      _catalog = [];
    });
    _loadCatalog();
  }

  void _nextSemester() async {
    if ((_history[_currentSemester!] ?? {}).isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please select at least one course for this semester.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

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
      final match =
          _catalog.where((c) {
            final key = _isCurrentSemester
                ? "${c['code']}_Sec${c['section']}"
                : c['code'].toString();
            return key == selection;
          }).firstOrNull ??
          {};

      if (match.isNotEmpty) {
        details.add({
          'id': match['id'],
          'code': (match['code'] ?? selection).toString(),
          'name': (match['name'] ?? match['code'] ?? selection).toString(),
          'section': (match['section'] ?? '').toString(),
          'time': (match['time'] ?? '').toString(),
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
    if ((_history[_currentSemester!] ?? {}).isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select at least one course to continue."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
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
      ]);

      final allSems = results[0] as List<String>;
      final profileData = results[1] as Map<String, dynamic>;
      final completedCourses = results[2] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _runningSemester = (config['current_semester_code'] ?? "Spring2026")
              .toString();
          _allSemesters = allSems;
          if (!_allSemesters.contains(_runningSemester)) {
            _allSemesters.add(_runningSemester);
          }

          _history.clear();
          for (var row in completedCourses) {
            final semRaw = row['semester_code'] as String;
            String sem = semRaw.replaceAll('_', '');
            final reg = RegExp(r'^([a-zA-Z]+)(\d{4})$');
            if (reg.hasMatch(sem)) {
              final m = reg.firstMatch(sem)!;
              final name = m.group(1)!;
              sem =
                  "${name[0].toUpperCase()}${name.substring(1).toLowerCase()}${m.group(2)}";
            }

            final code = row['course_code'] as String;
            final grade = (row['grade'] ?? "Ongoing").toString();

            if (!_history.containsKey(sem)) _history[sem] = {};
            _history[sem]![code] = grade;
          }

          _admittedSemester = (profileData['admitted_semester'] ?? "")
              .toString();
          final programName =
              (profileData['department_name'] ??
                      profileData['program_code'] ??
                      "")
                  .toString()
                  .toLowerCase();

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

          if (widget.isEditMode) {
            final runIdx = _allSemesters.indexOf(_runningSemester);
            final admIdx = _admittedSemester != null
                ? _allSemesters.indexOf(_admittedSemester!)
                : 0;
            if (runIdx > 0 && runIdx > (admIdx != -1 ? admIdx : 0)) {
              _confirmAdmittedSemester(_allSemesters[runIdx - 1]);
            } else if (_allSemesters.isNotEmpty) {
              _confirmAdmittedSemester(
                _allSemesters[admIdx != -1 ? admIdx : 0],
              );
            }
          } else {
            if (_admittedSemester != null &&
                _admittedSemester!.isNotEmpty &&
                _allSemesters.contains(_admittedSemester)) {
              _confirmAdmittedSemester(_admittedSemester!);
            } else {
              _confirmAdmittedSemester(_runningSemester);
            }
          }
          _profileLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _profileLoading = false);
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

  void _addCourse(Map<String, dynamic> course) async {
    if (_currentSemester == null) return;
    final code = course['code'] as String;
    final sectionRaw = (course['section'] ?? '').toString();
    final selectionKey = _isCurrentSemester ? "${code}_Sec$sectionRaw" : code;

    // Check if the course is already taken in another semester within onboarding
    for (final sem in _history.keys) {
      if (sem == _currentSemester) continue;
      final semCourses = _history[sem]!;
      for (final prevKey in semCourses.keys) {
        final baseCode = prevKey.contains('_Sec')
            ? prevKey.split('_Sec').first
            : prevKey;
        if (baseCode == code) {
          final existingGrade = semCourses[prevKey];
          // If already passed, warn/prevent taking it again in another semester
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

    final currentMap = _history[_currentSemester!] ?? {};

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
      final g = await _showGradeDialog(code);
      if (g == null) return;
      grade = g;
    }

    setState(() {
      currentMap[selectionKey] = grade;
      _history[_currentSemester!] = currentMap;

      final List<String> ids = [];
      if (course.containsKey('allIds')) {
        ids.addAll(List<String>.from(course['allIds']));
      } else if (course.containsKey('id')) {
        ids.add(course['id']);
      }
      _selectedSectionIds[selectionKey] = ids;
    });
  }

  void _removeCourse(String key) {
    setState(() {
      _history[_currentSemester!]?.remove(key);
      _selectedSectionIds.remove(key);
    });
  }

  Future<String?> _showGradeDialog(String code) {
    final grades = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "D", "F"];
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text("Grade for $code"),
        children: grades
            .map(
              (g) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, g),
                child: Center(
                  child: Text(
                    g,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: AppBar(
        title: widget.isEditMode
            ? DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentSemester,
                  dropdownColor: const Color(0xFF16202A),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
            : Text(
                _currentSemester ?? "Select Semester",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _profileLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    _buildHeaderCard(),
                    _buildSearchField(),
                    Expanded(child: _buildCourseList()),
                  ],
                ),
                if (_isSyncing) _buildSyncOverlay(),
              ],
            ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildHeaderCard() {
    final currentMap = _history[_currentSemester] ?? {};
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      color: _isCurrentSemester
          ? Colors.greenAccent.withOpacity(0.1)
          : Colors.blueAccent.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCurrentSemester ? "Current Enrollment" : "Academic History",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          if (currentMap.isEmpty)
            const Text(
              "No courses selected for this semester.",
              style: TextStyle(color: Colors.white60),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentMap.entries
                  .map(
                    (e) => Chip(
                      backgroundColor: Colors.white10,
                      label: Text(
                        "${e.key} (${e.value})",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      onDeleted: () => _removeCourse(e.key),
                      deleteIconColor: Colors.white54,
                    ),
                  )
                  .toList(),
            ),
        ],
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
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }
    if (_catalog.isEmpty) {
      return const Center(
        child: Text(
          "No courses found.",
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    String formatSchedule(dynamic scheduleData) {
      if (scheduleData == null || scheduleData is! List || scheduleData.isEmpty) {
        return 'TBA';
      }
      final formatted = scheduleData
          .map((s) {
            if (s is Map) {
              final day = s['day'] ?? '';
              final start = s['startTime'] ?? s['start_time'] ?? '';
              final end = s['endTime'] ?? s['end_time'] ?? '';
              final room = s['room'] ?? '';
              final type = s['type'] != null && s['type'] != 'Theory'
                  ? '(${s['type']}) '
                  : '';

              String sessionText = '$type$day $start-$end'.trim();
              if (room.isNotEmpty) sessionText += ' [$room]';
              return sessionText;
            }
            return '';
          })
          .where((e) => e.isNotEmpty)
          .join(', ');

      return formatted.isEmpty ? 'TBA' : formatted;
    }

    String? getPassedGrade(String courseCode) {
      if (_history.isEmpty) return null;
      for (final sem in _history.keys) {
        if (sem == _currentSemester) continue;
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

    if (!_isCurrentSemester) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _catalog.length,
        itemBuilder: (ctx, i) {
          final c = _catalog[i];
          final code = c['code'] as String;
          final isSelected = (_history[_currentSemester] ?? {}).containsKey(
            code,
          );

          final String? passedGrade = getPassedGrade(code);

          return Card(
            color: passedGrade != null
                ? Colors.white.withOpacity(0.02)
                : Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              enabled: passedGrade == null,
              title: Text(
                code,
                style: TextStyle(
                  color: passedGrade != null
                      ? Colors.white38
                      : Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  decoration: passedGrade != null
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: Colors.white38,
                ),
              ),
              subtitle: Text(
                c['name'] ?? '',
                style: TextStyle(
                  color: passedGrade != null ? Colors.white24 : Colors.white70,
                ),
              ),
              trailing: passedGrade != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Passed ($passedGrade)",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: isSelected ? Colors.greenAccent : Colors.white38,
                    ),
              onTap: passedGrade != null ? null : () => _addCourse(c),
            ),
          );
        },
      );
    } else {
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var c in _catalog) {
        grouped.putIfAbsent(c['code'], () => []).add(c);
      }
      final sortedKeys = grouped.keys.toList()..sort();

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedKeys.length,
        itemBuilder: (ctx, i) {
          final code = sortedKeys[i];
          final sections = grouped[code]!;
          final name = sections.first['name'] ?? '';

          final String? passedGrade = getPassedGrade(code);

          int selectedCount = 0;
          if (passedGrade == null) {
            for (var c in sections) {
              final section = (c['section'] ?? '').toString();
              final selectionKey = "${code}_Sec$section";
              if ((_history[_currentSemester] ?? {}).containsKey(
                selectionKey,
              )) {
                selectedCount++;
              }
            }
          }

          return Card(
            color: passedGrade != null
                ? Colors.white.withOpacity(0.02)
                : Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: selectedCount > 0
                    ? Colors.cyanAccent.withOpacity(0.5)
                    : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                enabled: passedGrade == null,
                iconColor: passedGrade != null ? Colors.white38 : null,
                collapsedIconColor: passedGrade != null
                    ? Colors.transparent
                    : null,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  code,
                  style: TextStyle(
                    color: passedGrade != null
                        ? Colors.white38
                        : Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    decoration: passedGrade != null
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white38,
                  ),
                ),
                subtitle: Text(
                  name,
                  style: TextStyle(
                    color: passedGrade != null
                        ? Colors.white24
                        : Colors.white70,
                  ),
                ),
                trailing: passedGrade != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Passed ($passedGrade)",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : selectedCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Enrolled",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white38,
                      ),
                children: passedGrade != null
                    ? []
                    : sections.map((c) {
                        final section = (c['section'] ?? '').toString();
                        final selectionKey = "${code}_Sec$section";
                        final isSelected = (_history[_currentSemester] ?? {})
                            .containsKey(selectionKey);

                        final faculty = c['faculty'] ?? 'TBA';
                        final schedule = formatSchedule(c['schedule']);

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            title: Text(
                              "Section $section",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Faculty: $faculty\nSchedule: $schedule",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: isSelected
                                  ? Colors.greenAccent
                                  : Colors.white38,
                            ),
                            onTap: () => _addCourse(c),
                          ),
                        );
                      }).toList(),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildSyncOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent),
            SizedBox(height: 16),
            Text(
              "Syncing stats...",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: GlassContainer(
          width: double.infinity, // Explicitly span horizontal
          onTap: widget.isEditMode
              ? _finishOnboarding
              : (_isCurrentSemester ? _finishOnboarding : _nextSemester),
          color: Colors.cyanAccent.withOpacity(0.1),
          borderColor: Colors.cyanAccent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              widget.isEditMode
                  ? "SAVE CHANGES"
                  : (_isCurrentSemester ? "FINISH" : "CONTINUE"),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
