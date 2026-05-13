import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/course_repository.dart';
import '../../../core/repositories/schedule_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/models/active_semester.dart';
import '../../../core/models/course_metadata.dart';
import '../../../core/models/course_section.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../course_browser/presentation/providers/course_browser_providers.dart';
import 'user_academic_providers.dart';
import '../../../core/providers/feature_flag_provider.dart';

class NextSemesterScreen extends ConsumerStatefulWidget {
  const NextSemesterScreen({super.key});

  @override
  ConsumerState<NextSemesterScreen> createState() => _NextSemesterScreenState();
}

class _NextSemesterScreenState extends ConsumerState<NextSemesterScreen> {
  String _searchQuery = "";
  final List<Map<String, String>> _selectedCourses = [];
  final Map<String, CourseSection> _selectedSections =
      {}; // section_id -> CourseSection for conflict checking
  bool _isSaving = false;
  bool _isManualMode = false;
  bool _isLoadingExisting = true;
  String? _loadedSemCode;
  int _activeTab = 0; // 0: Available, 1: Selected

  @override
  void initState() {
    super.initState();
    // Load will be triggered by build once we get the active semester
  }

  Future<void> _loadExistingEnrollments(String nextSemCode) async {
    if (_loadedSemCode == nextSemCode) return; // already loaded
    _loadedSemCode = nextSemCode;

    final lowerSemCode = nextSemCode.toLowerCase();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        setState(() => _isLoadingExisting = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('enrollments')
          .select('course_code, section_id, section')
          .eq('user_id', user.id)
          .eq('semester_code', nextSemCode)
          .eq('status', 'upcoming');

      if (!mounted) return;

      if (response.isNotEmpty) {
        final sectionIds = response
            .map((e) => e['section_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        final courseCodes = response
            .map((e) => e['course_code']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();

        List<dynamic> sectionsData = [];
        List<dynamic> metadataData = [];

        if (sectionIds.isNotEmpty) {
          try {
            sectionsData = await Supabase.instance.client
                .from('courses_$lowerSemCode')
                .select()
                .inFilter('id', sectionIds);
          } catch (e) {
            debugPrint('Failed to fetch section data: $e');
          }
        }

        if (courseCodes.isNotEmpty) {
          try {
            metadataData = await Supabase.instance.client
                .from('course_metadata')
                .select('code, name')
                .inFilter('code', courseCodes);
          } catch (e) {
            debugPrint('Failed to fetch course metadata: $e');
          }
        }

        // Create lookup maps
        final Map<String, dynamic> secDataMap = {
          for (var s in sectionsData) s['id'].toString(): s,
        };
        final Map<String, String> metaDataMap = {
          for (var m in metadataData)
            m['code'].toString(): m['name']?.toString() ?? '',
        };

        setState(() {
          for (final row in response) {
            final code = row['course_code']?.toString() ?? '';
            final secId = row['section_id']?.toString() ?? '';
            final secNum = row['section']?.toString() ?? '';
            // Assign name from the metadata map
            final cName = metaDataMap[code] ?? '';

            _selectedCourses.add({
              'code': code,
              'section': secNum,
              'section_id': secId,
              'name': cName,
            });

            if (secId.isNotEmpty && secDataMap.containsKey(secId)) {
              try {
                final secData = secDataMap[secId];
                if (secData != null) {
                  final sectionObj = CourseSection.fromJson(
                    secData as Map<String, dynamic>,
                  );
                  _selectedSections[secId] = sectionObj;
                }
              } catch (e) {
                debugPrint(
                  'Failed to parse section data for conflict checking: $e',
                );
              }
            }
          }
          _isManualMode =
              true; // Switch to manual mode if we have existing selections
        });
      }
    } catch (e) {
      debugPrint('Error loading existing enrollments: $e');
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  /// Parse "08:00 AM" or "01:30 PM" into minutes since midnight for comparison
  int _parseTime(String t) {
    t = t.trim().toUpperCase();
    final isPM = t.contains('PM');
    final isAM = t.contains('AM');
    t = t.replaceAll(RegExp(r'[APM\s]'), '');
    final parts = t.split(':');
    if (parts.length != 2) return 0;
    var hour = int.tryParse(parts[0]) ?? 0;
    final min = int.tryParse(parts[1]) ?? 0;
    if (isPM && hour != 12) hour += 12;
    if (isAM && hour == 12) hour = 0;
    return hour * 60 + min;
  }

  /// Check if a new section conflicts with any already-selected sections
  String? _findConflict(CourseSection newSection) {
    for (final entry in _selectedSections.entries) {
      final existing = entry.value;
      for (final newSess in newSection.sessions) {
        for (final existSess in existing.sessions) {
          // Same day?
          if (newSess.day == existSess.day) {
            final newStart = _parseTime(newSess.startTime);
            final newEnd = _parseTime(newSess.endTime);
            final exStart = _parseTime(existSess.startTime);
            final exEnd = _parseTime(existSess.endTime);
            if (newStart < exEnd && newEnd > exStart) {
              return '${existing.code} Sec ${existing.section}';
            }
          }
        }
      }
    }
    return null;
  }

  void _toggleSection({
    required CourseMetadata course,
    required CourseSection section,
  }) {
    final exists = _selectedCourses.indexWhere(
      (c) => c['section_id'] == section.id,
    );
    if (exists != -1) {
      // Deselect
      setState(() {
        _selectedCourses.removeAt(exists);
        _selectedSections.remove(section.id);
      });
    } else {
      // Check for time conflicts (exclude same course since we replace it)
      final tempSections = Map<String, CourseSection>.from(_selectedSections);
      tempSections.removeWhere((_, v) => v.code == course.code);
      final oldSections = _selectedSections;
      _selectedSections.clear();
      _selectedSections.addAll(tempSections);
      final conflict = _findConflict(section);
      _selectedSections.clear();
      _selectedSections.addAll(oldSections);

      if (conflict != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Time conflict with $conflict'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        // Remove any previously selected section of the same course
        final oldId = _selectedCourses.firstWhere(
          (c) => c['code'] == course.code,
          orElse: () => {},
        )['section_id'];
        if (oldId != null) _selectedSections.remove(oldId);
        _selectedCourses.removeWhere((c) => c['code'] == course.code);

        _selectedCourses.add({
          'code': course.code,
          'section': section.section.toString(),
          'section_id': section.id,
          'name': course.name,
        });
        _selectedSections[section.id] = section;
      });
    }
  }

  void _importDraft(Map<String, dynamic> draft) {
    final combo = draft['combination_data'] ?? {};
    final sections = combo['sections'] as Map<String, dynamic>? ?? {};

    setState(() {
      _selectedCourses.clear();
      for (final sec in sections.values) {
        _selectedCourses.add({
          'code': (sec['course_code'] ?? sec['code'] ?? '???').toString(),
          'section': (sec['section_number'] ?? sec['section'] ?? '').toString(),
          'section_id': (sec['id'] ?? '').toString(),
          'name': (sec['course_name'] ?? sec['name'] ?? '').toString(),
        });
      }
      _isManualMode = true;
    });
  }

  Future<void> _saveExpectedSchedule(ActiveSemester activeSem) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final nextSemCode = activeSem.nextSemesterCode;
    if (nextSemCode == null || nextSemCode.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      // Clear previous selection for this semester
      await Supabase.instance.client
          .from('enrollments')
          .delete()
          .eq('user_id', user.id)
          .eq('semester_code', nextSemCode)
          .eq('status', 'upcoming');

      if (_selectedCourses.isNotEmpty) {
        final payload = _selectedCourses
            .map(
              (c) => {
                'user_id': user.id,
                'course_code': c['code'],
                'semester_code': nextSemCode,
                'section': c['section'],
                'section_id': c['section_id'],
                'status': 'upcoming',
              },
            )
            .toList();

        await Supabase.instance.client.from('enrollments').insert(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Strategy saved successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
        ref.invalidate(userEnrollmentsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLockedView(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.cyan.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          children: [
            if (isActive) ...[
              const Icon(Icons.check, size: 16, color: Colors.black),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSemAsync = ref.watch(activeSemesterProvider);
    final draftsAsync = ref.watch(savedSchedulesProvider);
    final isFeatureOpenAsync = ref.watch(isNextSemesterOpenProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF16202A),
      appBar: AppBar(
        title: const Text(
          'Confirm Schedule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: activeSemAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (e, _) => Center(
          child: Text(
            'Error loading configuration',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (activeSem) {
          if (activeSem == null) {
            return const Center(
              child: Text(
                'Configuration missing.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final now = DateTime.now();
          final advEnd = activeSem.advisingEndDate;
          final classStart = activeSem.upcomingClassesStartDate;

          // Manual Admin Switch Overrides Automatic Dates
          final isFeatureOpen = isFeatureOpenAsync.value ?? false;
          bool isLocked = !isFeatureOpen;

          if (isLocked) {
            final openDateStr = advEnd != null
                ? DateFormat('MMM dd, yyyy h:mm a').format(advEnd)
                : 'TBA';
            final closeDateStr = classStart != null
                ? DateFormat('MMM dd, yyyy h:mm a').format(classStart)
                : 'TBA';
            return _buildLockedView(
              'Schedule Confirmation Locked',
              'This section opens on $openDateStr and closes on $closeDateStr.',
              Icons.lock_clock,
            );
          }

          final nextSemCode = activeSem.nextSemesterCode;
          if (nextSemCode == null) {
            return const Center(
              child: Text(
                'Next semester code not available.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // Trigger loading of existing enrollments once we have the semester code
          if (_loadedSemCode != nextSemCode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadExistingEnrollments(nextSemCode);
            });
          }

          if (_isLoadingExisting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          final semesterCoursesAsync = ref.watch(
            semesterCoursesProvider(nextSemCode),
          );
          final isAdvisingActive =
              activeSem.advisingEndDate != null &&
              DateTime.now().isBefore(activeSem.advisingEndDate!);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    // Warning Banner
                    if (isAdvisingActive)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: GlassContainer(
                          opacity: 0.1,
                          color: Colors.orange,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orangeAccent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Advising for $nextSemCode is in progress.',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Draft Discovery
                    if (!_isManualMode && _selectedCourses.isEmpty)
                      draftsAsync.when(
                        data: (drafts) {
                          final nextSemDrafts = drafts
                              .where(
                                (d) => (d['semester_code'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains(nextSemCode.toLowerCase()),
                              )
                              .toList();
                          if (nextSemDrafts.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final latestDraft = nextSemDrafts.first;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: GlassContainer(
                              opacity: 0.15,
                              borderColor: Colors.cyan.withValues(alpha: 0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.cyan,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Draft Found!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        nextSemCode,
                                        style: const TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'We found a saved draft for your upcoming semester.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setState(
                                            () => _isManualMode = true,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: const Text(
                                            'Manual Entry',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            final userId = ref
                                                .read(currentUserProvider)
                                                ?.id;
                                            if (userId != null) {
                                              await ref
                                                  .read(
                                                    scheduleRepositoryProvider,
                                                  )
                                                  .deleteDraft(
                                                    userId,
                                                    nextSemCode,
                                                  );
                                              ref.invalidate(
                                                savedSchedulesProvider,
                                              );
                                            }
                                            setState(
                                              () => _isManualMode = true,
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          child: const Text(
                                            'Discard',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () =>
                                              _importDraft(latestDraft),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.cyan,
                                          ),
                                          child: const Text(
                                            'Use Draft',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                      ),

                    // Manual Search / Course Browser Style Builder
                    Builder(
                      builder: (context) {
                        final drafts = draftsAsync.valueOrNull ?? [];
                        final hasDrafts = drafts.any(
                          (d) => (d['semester_code'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(nextSemCode.toLowerCase()),
                        );
                        final showManual =
                            _isManualMode ||
                            _selectedCourses.isNotEmpty ||
                            (!hasDrafts &&
                                draftsAsync.hasValue &&
                                !draftsAsync.isLoading);

                        if (!showManual) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Beautiful Tabs
                            Row(
                              children: [
                                _buildTabChip(
                                  'Available',
                                  _activeTab == 0,
                                  () => setState(() => _activeTab = 0),
                                ),
                                const SizedBox(width: 12),
                                _buildTabChip(
                                  'Selected (${_selectedCourses.length})',
                                  _activeTab == 1,
                                  () => setState(() => _activeTab = 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_activeTab == 0) ...[
                              TextField(
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search code or name (e.g. CSE101)',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.cyan,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            semesterCoursesAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.cyan,
                                ),
                              ),
                              error: (e, _) => const Text(
                                'Failed to load courses for search',
                              ),
                              data: (courses) {
                                List<CourseMetadata> filtered = [];

                                if (_activeTab == 0) {
                                  // Available tab
                                  final queryMatch = _searchQuery.toLowerCase().replaceAll(' ', '');
                                  filtered = courses
                                      .where(
                                        (c) {
                                          final normalizedCode = c.code.toLowerCase().replaceAll(' ', '');
                                          final normalizedName = c.name.toLowerCase().replaceAll(' ', '');
                                          return normalizedCode.contains(queryMatch) || normalizedName.contains(queryMatch);
                                        }
                                      )
                                      .toList();

                                  if (filtered.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No courses found.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }
                                } else {
                                  // Selected tab
                                  final selectedCodes = _selectedCourses
                                      .map((e) => e['code'])
                                      .toSet();
                                  filtered = courses
                                      .where(
                                        (c) => selectedCodes.contains(c.code),
                                      )
                                      .toList();

                                  if (filtered.isEmpty) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 20.0),
                                        child: Text(
                                          'No courses added yet. Search and add pieces from the Available tab.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
                                }

                                return Column(
                                  children: filtered.map((course) {
                                    final bool isAnySelected = _selectedCourses
                                        .any((c) => c['code'] == course.code);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1E2836,
                                        ).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isAnySelected
                                              ? Colors.cyan.withValues(
                                                  alpha: 0.3,
                                                )
                                              : Colors.white12,
                                        ),
                                      ),
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course.code,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              course.name,
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_activeTab == 1) // Selected Tab
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedCourses.removeWhere((c) => c['code'] == course.code);
                                                    _selectedSections.removeWhere((_, v) => v.code == course.code);
                                                  });
                                                },
                                              ),
                                            Icon(
                                              isAnySelected
                                                  ? Icons.check_circle
                                                  : Icons.add_circle_outline,
                                              color: isAnySelected
                                                  ? Colors.cyan
                                                  : Colors.white24,
                                            ),
                                          ],
                                        ),
                                        children: [
                                          const Divider(
                                            height: 1,
                                            color: Colors.white10,
                                          ),
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final sectionsAsync = ref.watch(
                                                courseSectionsProvider(
                                                  semesterCode: nextSemCode,
                                                  courseCode: course.code,
                                                ),
                                              );
                                              return sectionsAsync.when(
                                                loading: () =>
                                                    const LinearProgressIndicator(
                                                      color: Colors.cyan,
                                                    ),
                                                error: (e, _) => const Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Text(
                                                    'Failed to load sections',
                                                  ),
                                                ),
                                                data: (sections) => Column(
                                                  children: sections.map((sec) {
                                                    final isThisSelected =
                                                        _selectedCourses.any(
                                                          (c) =>
                                                              c['section_id'] ==
                                                              sec.id,
                                                        );
                                                    // Extract faculty name from the first session
                                                    final faculty =
                                                        sec
                                                                .sessions
                                                                .isNotEmpty &&
                                                            sec
                                                                .sessions
                                                                .first
                                                                .faculty
                                                                .isNotEmpty
                                                        ? sec
                                                              .sessions
                                                              .first
                                                              .faculty
                                                        : null;
                                                    return ListTile(
                                                      title: Row(
                                                        children: [
                                                          Text(
                                                            'Section ${sec.section}',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          _buildCapacityIndicator(
                                                            sec.capacity,
                                                          ),
                                                          if (faculty !=
                                                              null) ...[
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                '• $faculty',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .cyan
                                                                      .withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      ),
                                                                  fontSize: 12,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      subtitle: Text(
                                                        sec.sessions
                                                            .map(
                                                              (s) =>
                                                                  '${s.day} ${s.startTime}-${s.endTime}',
                                                            )
                                                            .join(' | '),
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                      trailing: Switch(
                                                        value: isThisSelected,
                                                        activeThumbColor:
                                                            Colors.cyan,
                                                        onChanged: (_) =>
                                                            _toggleSection(
                                                              course: course,
                                                              section: sec,
                                                            ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ), // semesterCoursesAsync.when
                          ],
                        ); // Column (Builder return)
                      },
                    ), // Builder
                  ], // ListView children
                ), // ListView
              ), // Expanded
              // Sticky Confirmation Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2836).withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Row(
                          children: [
                            Text(
                              _selectedCourses.isEmpty 
                                ? 'No Courses Selected'
                                : '${_selectedCourses.length} Courses Selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedCourses.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _selectedCourses.clear()),
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                          ],
                        ),
                      if (_isManualMode || _selectedCourses.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving
                                ? null
                                : () => _saveExpectedSchedule(activeSem),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.black,
                                  )
                                : Text(
                                    _selectedCourses.isEmpty 
                                      ? 'Clear & Save Empty Strategy'
                                      : 'Confirm & Save Strategy',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      if (_selectedCourses.isNotEmpty)
                        const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.white38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Skip / Do it Later',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ], // outer Column children
          ); // Column
        }, // data callback
      ), // activeSemAsync.when
    ); // Scaffold
  }

  Widget _buildCapacityIndicator(String capacity) {
    if (capacity.isEmpty || !capacity.contains('/')) {
      return const SizedBox.shrink();
    }
    try {
      final parts = capacity.split('/');
      final enrolled = int.parse(parts[0].trim());
      final total = int.parse(parts[1].trim());
      final bool isFull =
          (total > 0 && enrolled >= total) || (total == 0 && enrolled > 0);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: (isFull ? Colors.redAccent : Colors.cyan).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: (isFull ? Colors.redAccent : Colors.cyan).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          isFull ? 'Full' : '${total - enrolled} Left',
          style: TextStyle(
            color: isFull ? Colors.redAccent : Colors.cyan,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
