import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/profile.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/providers/academic_providers.dart';
import '../../../core/providers/supabase_provider.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen> {
  String? _selectedCourse;
  bool _isSaving = false;
  bool _isLoadingCourses = true;
  List<String> _enrolledCourses = [];

  // Local working copy of offsets for the currently selected course
  // e.g. [30, 10, 105] in descending order
  List<int> _currentOffsets = [30, 10];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnrolledCourses();
    });
  }

  Future<void> _loadEnrolledCourses() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    final Set<String> coursesSet = {};

    if (user != null) {
      // Get current active semester code
      String? activeSem;
      try {
        final academicState = ref.read(academicStateProvider).valueOrNull ??
            await ref.read(academicStateProvider.future);
        activeSem = academicState?.currentSemesterCode;
      } catch (e) {
        debugPrint('[ReminderSettings] academicState error: $e');
      }

      // If activeSem is still null, fetch from active_semester table
      if (activeSem == null) {
        try {
          final profile = ref.read(userProfileProvider).valueOrNull;
          final track = profile?.track ?? 'tri_semester';
          final semRes = await supabase
              .from('active_semester')
              .select('current_semester_code')
              .eq('track', track == 'bi' ? 'bi_semester' : (track == 'tri' ? 'tri_semester' : track))
              .maybeSingle();
          activeSem = semRes?['current_semester_code']?.toString();
        } catch (e) {
          debugPrint('[ReminderSettings] active_semester fallback error: $e');
        }
      }

      final cleanSem = (activeSem ?? 'Summer2026').replaceAll(' ', '');
      final safeSemLower = cleanSem.toLowerCase();
      final spaceSem = cleanSem.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
      final possibleCodes = [cleanSem, safeSemLower, spaceSem, activeSem ?? ''];

      // 1. Check weekly_grid_cache for the active semester ONLY
      try {
        final stateRes = await supabase
            .from('user_semester_states')
            .select('weekly_grid_cache, semester_code')
            .eq('user_id', user.id)
            .inFilter('semester_code', possibleCodes)
            .maybeSingle();

        final grid = stateRes?['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
        for (final dayClasses in grid.values) {
          if (dayClasses is List) {
            for (final c in dayClasses) {
              final code = (c['courseCode'] ?? c['course_code'] ?? '').toString().trim().toUpperCase();
              if (code.isNotEmpty) coursesSet.add(code);
            }
          }
        }
      } catch (e) {
        debugPrint('[ReminderSettings] weekly_grid_cache error: $e');
      }

      // 2. If weekly_grid_cache had no courses, check enrollments for active semester ONLY
      if (coursesSet.isEmpty) {
        try {
          final enrollments = await supabase
              .from('enrollments')
              .select('course_code')
              .eq('user_id', user.id)
              .inFilter('semester_code', possibleCodes);
          if (enrollments is List) {
            for (final row in enrollments) {
              final code = (row['course_code'] ?? '').toString().trim().toUpperCase();
              if (code.isNotEmpty) coursesSet.add(code);
            }
          }
        } catch (e) {
          debugPrint('[ReminderSettings] enrollments error: $e');
        }
      }

      // 3. Fallback to profile.enrolledSections only if still empty
      if (coursesSet.isEmpty) {
        final profile = ref.read(userProfileProvider).valueOrNull;
        if (profile != null) {
          for (final s in profile.enrolledSections) {
            final code = s.split('-').first.trim().toUpperCase();
            if (code.isNotEmpty && code.length <= 10) coursesSet.add(code);
          }
        }
      }
    }

    final sorted = coursesSet.toList()..sort();
    final profile = ref.read(userProfileProvider).valueOrNull;

    if (mounted) {
      setState(() {
        _enrolledCourses = sorted;
        _isLoadingCourses = false;
        if (sorted.isNotEmpty && (_selectedCourse == null || !sorted.contains(_selectedCourse))) {
          _selectedCourse = sorted.first;
          if (profile != null) {
            _loadOffsetsForCourse(profile, _selectedCourse!);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Class Reminder Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Profile not found', style: TextStyle(color: Colors.white54)),
            );
          }

          if (_isLoadingCourses) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          final enrolledList = List<String>.from(_enrolledCourses);

          if (enrolledList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.class_outlined, size: 48, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Enrolled Courses Found',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enroll in courses first to customize your reminder notification schedule.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          // Default selected course to first one if not set or invalid
          if (_selectedCourse == null || !enrolledList.contains(_selectedCourse)) {
            _selectedCourse = enrolledList.first;
            _loadOffsetsForCourse(profile, _selectedCourse!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Class reminders adapt to your schedule: 1st class of the day notifies at 1h, 30m, & 15m. Between-class gaps > 30m notify at 30m & 15m.',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Day-Adaptive Safety Badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16202E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white70),
                            children: [
                              const TextSpan(
                                text: 'Day-Adaptive Safety: ',
                                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: 'On days where this class immediately follows another class (gap \u2264 30 mins), alerts automatically condense to ',
                              ),
                              const TextSpan(
                                text: '5 minutes ',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: 'so your previous class is not interrupted.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Step 1: Course Selector
                const Text(
                  '1. SELECT COURSE',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: enrolledList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final course = enrolledList[index];
                      final isSelected = course == _selectedCourse;
                      return ChoiceChip(
                        label: Text(course),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCourse = course;
                              _loadOffsetsForCourse(profile, course);
                            });
                          }
                        },
                        selectedColor: Colors.cyanAccent,
                        backgroundColor: const Color(0xFF1A1A2E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? Colors.cyanAccent : Colors.white12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Step 2: Number of Reminders Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '2. TOTAL NOTIFICATIONS',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${_currentOffsets.length} configured',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Alerts Count:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      DropdownButton<int>(
                        value: _currentOffsets.length.clamp(2, 5),
                        dropdownColor: const Color(0xFF1E1E38),
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
                        items: [2, 3, 4, 5].map((int val) {
                          return DropdownMenuItem<int>(
                            value: val,
                            child: Text('$val reminders'),
                          );
                        }).toList(),
                        onChanged: (newCount) {
                          if (newCount == null) return;
                          _adjustSlotCount(newCount);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Step 3: Notification Slots
                const Text(
                  '3. REMINDER TIMELINE SLOTS',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _currentOffsets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final offset = _currentOffsets[index];
                    final isFixed = offset == 30 || offset == 15;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFixed ? Colors.white12 : Colors.cyanAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isFixed
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.cyanAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isFixed ? Icons.lock_clock_rounded : Icons.alarm_rounded,
                              color: isFixed ? Colors.white54 : Colors.cyanAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDuration(offset),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isFixed ? 'Fixed System Anchor' : 'Custom User Slot (tap to adjust)',
                                  style: TextStyle(
                                    color: isFixed ? Colors.white38 : Colors.cyanAccent.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isFixed)
                            TextButton.icon(
                              onPressed: () => _showDurationPickerDialog(index),
                              icon: const Icon(Icons.edit, size: 16, color: Colors.cyanAccent),
                              label: const Text('Change', style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'LOCKED',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // Save & Preview Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _showSchedulePreview(profile),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Icon(Icons.remove_red_eye_outlined, color: Colors.black),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Preview Schedule & Save',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _currentOffsets = [60, 30, 15];
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset to standard anchors (60m, 30m, 15m). Save to apply.')),
                      );
                    },
                    child: const Text('Reset this course to default', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  void _loadOffsetsForCourse(Profile profile, String courseCode) {
    final raw = profile.reminderSettings[courseCode];
    if (raw is List && raw.isNotEmpty) {
      final list = raw.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0 && e <= 300).toSet();
      list.add(30);
      list.add(15);
      final sorted = list.toList()..sort((a, b) => b.compareTo(a));
      _currentOffsets = sorted;
    } else {
      _currentOffsets = [60, 30, 15];
    }
  }

  void _adjustSlotCount(int targetCount) {
    final current = List<int>.from(_currentOffsets);
    if (targetCount > current.length) {
      // Add sensible defaults not already present (up to 5 hours = 300 mins)
      final defaults = [60, 90, 120, 180, 240, 300];
      while (current.length < targetCount) {
        final candidate = defaults.firstWhere(
          (d) => !current.contains(d),
          orElse: () => (current.first + 30).clamp(5, 300),
        );
        current.add(candidate);
      }
    } else if (targetCount < current.length) {
      // Remove custom slots first (never remove 30 or 15)
      while (current.length > targetCount) {
        final removeIndex = current.lastIndexWhere((d) => d != 30 && d != 15);
        if (removeIndex != -1) {
          current.removeAt(removeIndex);
        } else {
          break;
        }
      }
    }
    current.sort((a, b) => b.compareTo(a));
    setState(() {
      _currentOffsets = current;
    });
  }

  Future<void> _showDurationPickerDialog(int index) async {
    int currentMinutes = _currentOffsets[index];
    int selectedHours = currentMinutes ~/ 60;
    int selectedMins = currentMinutes % 60;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final totalCalculated = selectedHours * 60 + selectedMins;
            final isTooLong = totalCalculated > 300;
            final isZero = totalCalculated == 0;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.schedule, color: Colors.cyanAccent),
                  SizedBox(width: 10),
                  Text('Custom Reminder Time', style: TextStyle(color: Colors.white, fontSize: 17)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose how much time before class you want this alert:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hours Picker
                      Column(
                        children: [
                          const Text('Hours', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButton<int>(
                            value: selectedHours,
                            dropdownColor: const Color(0xFF282846),
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
                            underline: const SizedBox(),
                            items: List.generate(6, (h) => DropdownMenuItem(value: h, child: Text('$h h'))),
                            onChanged: (h) {
                              if (h != null) {
                                setDialogState(() {
                                  selectedHours = h;
                                  if (selectedHours == 5) selectedMins = 0; // Max 5 hours
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      const Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 24),
                      // Minutes Picker (5-min intervals)
                      Column(
                        children: [
                          const Text('Minutes', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButton<int>(
                            value: (selectedMins ~/ 5) * 5,
                            dropdownColor: const Color(0xFF282846),
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
                            underline: const SizedBox(),
                            items: List.generate(12, (m) {
                              final minVal = m * 5;
                              return DropdownMenuItem(value: minVal, child: Text('$minVal m'));
                            }),
                            onChanged: selectedHours == 5
                                ? null
                                : (m) {
                                    if (m != null) {
                                      setDialogState(() {
                                        selectedMins = m;
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total: ${_formatDuration(totalCalculated)} before class',
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  if (isTooLong)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Maximum lead time is 5 hours.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  if (isZero)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Time must be greater than 0.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: (isTooLong || isZero)
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          final updated = List<int>.from(_currentOffsets);
                          updated[index] = totalCalculated;
                          updated.add(30);
                          updated.add(15);
                          final deduplicated = updated.toSet().toList()..sort((a, b) => b.compareTo(a));
                          setState(() {
                            _currentOffsets = deduplicated;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSchedulePreview(Profile profile) {
    if (_selectedCourse == null) return;

    // Simulate an example class at 08:30 AM (Dhaka standard first slot)
    const exampleHour = 8;
    const exampleMin = 30;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: Colors.cyanAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confirm ${_selectedCourse!} Schedule',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Here is the exact notification timeline that will be scheduled for every ${_selectedCourse!} class:',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Simulation Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Simulation Example:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Class at 08:30 AM', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    ..._currentOffsets.map((offset) {
                      final totalClassMins = exampleHour * 60 + exampleMin;
                      var triggerMins = totalClassMins - offset;
                      if (triggerMins < 0) triggerMins += 24 * 60; // previous day wrap
                      final th = triggerMins ~/ 60;
                      final tm = triggerMins % 60;
                      final ampm = th >= 12 ? 'PM' : 'AM';
                      final h12 = th % 12 == 0 ? 12 : th % 12;
                      final triggerTimeStr = '${h12.toString().padLeft(2, '0')}:${tm.toString().padLeft(2, '0')} $ampm';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined, color: Colors.cyanAccent, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              triggerTimeStr,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: (offset == 30 || offset == 15)
                                    ? Colors.white10
                                    : Colors.cyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_formatDuration(offset)} before',
                                style: TextStyle(
                                  color: (offset == 30 || offset == 15) ? Colors.white70 : Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Confirm and Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _savePreferences(profile);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Confirm & Save Schedule',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePreferences(Profile profile) async {
    if (_selectedCourse == null) return;

    setState(() => _isSaving = true);
    try {
      final updatedSettings = Map<String, dynamic>.from(profile.reminderSettings);
      final listToSave = _currentOffsets.toSet().toList()..sort((a, b) => b.compareTo(a));
      updatedSettings[_selectedCourse!] = listToSave;

      final updatedProfile = profile.copyWith(reminderSettings: updatedSettings);
      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved reminder schedule for ${_selectedCourse!}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min${minutes == 1 ? '' : 's'}';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return '$hours hr${hours == 1 ? '' : 's'}';
    }
    return '$hours hr${hours == 1 ? '' : 's'} $remainingMins min${remainingMins == 1 ? '' : 's'}';
  }
}
