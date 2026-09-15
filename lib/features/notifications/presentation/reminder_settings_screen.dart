import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/models/profile.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/providers/academic_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import 'widgets/reminder_duration_picker_dialog.dart';
import 'widgets/reminder_schedule_preview_sheet.dart';

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
          for (final row in enrollments) {
            final code = (row['course_code'] ?? '').toString().trim().toUpperCase();
            if (code.isNotEmpty) coursesSet.add(code);
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

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Class Reminder Settings',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Profile not found',
                style: GoogleFonts.sora(color: AppColors.secondaryText),
              ),
            );
          }

          if (_isLoadingCourses) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
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
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: const Icon(Icons.class_outlined, size: 48, color: AppColors.primaryCyan),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No Enrolled Courses Found',
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enroll in courses first to customize your reminder notification schedule.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.primaryCyan, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Class reminders adapt to your schedule: 1st class of the day notifies at 1h, 30m, & 15m. Between-class gaps > 30m notify at 30m & 15m.',
                          style: GoogleFonts.sora(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.45),
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.sora(fontSize: 12, height: 1.4, color: AppColors.secondaryText),
                            children: [
                              TextSpan(
                                text: 'Day-Adaptive Safety: ',
                                style: GoogleFonts.sora(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold),
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
                Text(
                  '1. SELECT COURSE',
                  style: GoogleFonts.sora(
                    color: AppColors.primaryCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: enrolledList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final course = enrolledList[index];
                      final isSelected = course == _selectedCourse;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCourse = course;
                            _loadOffsetsForCourse(profile, course);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                                  )
                                : null,
                            color: isSelected ? null : AppColors.surfaceNavyBlue.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryCyan.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              course,
                              style: GoogleFonts.sora(
                                color: isSelected ? AppColors.primaryNavy : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
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
                    Text(
                      '2. TOTAL NOTIFICATIONS',
                      style: GoogleFonts.sora(
                        color: AppColors.primaryCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${_currentOffsets.length} configured',
                      style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Alerts Count:',
                        style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      DropdownButton<int>(
                        value: _currentOffsets.length.clamp(2, 5),
                        dropdownColor: AppColors.surfaceNavyBlue,
                        style: GoogleFonts.sora(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 15),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryCyan),
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
                Text(
                  '3. REMINDER TIMELINE SLOTS',
                  style: GoogleFonts.sora(
                    color: AppColors.primaryCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
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

                    return GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      borderColor: isFixed
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.primaryCyan.withValues(alpha: 0.25),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isFixed
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.primaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isFixed ? Icons.lock_clock_rounded : Icons.alarm_rounded,
                              color: isFixed ? AppColors.secondaryText : AppColors.primaryCyan,
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
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isFixed ? 'Fixed System Anchor' : 'Custom User Slot (tap to adjust)',
                                  style: GoogleFonts.sora(
                                    color: isFixed ? AppColors.secondaryText : AppColors.primaryCyan.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isFixed)
                            TextButton.icon(
                              onPressed: () => _showDurationPickerDialog(index),
                              icon: const Icon(Icons.edit, size: 15, color: AppColors.primaryCyan),
                              label: Text('Change', style: GoogleFonts.sora(color: AppColors.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'LOCKED',
                                style: GoogleFonts.sora(
                                  color: AppColors.secondaryText,
                                  fontSize: 9,
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
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _showSchedulePreview(profile),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2),
                          )
                        : const Icon(Icons.remove_red_eye_outlined, color: AppColors.primaryNavy),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Preview Schedule & Save',
                      style: GoogleFonts.sora(color: AppColors.primaryNavy, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        SnackBar(
                          content: Text(
                            'Reset to standard anchors (60m, 30m, 15m). Save to apply.',
                            style: GoogleFonts.sora(),
                          ),
                        ),
                      );
                    },
                    child: Text('Reset this course to default', style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
        error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.sora(color: Colors.redAccent))),
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
    final result = await ReminderDurationPickerDialog.show(
      context: context,
      initialMinutes: _currentOffsets[index],
    );
    if (result != null) {
      final updated = List<int>.from(_currentOffsets);
      updated[index] = result;
      updated.add(30);
      updated.add(15);
      final deduplicated = updated.toSet().toList()..sort((a, b) => b.compareTo(a));
      setState(() {
        _currentOffsets = deduplicated;
      });
    }
  }

  void _showSchedulePreview(Profile profile) {
    if (_selectedCourse == null) return;
    ReminderSchedulePreviewSheet.show(
      context: context,
      selectedCourse: _selectedCourse!,
      currentOffsets: _currentOffsets,
      onConfirmSave: () => _savePreferences(profile),
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
