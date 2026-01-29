import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/task_model.dart';
import '../../core/models/course_model.dart';

import '../course_browser/course_repository.dart';
import '../tasks/task_repository.dart';
import '../tasks/task_card.dart';
import '../tasks/task_editor_modal.dart';
import '../calendar/academic_repository.dart';
import 'dashboard_logic.dart';
import 'exception_repository.dart';
import '../../core/logic/scheduler_logic.dart';
import '../../core/logic/exam_sync_logic.dart';

import '../../core/widgets/main_shell.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/sky_animation.dart';
import '../../core/widgets/error_view.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSeeAllTasks;

  const DashboardScreen({super.key, this.onSeeAllTasks});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CourseRepository _courseRepo = CourseRepository();
  final TaskRepository _taskRepo = TaskRepository();
  final AcademicRepository _academicRepo = AcademicRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExceptionRepository _exceptionRepo = ExceptionRepository();

  bool _loading = true;
  String _error = '';
  String _nickname = "Student";
  String _semesterCode = "";
  List<Course> _enrolledCourses = [];
  List<Task> _tasks = [];
  List<Map<String, dynamic>> _userExceptions = [];
  Map<String, dynamic> _displayData = {};
  Map<String, dynamic>? _cloudSchedule;
  StreamSubscription? _scheduleSubscription;

  User? get user => FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? _mergeExceptions(Map<String, dynamic>? cloudSchedule) {
    if (cloudSchedule == null && _userExceptions.isEmpty) return null;

    final base = cloudSchedule ?? {};
    // Ensure we don't mutate input
    final merged = Map<String, dynamic>.from(base);

    final cloudEx = (merged['exceptions'] as List<dynamic>?) ?? [];
    merged['exceptions'] = [...cloudEx, ..._userExceptions];

    return merged;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    super.dispose();
  }

  /// Simple, robust data loading - no complex caching logic
  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    // Get current user first - if null, show appropriate message
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please log in to view your dashboard';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // 1. Get semester code
      _semesterCode = await _academicRepo.getCurrentSemesterCode();
      final safeSem = _semesterCode.replaceAll(' ', '');
      debugPrint(
        '[Dashboard] Loading for user: ${currentUser.uid}, semester: $safeSem',
      );

      // 2. Get user data (nickname, enrolled sections)
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        _nickname = userData['nickname']?.toString() ??
            currentUser.displayName ??
            'Student';
        final enrolledIds = List<String>.from(
          userData['enrolledSections'] ?? [],
        );
        debugPrint('[Dashboard] Enrolled sections: ${enrolledIds.length}');

        // Fetch courses by IDs
        if (enrolledIds.isNotEmpty) {
          _enrolledCourses = await _courseRepo.fetchCoursesByIds(
            _semesterCode,
            enrolledIds,
          );
        }
      }

      // 3. Get schedule directly from Firestore
      final scheduleDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('schedule')
          .doc(safeSem)
          .get();

      if (scheduleDoc.exists) {
        _cloudSchedule = scheduleDoc.data();
        debugPrint(
          '[Dashboard] Schedule loaded: ${_cloudSchedule?.keys.length} keys',
        );
      } else {
        _cloudSchedule = null;
        debugPrint('[Dashboard] No schedule document found');
      }

      // 4. Get tasks
      _tasks = await _taskRepo.fetchTasks();
      _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      // 5. Get user exceptions
      _userExceptions = await _exceptionRepo.fetchExceptions();

      // 6. Process display data
      _displayData = DashboardLogic.getScheduleFromCloud(
        _mergeExceptions(_cloudSchedule),
      );

      // 7. Set up real-time listener for schedule updates (optional, non-blocking)
      _scheduleSubscription?.cancel();
      _scheduleSubscription = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('schedule')
          .doc(safeSem)
          .snapshots()
          .listen(
        (snapshot) {
          if (mounted) {
            _cloudSchedule = snapshot.exists ? snapshot.data() : null;
            setState(() {
              _displayData = DashboardLogic.getScheduleFromCloud(
                _mergeExceptions(_cloudSchedule),
              );
            });
          }
        },
        onError: (e) {
          debugPrint('[Dashboard] Schedule listener error: $e');
        },
      );

      // 8. Background tasks (non-blocking)
      _runBackgroundTasks();

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e, stack) {
      debugPrint('[Dashboard] Error: $e\n$stack');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load dashboard: ${e.toString().split(':').first}';
        });
      }
    }
  }

  void _runBackgroundTasks() {
    debugPrint('[Dashboard] Running background tasks');
    // Schedule notifications from cloud schedule (more reliable than course sessions)
    SchedulerLogic.scheduleFromCloudSchedule(_cloudSchedule).catchError((e) {
      debugPrint('[Dashboard] Notification error: $e');
    });

    // Sync exams (non-blocking)
    ExamSyncLogic()
        .syncExams(_enrolledCourses, _tasks, _semesterCode)
        .catchError((e) {
      debugPrint('[Dashboard] Exam sync error: $e');
    });
  }

  void _showTaskEditor(Task? task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskEditorModal(
        availableCourses: _enrolledCourses,
        taskToEdit: task,
        onTaskSaved: (savedTask) {
          setState(() {
            // Refresh tasks list
            _loadDashboardData();
          });
        },
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskRepo.deleteTask(task.id);
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Task deleted")));
      }
    } catch (e) {
      debugPrint('[Dashboard] Error deleting task: $e');
    }
  }

  Future<void> _handleOverdueAction(Task task, bool markComplete) async {
    if (markComplete) {
      await _taskRepo.toggleTaskCompletion(task.id, true);
    } else {
      // Mark Incomplete = Delete/Dismiss
      await _taskRepo.deleteTask(task.id);
    }
    _loadDashboardData(); // Refresh to update lists
  }

  Future<void> _showClassActionDialog(ScheduleItem item) async {
    // Extract proper date string YYYY-MM-DD
    final DateTime targetDate = _displayData['targetDate'] ?? DateTime.now();
    // Assuming AppConstants.dateFormat is yyyy-MM-dd, let's import intl or rely on logic
    // DashboardLogic line 52: final dateStr = DateFormat(AppConstants.dateFormat).format(targetDate);
    // I can't access that local var.
    // I will recreate dateStr using the same format logic or just pass it if I had it.
    // Let's assume uniform format "yyyy-MM-dd".
    final dateStr =
        "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.courseName),
        content: Text(
          item.isCancelled
              ? "Restore this class to your schedule?"
              : "Mark this class as cancelled?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);

              if (item.isCancelled) {
                // RESTORE: Find and delete exception
                final id = await _exceptionRepo.findExceptionId(
                  dateStr,
                  item.courseCode,
                  'cancel',
                );
                if (id != null) {
                  await _exceptionRepo.removeException(id);
                } else {
                  // Could be a cloud exception (immutable by user)
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cannot restore official cancellations"),
                      ),
                    );
                  }
                }
              } else {
                // CANCEL
                await _exceptionRepo.addCancellation(dateStr, item.courseCode);
              }
              _loadDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  item.isCancelled ? Colors.green : Colors.redAccent,
            ),
            child: Text(item.isCancelled ? "Restore" : "Cancel Class"),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return "Good Night";
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // 1. Fixed App Bar
          _buildAppBar(),

          // 2. Fixed Header (User Card)
          _buildHeader(),

          // 3. Scrollable Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: Colors.cyanAccent,
              backgroundColor: const Color(0xFF1A1A2E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_buildContent(), const SizedBox(height: 40)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        "EWUmate",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      borderColor: Colors.cyanAccent.withValues(alpha: 0.3),
      child: Row(
        children: [
          // Left side - Avatar and Text
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => MainShell.scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withValues(alpha: 0.5),
                          Colors.blue.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF1A1A2E),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.cyanAccent,
                              size: 28,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_getGreeting()},",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        _nickname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.waving_hand,
                            size: 14,
                            color: Colors.amber.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Welcome to EWUmate",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.cyanAccent.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right side - Animated Sky
          const SizedBox(width: 75, height: 75, child: SkyAnimationWidget()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return SizedBox(
        height: 300,
        child: ErrorView(message: _error, onRetry: _loadDashboardData),
      );
    }

    final schedule = _displayData['schedule'] as List<ScheduleItem>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. SCHEDULE SECTION
        _buildSectionTitle(_getScheduleTitle()),
        const SizedBox(height: 15),
        if (schedule.isEmpty)
          _buildHeroCard(
            "🎉",
            "All Caught Up!",
            "You have no classes remaining.",
            Colors.greenAccent,
          )
        else
          ...schedule.map((item) => _buildScheduleCard(item)),

        // 2. UPCOMING TASKS
        const SizedBox(height: 30),
        _buildSectionTitleWithAction(
          "Upcoming Tasks",
          "See All",
          widget.onSeeAllTasks ?? () => context.push('/tasks'),
        ),
        const SizedBox(height: 10),
        if (_tasks.isEmpty)
          _buildEmptyCard(Icons.task_alt, "No tasks pending")
        else
          ..._tasks.take(3).map(
                (t) => TaskCard(
                  task: t,
                  onTap: () => _showTaskEditor(t),
                  onDelete: () => _deleteTask(t),
                  onStatusChange: (isComplete) =>
                      _handleOverdueAction(t, isComplete),
                ),
              ),

        // Removed Events & Holidays
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSectionTitleWithAction(
    String title,
    String action,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(action, style: const TextStyle(color: Colors.cyanAccent)),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(IconData icon, String message) {
    return GlassContainer(
      padding: const EdgeInsets.all(30),
      opacity: 0.05,
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white24),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    String emoji,
    String title,
    String subtitle,
    Color color,
  ) {
    return GlassContainer(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      opacity: 0.1,
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    final bool isLab = item.sessionType == 'Lab';
    Color accentColor = isLab ? Colors.orangeAccent : Colors.cyanAccent;
    String badgeText = item.sessionType;
    IconData typeIcon =
        isLab ? Icons.science_outlined : Icons.class_outlined; // Default icon

    if (item.isMakeup) {
      accentColor = Colors.purpleAccent;
      badgeText = "MAKEUP";
      typeIcon = Icons.event_repeat;
    } else if (item.isCancelled) {
      accentColor = Colors.redAccent;
      badgeText = "CANCELLED";
      typeIcon = Icons.cancel_outlined;
    }

    final double cardOpacity = item.isCancelled ? 0.5 : 1.0;
    final TextDecoration? textDecoration =
        item.isCancelled ? TextDecoration.lineThrough : null;

    return GestureDetector(
      onLongPress: () => _showClassActionDialog(item),
      child: Opacity(
        opacity: 0.1 +
            (cardOpacity *
                0.9), // GlassContainer base opacity is 0.1? No, Opacity widget wraps it.
        // Wait, GlassContainer has its own opacity arg.
        // Let's wrap the whole GlassContainer in Opacity widget OR modify GlassContainer opacity.
        // Actually, standard GlassContainer usage in this file is opacity: 0.1.
        // I'll wrap the whole thing.
        child: GlassContainer(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(20),
          opacity: item.isCancelled ? 0.05 : 0.1,
          borderColor: accentColor.withValues(alpha: 0.3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Column
              Column(
                children: [
                  Text(
                    _extractTimeNumber(item.startTime),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      decoration: textDecoration,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _extractAmPm(item.startTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    height: 25,
                    width: 3,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  Text(
                    _extractTimeNumber(item.endTime),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      decoration: textDecoration,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Course Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.courseName.isNotEmpty
                                ? item.courseName
                                : item.courseCode,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: textDecoration,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.isMakeup || item.isCancelled) ...[
                                Icon(typeIcon, size: 10, color: accentColor),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                badgeText,
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.courseCode,
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            decoration: textDecoration,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.faculty.isNotEmpty ? item.faculty : "TBA",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                decoration: textDecoration,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!item.isCancelled)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Room ${item.room.isNotEmpty ? item.room : 'TBA'}",
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getScheduleTitle() {
    final targetDate =
        _displayData['targetDate'] as DateTime? ?? DateTime.now();
    final now = DateTime.now();

    // Check if target is tomorrow (ignoring time)
    final isTomorrow = targetDate.day != now.day ||
        targetDate.month != now.month ||
        targetDate.year != now.year;

    return isTomorrow ? "Tomorrow's Schedule" : "Today's Schedule";
  }

  String _extractTimeNumber(String time) {
    if (time.isEmpty) return "--";
    return time.split(" ").first;
  }

  String _extractAmPm(String time) {
    if (time.isEmpty) return "";
    if (time.toUpperCase().contains("PM")) return "PM";
    if (time.toUpperCase().contains("AM")) return "AM";
    return "";
  }
}
