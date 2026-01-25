import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'task_repository.dart';
import '../../core/models/task_model.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import '../../core/logic/exam_sync_logic.dart';

import 'task_card.dart';
import 'task_editor_modal.dart';

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

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void refreshData() {
    _initData();
  }

  Future<void> _initData() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      _semesterCode = await _academicRepo.getCurrentSemesterCode();
      final userData = await _courseRepo.fetchUserData();
      final enrolledIds = List<String>.from(userData['enrolledSections'] ?? []);

      List<Course> enrolled = [];
      if (enrolledIds.isNotEmpty) {
        enrolled = await _courseRepo.fetchCoursesByIds(
          _semesterCode,
          enrolledIds,
        );
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in"));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: Colors.transparent),
            StreamBuilder<List<Task>>(
              stream: _taskRepo.getTasksStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _initializing) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final tasks = snapshot.data ?? [];
                tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

                final upcoming = tasks.where((t) => !t.isCompleted).toList();
                final completed = tasks.where((t) => t.isCompleted).toList();

                return CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    if (tasks.isEmpty && !_initializing)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.task_alt,
                                size: 64,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No tasks yet",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      if (upcoming.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          sliver: SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              "Upcoming",
                              upcoming.length,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildTaskItem(upcoming[i]),
                              childCount: upcoming.length,
                            ),
                          ),
                        ),
                      ],
                      if (completed.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                          sliver: SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              "Completed",
                              completed.length,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildTaskItem(completed[i]),
                              childCount: completed.length,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () => _showTaskEditor(null),
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.cyanAccent),
                label: const Text(
                  "New Task",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      title: Text(
        "All Tasks",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: false,
      automaticallyImplyLeading: false,
      floating: true,
      pinned: true,
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.redAccent),
        ),
        confirmDismiss: (dir) async {
          return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text(
                "Delete Task?",
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                "Are you sure you want to delete '${task.title}'?",
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                TextButton(
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onPressed: () {
                    _taskRepo.deleteTask(task.id);
                    Navigator.pop(ctx, true);
                  },
                ),
              ],
            ),
          );
        },
        child: TaskCard(
          task: task,
          onTap: () => _showTaskEditor(task),
          onStatusChange: (val) {
            _taskRepo.toggleTaskCompletion(task.id, val);
          },
          onDelete: () {},
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
        onTaskSaved: (savedTask) {
          if (task == null) {
            _taskRepo.addTask(savedTask);
          } else {
            _taskRepo.updateTask(savedTask);
          }
        },
      ),
    );
  }
}
