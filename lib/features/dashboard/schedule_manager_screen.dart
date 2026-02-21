import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_logic.dart';
import 'exception_repository.dart';
import 'dashboard_repository.dart';
import '../course_browser/course_repository.dart';
import '../../core/services/schedule_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../features/calendar/academic_repository.dart';
import '../../core/services/connectivity_service.dart';

/// Rebuilt Manager Screen - No Caching, Direct Firestore
class ScheduleManagerScreen extends StatefulWidget {
  const ScheduleManagerScreen({super.key});

  @override
  State<ScheduleManagerScreen> createState() => _ScheduleManagerScreenState();
}

class _ScheduleManagerScreenState extends State<ScheduleManagerScreen> {
  final AcademicRepository _academicRepo = AcademicRepository();
  final ExceptionRepository _exceptionRepo = ExceptionRepository();
  // Using DashboardRepository to fetch schedule data consistently
  final DashboardRepository _dashboardRepo = DashboardRepository();

  bool _loading = true;
  Map<String, dynamic>? _cloudSchedule;
  List<Map<String, dynamic>> _userExceptions = [];
  String _semesterCode = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load data using Repositories
  Future<void> _loadData({bool silent = false}) async {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) context.pop(); // Exit if not logged in
      return;
    }

    if (!silent) setState(() => _loading = true);
    try {
      // 1. Get Semester
      _semesterCode = await _academicRepo.getCurrentSemesterCode();

      // 2. Fetch User Exceptions (for the Pending Actions tab)
      final exceptions = await _exceptionRepo.fetchExceptions();
      
      // 3. Auto-sync Schedule (Generate Weekly Template & Merge Holidays) in background
      // ONLY trigger if this is NOT a silent refresh to avoid infinite loops
      if (!silent) {
        () async {
          try {
            final profileData = await CourseRepository().fetchUserData();
            final List<String> enrolledIds = List<String>.from(profileData['enrolled_sections'] ?? []);
            await ScheduleService().syncUserSchedule(_semesterCode, enrolledIds);
            // Gently refresh UI if we got fresh data
            if (mounted) _loadData(silent: true);
          } catch (e) {
            debugPrint("Auto-sync background error: $e");
          }
        }();
      }

      // 4. Fetch merged schedule using robust REST Future (no WebSockets)
      final scheduleData = await _dashboardRepo.getScheduleFuture(_semesterCode);

      if (mounted) {
        setState(() {
          _cloudSchedule = scheduleData;
          _userExceptions = exceptions;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading manager: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Merge cloud exceptions and user exceptions for logic processing
  Map<String, dynamic> _getMergedSchedule() {
    final base = _cloudSchedule ?? {};
    final merged = Map<String, dynamic>.from(base);
    final cloudEx = (merged['exceptions'] as List<dynamic>?) ?? [];
    merged['exceptions'] = [...cloudEx, ..._userExceptions];
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let gradient show through
        appBar: EWUmateAppBar(
          title: "Manage Schedule",
          showBack: true,
          bottom: const TabBar(
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Upcoming Classes"),
              Tab(text: "Pending Actions"),
            ],
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent))
            : TabBarView(
                children: [
                  _safeBuildUpcoming(),
                  _safeBuildPending(),
                ],
              ),
      ),
    );
  }

  Widget _safeBuildUpcoming() {
    try {
      return _buildUpcomingClasses();
    } catch (e) {
      debugPrint("Crash in _buildUpcomingClasses: $e");
      return Center(child: Text("Error: $e", style: const TextStyle(color: Colors.redAccent)));
    }
  }

  Widget _safeBuildPending() {
    try {
      return _buildPendingActions();
    } catch (e) {
      debugPrint("Crash in _buildPendingActions: $e");
      return Center(child: Text("Error: $e", style: const TextStyle(color: Colors.redAccent)));
    }
  }

  /// Tab 1: List of upcoming classes (Next 14 days)
  Widget _buildUpcomingClasses() {
    if (_cloudSchedule == null) {
      return const Center(
          child: Text("No schedule data available",
              style: TextStyle(color: Colors.white54)));
    }

    final merged = _getMergedSchedule();
    final today = DateTime.now();
    // Generate next 24 days of classes
    // We'll just generate the list
    final List<Map<String, dynamic>> upcomingList = [];

    // Helper to format date
    final dateFormat = DateFormat('EEE, MMM d');

    for (int i = 0; i < 24; i++) {
      final date = today.add(Duration(days: i));
      final result = DashboardLogic.getScheduleForDate(merged, date);
      final status = result['status'];
      final reason = result['reason'] ?? "";
      final classes = result['schedule'] as List<ScheduleItem>;
 
      if (status == 'holiday') {
        upcomingList.add({
          'date': date,
          'dateStr': dateFormat.format(date),
          'type': 'holiday',
          'reason': reason,
        });
      } else if (status == 'chill' && classes.isEmpty) {
         upcomingList.add({
          'date': date,
          'dateStr': dateFormat.format(date),
          'type': 'chill',
          'reason': reason,
        });
      } else if (classes.isNotEmpty) {
        for (var item in classes) {
          upcomingList.add({
            'date': date,
            'dateStr': dateFormat.format(date),
            'type': 'class',
            'item': item,
          });
        }
      }
    }

    if (upcomingList.isEmpty) {
      return const Center(
          child: Text("No upcoming classes found",
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingList.length,
      itemBuilder: (context, index) {
        final entry = upcomingList[index];
        final date = entry['date'] as DateTime;
        final dateStr = entry['dateStr'] as String;
        final type = entry['type'] as String;
 
        // Date formatting for Firestore ID (yyyy-MM-dd)
        final dateId = DateFormat('yyyy-MM-dd').format(date);
 
        if (type == 'holiday' || type == 'chill') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              borderColor: type == 'holiday' ? Colors.purpleAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (type == 'holiday' ? Colors.purpleAccent : Colors.greenAccent).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(type == 'holiday' ? "☕" : "✨", style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(type == 'holiday' ? entry['reason'] : "Chill Day",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        if (type == 'chill')
                           const Text("No classes scheduled", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
 
        final item = entry['item'] as ScheduleItem;
 
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr,
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(item.courseCode,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text("${item.startTime} - ${item.endTime}",
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                if (item.isMakeup)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                        onPressed: () => _scheduleMakeup(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _deleteExceptionById(item.id),
                      ),
                    ],
                  )
                else if (item.isCancelled)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _scheduleMakeup(item),
                        icon: const Icon(Icons.edit_calendar,
                            size: 14, color: Colors.orangeAccent),
                        label: const Text("Makeup",
                            style: TextStyle(
                                color: Colors.orangeAccent, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orangeAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.undo, color: Colors.white54),
                        onPressed: () => _deleteExceptionById(item.id),
                        tooltip: "Undo Cancel",
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () => _cancelClass(dateId, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                    ),
                    child: const Text("Cancel"),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tab 2: List of user exceptions (Pending Actions)
  Widget _buildPendingActions() {
    if (_userExceptions.isEmpty) {
      return const Center(
          child: Text("No pending actions",
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userExceptions.length,
      itemBuilder: (context, index) {
        final ex = _userExceptions[index];
        final type = ex['type'] ?? 'cancel';
        final isCancel = type == 'cancel' || type == 'cancellation';
        final date = ex['date'] ?? '';
        final course = ex['course_code'] ?? ex['courseCode'] ?? '';
        final room = ex['room'] ?? '';
        final startTime = ex['start_time'] ?? ex['startTime'] ?? '';
 
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCancel
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : Colors.greenAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCancel ? Icons.cancel : Icons.event,
                    color: isCancel ? Colors.redAccent : Colors.greenAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isCancel ? "Class Cancellation" : "Makeup Class",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text("$course • $date",
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      if (!isCancel && startTime.isNotEmpty)
                        Text("Time: $startTime ${room.isNotEmpty ? '• Room: $room' : ''}",
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 20),
                      onPressed: () => _editMakeupFromPending(ex),
                      tooltip: isCancel ? "Assign Makeup" : "Edit Makeup",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white54, size: 20),
                      onPressed: () => _deleteException(ex),
                      tooltip: "Remove Action",
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final dt = DateFormat('h:mm a').parse(timeStr.trim());
      return TimeOfDay.fromDateTime(dt);
    } catch (_) {
      return null;
    }
  }

  Future<void> _editMakeupFromPending(Map<String, dynamic> ex) async {
    final id = ex['id']?.toString() ?? '';
    if (id.isEmpty) return;

    DateTime? initialDate;
    final dateStr = ex['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      } catch (_) {}
    }

    final initialTime = _parseTimeOfDay(ex['startTime']?.toString());

    final item = ScheduleItem(
      id: id,
      courseCode: ex['course_code'] ?? ex['courseCode'] ?? 'Unknown',
      courseName: ex['course_name'] ?? ex['courseName'] ?? (ex['courseCode'] ?? 'Makeup Class'),
      sessionType: 'Makeup',
      day: '',
      startTime: ex['start_time'] ?? ex['startTime'] ?? '',
      endTime: ex['end_time'] ?? ex['endTime'] ?? '',
      room: ex['room'] ?? 'TBA',
      faculty: '',
      isMakeup: true,
    );

    await _scheduleMakeup(item,
        initialDate: initialDate, initialTime: initialTime);
  }

  Future<void> _cancelClass(String dateStr, ScheduleItem item) async {
    try {
      if (!mounted) return;

      // Confirm dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text("Cancel Class?",
              style: TextStyle(color: Colors.white)),
          content: Text("Cancel ${item.courseCode} on $dateStr?",
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text("Yes", style: TextStyle(color: Colors.redAccent)),
            )
          ],
        ),
      );

      if (confirm == true) {
        await _exceptionRepo.addCancellation(dateStr, item.courseCode);
        if (mounted) {
          final isOnline = await ConnectivityService().isOnline();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isOnline
                  ? "Class cancelled successfully"
                  : "Offline: Cancellation saved locally")));
          _loadData(); // Refresh list
        }
      }
    } catch (e) {
      debugPrint("Error cancelling class: $e");
    }
  }

  Future<void> _deleteException(Map<String, dynamic> exception) async {
    final id = exception['id'] as String?;
    if (id != null) await _deleteExceptionById(id);
  }

  Future<void> _deleteExceptionById(String id) async {
    try {
      if (id.isEmpty) return;
      await _exceptionRepo.removeException(id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Action removed")));
        _loadData(); // Refresh
      }
    } catch (e) {
      debugPrint("Error deleting exception: $e");
    }
  }

  Future<void> _scheduleMakeup(ScheduleItem item,
      {DateTime? initialDate, TimeOfDay? initialTime}) async {
    if (!mounted) return;

    // 1. Pick Date
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now.add(const Duration(days: 1)),
      firstDate: initialDate != null && initialDate.isBefore(now)
          ? initialDate
          : now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          onPrimary: Colors.black,
          surface: Color(0xFF1A1A2E),
          onSurface: Colors.white,
        )),
        child: child!,
      ),
    );
    if (date == null) return;

    // 2. Pick Time
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          onPrimary: Colors.black,
          surface: Color(0xFF1A1A2E),
          onSurface: Colors.white,
        )),
        child: child!,
      ),
    );
    if (time == null) return;

    // 3. Enter Room & Confirm
    if (!mounted) return;
    final roomController = TextEditingController(text: item.room);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text("Makeup Details", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Scheduling makeup for ${item.courseCode}",
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: roomController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Room Number",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Schedule",
                style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Format times
      final startDt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      final endDt = startDt.add(const Duration(minutes: 90)); // Default 1.5h

      // Simple Format: HH:mm AM/PM
      String fmt(DateTime dt) {
        final h = dt.hour;
        final m = dt.minute;
        final suffix = h >= 12 ? "PM" : "AM";
        int oh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        final mStr = m.toString().padLeft(2, '0');
        return "$oh:$mStr $suffix";
      }

      if (item.isMakeup) {
        // Update existing
        await _exceptionRepo.updateMakeupClass(
          id: item.id,
          date: DateFormat('yyyy-MM-dd').format(date),
          startTime: fmt(startDt),
          endTime: fmt(endDt),
          room: roomController.text,
        );
      } else {
        // Add new
        await _exceptionRepo.addMakeupClass(
          date: DateFormat('yyyy-MM-dd').format(date),
          courseCode: item.courseCode,
          courseName: item.courseName,
          startTime: fmt(startDt),
          endTime: fmt(endDt),
          room: roomController.text,
        );
      }

      if (mounted) {
        final isOnline = await ConnectivityService().isOnline();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isOnline
                ? (item.isMakeup ? "Makeup details updated!" : "Makeup class scheduled!")
                : "Offline: Makeup saved locally")));
        _loadData();
      }
    }
  }
}
