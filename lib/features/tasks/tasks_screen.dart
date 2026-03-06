import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'task_repository.dart';
import '../../core/models/task_model.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import '../../core/logic/exam_sync_logic.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/offline_cache_service.dart';

import 'task_card.dart';
import 'task_editor_modal.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/animations/loading_shimmer.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  final TaskRepository _taskRepo = TaskRepository();
  final CourseRepository _courseRepo = CourseRepository();
  final AcademicRepository _academicRepo = AcademicRepository();
  final ExamSyncLogic _examSyncLogic = ExamSyncLogic();

  List<Course> _enrolledCourses = [];
  bool _initializing = true;
  String _semesterCode = "";
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _initData();
    SyncService().performFullSync();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final userData = OfflineCacheService().getCachedAcademicProfile();
    List<String> enrolledIds = [];
    if (userData != null) {
      enrolledIds = ((userData['enrolled_sections'] as List?) ?? [])
          .map((e) => e.toString())
          .toList();
    }
    if (enrolledIds.isEmpty) return;

    List<Course> enrolled = [];
    for (var id in enrolledIds) {
      final data = OfflineCacheService().getCachedCourseDetails(id);
      if (data != null) enrolled.add(Course.fromSupabase(data, id));
    }

    if (enrolled.isNotEmpty && mounted) {
      setState(() {
        final uniqueCourses = <String, Course>{};
        for (var c in enrolled) {
          if (!uniqueCourses.containsKey(c.code)) uniqueCourses[c.code] = c;
        }
        _enrolledCourses = uniqueCourses.values.toList();
      });
    }
  }

  Future<void> _initData() async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    try {
      _semesterCode = await _academicRepo.getCurrentSemesterCode();
      final userData = await _courseRepo.fetchUserData();
      final enrolledIds = ((userData['enrolled_sections'] as List?) ?? [])
          .map((e) => e.toString())
          .toList();

      List<Course> enrolled = [];
      if (enrolledIds.isNotEmpty) {
        enrolled = await _courseRepo.fetchCoursesByIds(_semesterCode, enrolledIds);
      }

      final uniqueCourses = <String, Course>{};
      for (var c in enrolled) {
        if (!uniqueCourses.containsKey(c.code)) uniqueCourses[c.code] = c;
      }

      final tasks = await _taskRepo.fetchTasks();
      await _examSyncLogic.syncExams(enrolled, tasks, _semesterCode);

      if (mounted) {
        setState(() {
          _enrolledCourses = uniqueCourses.values.toList();
          _initializing = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing tasks: $e");
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        body: Column(
          children: [
            const EWUmateAppBar(title: "All Tasks", showMenu: true),
            TabBar(
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.cyanAccent,
              indicatorWeight: 3,
              dividerColor: Colors.white.withOpacity(0.05),
              tabs: [
                _buildTab("Upcoming", Colors.cyanAccent),
                _buildTab("Overdue", Colors.redAccent),
                _buildTab("Completed", Colors.greenAccent),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<Task>>(
                stream: _taskRepo.getTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _initializing) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 6,
                      itemBuilder: (_, __) => LoadingShimmer.listTile(margin: const EdgeInsets.only(bottom: 12)),
                    );
                  }

                  final tasks = snapshot.data ?? [];
                  final now = DateTime.now();

                  // Categorize
                  final overdue = tasks.where((t) => !t.isCompleted && !t.isMissed && t.dueDate.isBefore(now)).toList();
                  final upcoming = tasks.where((t) => !t.isCompleted && !t.isMissed && !t.dueDate.isBefore(now)).toList();
                  final completed = tasks.where((t) => t.isCompleted || t.isMissed).toList();

                  // Sort
                  overdue.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                  upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                  completed.sort((a, b) => b.dueDate.compareTo(a.dueDate));

                  return Stack(
                    children: [
                      TabBarView(
                        children: [
                          _buildTaskList(upcoming, "No upcoming tasks", Icons.upcoming),
                          _buildTaskList(overdue, "No overdue tasks", Icons.error_outline),
                          _buildTaskList(completed, "No completed tasks", Icons.check_circle_outline),
                        ],
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: FloatingActionButton.extended(
                          onPressed: () => _showTaskEditor(null),
                          backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                          ),
                          icon: const Icon(Icons.add, color: Colors.cyanAccent),
                          label: const Text("New Task", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, Color color) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          StreamBuilder<List<Task>>(
            stream: _taskRepo.getTasksStream(),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              final now = DateTime.now();
              int count = 0;
              if (label == "Upcoming") {
                count = tasks.where((t) => !t.isCompleted && !t.isMissed && !t.dueDate.isBefore(now)).length;
              } else if (label == "Overdue") {
                count = tasks.where((t) => !t.isCompleted && !t.isMissed && t.dueDate.isBefore(now)).length;
              } else {
                count = tasks.where((t) => t.isCompleted || t.isMissed).length;
              }

              if (count == 0) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> items, String emptyMessage, IconData emptyIcon) {
    if (items.isEmpty && !_initializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildTaskItem(items[index]),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key("task_${task.id}"),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete, color: Colors.redAccent),
        ),
        onDismissed: (_) => _taskRepo.deleteTask(task.id),
        child: TaskCard(
          task: task,
          onTap: () => _showTaskEditor(task),
          onStatusChange: (comp, miss) => _taskRepo.updateTaskStatus(task.id, isCompleted: comp, isMissed: miss),
        ),
      ),
    );
  }

  void _showTaskEditor(Task? task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskEditorModal(
        availableCourses: _enrolledCourses,
        taskToEdit: task,
        onTaskSaved: (_) => setState(() {}),
      ),
    );
  }
}
