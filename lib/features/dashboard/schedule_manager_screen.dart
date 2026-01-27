import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_logic.dart';
import 'exception_repository.dart';
import '../../core/widgets/glass_kit.dart';
import '../../features/calendar/academic_repository.dart';

/// Rebuilt Manager Screen - No Caching, Direct Firestore
class ScheduleManagerScreen extends StatefulWidget {
  const ScheduleManagerScreen({super.key});

  @override
  State<ScheduleManagerScreen> createState() => _ScheduleManagerScreenState();
}

class _ScheduleManagerScreenState extends State<ScheduleManagerScreen> {
  final ExceptionRepository _exceptionRepo = ExceptionRepository();
  final AcademicRepository _academicRepo = AcademicRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  Map<String, dynamic>? _cloudSchedule;
  List<Map<String, dynamic>> _userExceptions = [];
  String _semesterCode = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load data directly from Firestore without caching
  Future<void> _loadData() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.pop(); // Exit if not logged in
      return;
    }

    setState(() => _loading = true);
    try {
      // 1. Get Semester
      _semesterCode = await _academicRepo.getCurrentSemesterCode();
      final safeSem = _semesterCode.replaceAll(' ', '');

      // 2. Fetch Schedule directly
      final scheduleDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('schedule')
          .doc(safeSem)
          .get();

      // 3. Fetch Exceptions directly (repo might cache, but we call fetch)
      // Assuming exceptionRepo uses Firestore mainly
      final exceptions = await _exceptionRepo.fetchExceptions();

      if (mounted) {
        setState(() {
          _cloudSchedule = scheduleDoc.data();
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text("Manage Schedule",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent))
                : TabBarView(
                    children: [
                      _buildUpcomingClasses(),
                      _buildPendingActions(),
                    ],
                  ),
          ),
        ),
      ),
    );
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
    // Generate next 14 days of classes
    // We'll just generate the list
    final List<Map<String, dynamic>> upcomingList = [];

    // Helper to format date
    final dateFormat = DateFormat('EEE, MMM d');

    for (int i = 0; i < 14; i++) {
      final date = today.add(Duration(days: i));
      final result = DashboardLogic.getScheduleForDate(merged, date);
      final status = result['status'];
      final classes = result['schedule'] as List<ScheduleItem>;

      if (status == 'normal' && classes.isNotEmpty) {
        for (var item in classes) {
          upcomingList.add({
            'date': date,
            'dateStr': dateFormat.format(date),
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
        final item = entry['item'] as ScheduleItem;

        // Date formatting for Firestore ID (yyyy-MM-dd)
        final dateId = DateFormat('yyyy-MM-dd').format(date);

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
        final type = ex['type'] ?? 'cancellation';
        final date = ex['date'] ?? '';
        final course = ex['courseCode'] ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: type == 'cancellation'
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : Colors.greenAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'cancellation' ? Icons.cancel : Icons.event,
                    color: type == 'cancellation'
                        ? Colors.redAccent
                        : Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          type == 'cancellation'
                              ? "Cancellation"
                              : "Makeup Class",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text("$course • $date",
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white54),
                  onPressed: () => _deleteException(ex),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Class cancelled successfully")));
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

  Future<void> _scheduleMakeup(ScheduleItem item) async {
    if (!mounted) return;

    // 1. Pick Date
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
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
      initialTime: const TimeOfDay(hour: 10, minute: 0),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(item.isMakeup
                ? "Makeup details updated!"
                : "Makeup class scheduled!")));
        _loadData();
      }
    }
  }
}
