import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/repositories/profile_repository.dart';
import '../../core/theme/ewu_theme_extension.dart';
import '../../core/utils/error_utils.dart';
import '../../core/widgets/glass_kit.dart';
import 'controllers/course_marks_controller.dart';
import 'services/attendance_calendar_service.dart';
import 'widgets/attendance_sessions_tab.dart';
import 'widgets/detail/course_marks_input_tab.dart';
import 'widgets/detail/course_outline_setup_tab.dart';

class CourseProgressDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> courseData;
  final String semesterCode;

  const CourseProgressDetailScreen({
    super.key,
    required this.courseData,
    required this.semesterCode,
  });

  @override
  ConsumerState<CourseProgressDetailScreen> createState() =>
      _CourseProgressDetailScreenState();
}

class _CourseProgressDetailScreenState
    extends ConsumerState<CourseProgressDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CourseMarksController _marksController;

  bool _isSaving = false;
  bool _isLoadingAttendance = true;
  String _attendanceError = '';

  List<AttendanceSession> _generatedClassSessions = [];
  Map<String, String> _markedDates = {};
  Map<String, String> _dateTypes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    _marksController = CourseMarksController(
      initialData: widget.courseData,
      semesterCode: widget.semesterCode,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    final extra = widget.courseData['marks_data'] ?? {};
    final attendance = extra['attendance'] ?? {};
    final datesRaw = attendance['dates'] ?? {};
    final typesRaw = attendance['types'] ?? {};
    _markedDates = Map<String, String>.from(datesRaw);
    _dateTypes = Map<String, String>.from(typesRaw);

    _loadAttendanceCalendar();
  }

  void _handleTabChange() {
    setState(() {});
    if (_tabController.index == 1 && _generatedClassSessions.isEmpty && !_isLoadingAttendance) {
      _loadAttendanceCalendar();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceCalendar() async {
    setState(() {
      _isLoadingAttendance = true;
      _attendanceError = '';
    });

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final courseCode = (widget.courseData['course_code'] ?? '').toString();

      final result = await AttendanceCalendarService.generateSessions(
        courseCode: courseCode,
        semesterCode: widget.semesterCode,
        userTrack: profile?.track,
        existingMarksData: widget.courseData['marks_data'] ?? {},
      );

      if (mounted) {
        setState(() {
          _generatedClassSessions = result.sessions;
          _markedDates = result.markedDates;
          _dateTypes = result.dateTypes;
          _isLoadingAttendance = false;
        });

        // Silent auto-save if newly discovered session types changed
        if (result.typesChanged) {
          _marksController.saveMarks(
            ref: ref,
            markedDates: _markedDates,
            dateTypes: _dateTypes,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _attendanceError = e.toString();
          _isLoadingAttendance = false;
        });
      }
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      await _marksController.saveMarks(
        ref: ref,
        markedDates: _markedDates,
        dateTypes: _dateTypes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully!', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorUtils.getFriendlyMessage(e), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addCustomClassDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 120)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null) {
      if (!mounted) return;
      String selectedType = 'Theory';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDlgState) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Add Makeup Class', style: TextStyle(color: Colors.white, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose session type:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Theory'),
                      selected: selectedType == 'Theory',
                      onSelected: (val) {
                        if (val) setDlgState(() => selectedType = 'Theory');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Lab'),
                      selected: selectedType == 'Lab',
                      onSelected: (val) {
                        if (val) setDlgState(() => selectedType = 'Lab');
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
            ],
          ),
        ),
      );

      if (confirmed == true && mounted) {
        setState(() {
          _generatedClassSessions.insert(0, AttendanceSession(picked, selectedType));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final courseCode = widget.courseData['course_code'] ?? 'Course';

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          courseCode,
          style: GoogleFonts.sora(
            color: colors.primaryText,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.primaryText),
        actions: [
          IconButton(
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: colors.primaryCyan, strokeWidth: 2),
                  )
                : Icon(Icons.check_circle_rounded, color: colors.primaryCyan, size: 28),
            onPressed: _isSaving ? null : _saveData,
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primaryCyan,
          indicatorWeight: 3,
          labelColor: colors.primaryCyan,
          unselectedLabelColor: colors.secondaryText,
          labelStyle: GoogleFonts.sora(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Marks'),
            Tab(text: 'Attendance'),
            Tab(text: 'Setup'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Marks input & simulator
          CourseMarksInputTab(
            marksController: _marksController,
            onMarksChanged: () => setState(() {}),
          ),

          // Tab 2: Attendance Sessions
          AttendanceSessionsTab(
            isLoading: _isLoadingAttendance,
            errorMessage: _attendanceError,
            sessions: _generatedClassSessions,
            markedDates: _markedDates,
            onRetry: _loadAttendanceCalendar,
            onAddMakeup: _addCustomClassDate,
            onStatusChanged: (sessionKey, newStatus) {
              setState(() {
                final parts = sessionKey.split('_');
                if (newStatus == null) {
                  _markedDates.remove(sessionKey);
                  if (parts.isNotEmpty) _markedDates.remove(parts[0]);
                } else {
                  _markedDates[sessionKey] = newStatus;
                  if (parts.isNotEmpty) _markedDates[parts[0]] = newStatus;
                }
              });
            },
          ),

          // Tab 3: Outline & Quiz Setup
          CourseOutlineSetupTab(
            marksController: _marksController,
            onStrategyChanged: (val) {
              setState(() => _marksController.quizStrategy = val);
            },
          ),
        ],
      ),
    );
  }
}
