import 'package:flutter/material.dart';
import 'task_repository.dart';
import '../../core/models/task_model.dart';
import '../../core/models/course_model.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import 'task_card.dart';
import 'task_editor_modal.dart';
import '../../core/widgets/glass_kit.dart';
// End of imports

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  final TaskRepository _taskRepo = TaskRepository();
  final CourseRepository _courseRepo = CourseRepository();
  final AcademicRepository _academicRepo = AcademicRepository();

  bool _loading = true;
  String _error = '';
  List<Task> _tasks = [];
  List<Course> _enrolledCourses = [];

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  /// Simple, direct data loading - no caching
  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // 1. Fetch tasks directly from Firestore
      final tasks = await _taskRepo.fetchTasks();
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      // 2. Get semester code
      final semesterCode = await _academicRepo.getCurrentSemesterCode();
      debugPrint('[TasksScreen] Semester: $semesterCode');

      // 3. Fetch user data for enrolled sections
      final userData = await _courseRepo.fetchUserData();
      final enrolledIds = List<String>.from(userData['enrolledSections'] ?? []);
      debugPrint('[TasksScreen] Enrolled IDs: ${enrolledIds.length}');

      // 4. Fetch courses by document IDs
      List<Course> enrolled = [];
      if (enrolledIds.isNotEmpty) {
        enrolled = await _courseRepo.fetchCoursesByIds(
          semesterCode,
          enrolledIds,
        );
      }
      debugPrint('[TasksScreen] Fetched ${enrolled.length} courses');

      // 5. Deduplicate courses for dropdown
      final uniqueCourses = <String, Course>{};
      for (var c in enrolled) {
        if (!uniqueCourses.containsKey(c.code)) {
          uniqueCourses[c.code] = c;
        }
      }

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _enrolledCourses = uniqueCourses.values.toList();
          _loading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[TasksScreen] Error: $e\n$stack');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load tasks: ${e.toString().split(':').first}';
        });
      }
    }
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
            // Check if it's an update or new
            final idx = _tasks.indexWhere((t) => t.id == savedTask.id);
            if (idx != -1) {
              _tasks[idx] = savedTask;
            } else {
              _tasks.add(savedTask);
            }
            _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          });
        },
      ),
    );
  }

  Future<void> _toggleTaskComplete(Task task) async {
    try {
      await _taskRepo.toggleTaskCompletion(task.id, !task.isCompleted);
      setState(() {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          _tasks[idx] = Task(
            id: task.id,
            courseCode: task.courseCode,
            courseName: task.courseName,
            title: task.title,
            assignDate: task.assignDate,
            type: task.type,
            submissionType: task.submissionType,
            dueDate: task.dueDate,
            isCompleted: !task.isCompleted,
          );
        }
      });
    } catch (e) {
      debugPrint('[TasksScreen] Error toggling task: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${task.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskRepo.deleteTask(task.id);
        setState(() {
          _tasks.removeWhere((t) => t.id == task.id);
        });
      } catch (e) {
        debugPrint('[TasksScreen] Error deleting task: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: refreshData,
            color: Colors.cyanAccent,
            backgroundColor: const Color(0xFF1A1A2E),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [_buildAppBar(), _buildContent()],
            ),
          ),
          _buildFAB(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      title: const Text(
        "All Tasks",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      automaticallyImplyLeading: false,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.cyanAccent),
          onPressed: () => _showTaskEditor(null),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(_error, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: refreshData,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.task_alt, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                "No upcoming tasks",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                width: null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                borderRadius: 12,
                borderColor: Colors.cyanAccent.withValues(alpha: 0.5),
                onTap: () => _showTaskEditor(null),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.cyanAccent),
                    SizedBox(width: 8),
                    Text(
                      "Add Your First Task",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group tasks by status (upcoming vs completed)
    final upcomingTasks = _tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = _tasks.where((t) => t.isCompleted).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (upcomingTasks.isNotEmpty) ...[
            _buildSectionHeader("Upcoming", upcomingTasks.length),
            const SizedBox(height: 12),
            ...upcomingTasks.map((task) => _buildTaskCard(task)),
          ],
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader("Completed", completedTasks.length),
            const SizedBox(height: 12),
            ...completedTasks.map((task) => _buildTaskCard(task)),
          ],
          const SizedBox(height: 80), // Space for FAB
        ]),
      ),
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

  Widget _buildTaskCard(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      confirmDismiss: (direction) async {
        await _deleteTask(task);
        return false; // We handle deletion ourselves
      },
      child: GestureDetector(
        onTap: () => _toggleTaskComplete(task),
        child: TaskCard(
          task: task,
          onTap: () => _showTaskEditor(task),
          onDelete: () => _deleteTask(task),
          onStatusChange: (isComplete) => _toggleTaskComplete(task),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: FloatingActionButton.extended(
        onPressed: () => _showTaskEditor(null),
        backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.5)),
        ),
        icon: const Icon(Icons.add_task, color: Colors.cyanAccent),
        label: const Text(
          "New Task",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
