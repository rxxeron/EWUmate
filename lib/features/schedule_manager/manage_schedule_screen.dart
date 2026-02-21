import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/models/course_model.dart';
import '../calendar/academic_repository.dart';
import 'schedule_manager_repository.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  final ScheduleManagerRepository _repo = ScheduleManagerRepository();
  final AcademicRepository _academicRepo = AcademicRepository();

  String _semesterCode = '';
  List<Course> _courses = [];
  List<Map<String, dynamic>> _exceptions = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    try {
      _semesterCode = await _academicRepo.getCurrentSemesterCode();
      final courses = await _repo.fetchEnrolledCourses(_semesterCode);
      final dates = await _repo.fetchSemesterDates(_semesterCode);
      final exceptions = await _repo.fetchExceptions(_semesterCode);

      setState(() {
        _courses = courses;
        _startDate = dates['start'];
        _endDate = dates['end'];
        _exceptions = exceptions;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading schedule manager: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: AppBar(
        title: const Text("Manage Schedule",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _courses.isEmpty
              ? const Center(
                  child: Text("No enrolled courses found",
                      style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (ctx, i) => _buildCourseCard(_courses[i]),
                ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 16,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(course.code,
            style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(course.courseName,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(_formatSessions(course.sessions),
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.edit_calendar, color: Colors.white70),
        onTap: () => _showSessionSheet(course),
      ),
    );
  }

  void _showSessionSheet(Course course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) {
          final sessions = _generateSessionDates(course);

          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("${course.code} Sessions",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                  ),
                  Expanded(
                    child: sessions.isEmpty
                        ? const Center(
                            child: Text(
                                "No sessions found for this semester dates.",
                                style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sessions.length,
                            itemBuilder: (ctx, i) {
                              final s = sessions[i];
                              return _buildSessionItem(s, course, () async {
                                await _initData(); // Refresh overrides
                                setSheetState(() {});
                              });
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionItem(
      _SessionItem item, Course course, VoidCallback onUpdate) {
    final isCancelled = item.status == 'cancelled';
    final hasMakeup = item.makeupDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCancelled
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isCancelled ? Colors.redAccent : Colors.greenAccent,
            width: 1),
      ),
      child: ListTile(
        title: Text(
          DateFormat('EEEE, MMM d').format(item.date),
          style: TextStyle(
            color: Colors.white,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                isCancelled
                    ? "Cancelled"
                    : "${item.baseSession?.startTime} - ${item.baseSession?.endTime}",
                style: TextStyle(
                    color: isCancelled ? Colors.redAccent : Colors.white70)),
            if (hasMakeup)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.event_repeat,
                        size: 14, color: Colors.orangeAccent),
                    const SizedBox(width: 4),
                    Text(
                        "Makeup: ${DateFormat('MMM d, h:mm a').format(item.makeupDate!)}",
                        style: const TextStyle(
                            color: Colors.orangeAccent, fontSize: 12)),
                  ],
                ),
              )
          ],
        ),
        trailing: isCancelled
            ? IconButton(
                icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                onPressed: () =>
                    _showMakeupPicker(item, course, onUpdate, edit: true),
              )
            : const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
        onTap: () {
          if (isCancelled) {
            _showRestoreDialog(item, course, onUpdate);
          } else {
            _showCancelDialog(item, course, onUpdate);
          }
        },
      ),
    );
  }

  Future<void> _showCancelDialog(
      _SessionItem item, Course course, VoidCallback onUpdate) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text("Cancel Class?", style: TextStyle(color: Colors.white)),
        content: Text(
            "Mark ${DateFormat('MMM d').format(item.date)} as cancelled?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _repo.updateException(
                _semesterCode,
                course.id,
                course.code,
                course.courseName,
                item.date,
                'cancel',
              );
              onUpdate();
            },
            child: const Text("Yes, Cancel",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestoreDialog(
      _SessionItem item, Course course, VoidCallback onUpdate) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text("Restore Class?", style: TextStyle(color: Colors.white)),
        content: Text(
            "Set ${DateFormat('MMM d').format(item.date)} back to active?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Back")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _repo.updateException(
                _semesterCode,
                course.id,
                course.code,
                course.courseName,
                item.date,
                'active',
              );
              onUpdate();
            },
            child: const Text("Restore",
                style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showMakeupPicker(
      _SessionItem item, Course course, VoidCallback onUpdate,
      {bool edit = false}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: item.makeupDate ?? item.date,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(item.makeupDate ?? item.date),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    String? room = item.makeupRoom ?? item.baseSession?.room;
    if (!mounted) return;

    final roomController = TextEditingController(text: room);
    final roomConfirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Enter Room", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: roomController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Room Number",
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, roomController.text),
            child:
                const Text("Save", style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );

    if (roomConfirmed == null) return;

    final makeupDateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    await _repo.updateException(
      _semesterCode,
      course.id,
      course.code,
      course.courseName,
      item.date,
      'makeup',
      makeupDate: makeupDateTime,
      room: roomConfirmed,
    );
    onUpdate();
  }

  List<_SessionItem> _generateSessionDates(Course course) {
    if (_startDate == null || _endDate == null) return [];

    final List<_SessionItem> items = [];
    final daysMap = {
      'S': DateTime.sunday,
      'M': DateTime.monday,
      'T': DateTime.tuesday,
      'W': DateTime.wednesday,
      'R': DateTime.thursday,
      'F': DateTime.friday,
      'A': DateTime.saturday,
    };

    final nameMap = {
      'sunday': DateTime.sunday,
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sun': DateTime.sunday,
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
    };

    final sessionDays = <int, CourseSession>{};
    for (var s in course.sessions) {
      final lower = s.day.toLowerCase().trim();
      bool found = false;

      for (var entry in nameMap.entries) {
        if (lower.contains(entry.key)) {
          sessionDays[entry.value] = s;
          found = true;
        }
      }

      if (!found) {
        final clean = s.day.replaceAll(' ', '').toUpperCase();
        for (var char in clean.split('')) {
          if (daysMap.containsKey(char)) {
            sessionDays[daysMap[char]!] = s;
          }
        }
      }
    }

    DateTime current = _startDate!;
    while (!current.isAfter(_endDate!)) {
      if (sessionDays.containsKey(current.weekday)) {
        final dateStr = current.toIso8601String().split('T')[0];
        Map<String, dynamic>? exception;

        for (var e in _exceptions) {
          if (e['courseCode'] == course.code && e['date'] == dateStr) {
            exception = e;
            break;
          }
        }

        DateTime? makeup;
        String? makeupRoom;
        String status = 'active';

        if (exception != null) {
          final type = exception['type'];
          if (type == 'cancel') status = 'cancelled';
          if (type == 'makeup') {
            status = 'cancelled';
            if (exception['makeupDate'] != null) {
              makeup = DateTime.tryParse(exception['makeupDate']);
            }
            makeupRoom = exception['room'];
          }
        }

        items.add(_SessionItem(
          date: current,
          status: status,
          makeupDate: makeup,
          makeupRoom: makeupRoom,
          baseSession: sessionDays[current.weekday],
        ));
      }
      current = current.add(const Duration(days: 1));
    }
    return items;
  }

  String _formatSessions(List<CourseSession> sessions) {
    return sessions
        .map((s) => "${s.day} ${s.startTime}-${s.endTime} (${s.room})")
        .join(", ");
  }
}

class _SessionItem {
  final DateTime date;
  final String status;
  final DateTime? makeupDate;
  final String? makeupRoom;
  final CourseSession? baseSession;

  _SessionItem(
      {required this.date,
      required this.status,
      this.makeupDate,
      this.makeupRoom,
      this.baseSession});
}
