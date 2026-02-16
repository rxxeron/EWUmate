import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../../core/models/task_model.dart';
import '../../core/models/course_model.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/sky_animation.dart';
import '../../core/widgets/main_shell.dart';
import '../tasks/task_repository.dart';
import '../tasks/task_card.dart';
import '../tasks/task_editor_modal.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import 'dashboard_repository.dart';
import 'dashboard_logic.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSeeAllTasks;

  const DashboardScreen({super.key, this.onSeeAllTasks});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  final AcademicRepository _academicRepo = AcademicRepository();
  final TaskRepository _taskRepo = TaskRepository();
  final DashboardRepository _dashboardRepo = DashboardRepository();
  final CourseRepository _courseRepo = CourseRepository();

  User? get user => _supabase.auth.currentUser;
  String _semesterCode = "";
  bool _loadingInit = true;
  List<Task> _tasks = [];
  List<Course> _enrolledCourses = [];

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    if (user == null) return;
    try {
      final code = await _academicRepo.getCurrentSemesterCode();
      final tasks = await _taskRepo.fetchTasks();
      final userData = await _courseRepo.fetchUserData();
      final enrolledIds =
          List<String>.from(userData['enrolled_sections'] ?? []);
      List<Course> enrolled = [];
      if (enrolledIds.isNotEmpty) {
        enrolled = await _courseRepo.fetchCoursesByIds(
            code.replaceAll(' ', ''), enrolledIds);
      }

      if (mounted) {
        setState(() {
          _semesterCode = code.replaceAll(' ', '');
          _tasks = tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          _enrolledCourses = enrolled;
          _loadingInit = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing dashboard: $e");
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  Future<void> _refreshTasks() async {
    final tasks = await _taskRepo.fetchTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Please log in"));
    }

    if (_loadingInit) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildAppBar(),
          _buildHeader(),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _dashboardRepo.getScheduleStream(_semesterCode),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  );
                }

                final data = snapshot.data;
                debugPrint(
                    '[Dashboard] Cloud schedule keys: ${data?.keys.toList()}');
                debugPrint(
                    '[Dashboard] Holidays count: ${(data?['holidays'] as List?)?.length ?? 0}');
                final processed = DashboardLogic.getScheduleFromCloud(data);

                return RefreshIndicator(
                  onRefresh: () async {
                    await _initDashboard();
                  },
                  color: Colors.cyanAccent,
                  backgroundColor: const Color(0xFF1A1A2E),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildScheduleSection(processed),
                        const SizedBox(height: 30),
                        _buildTasksSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                );
              },
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
    String greeting = _getGreeting();
    String nickname =
        user?.userMetadata?['full_name']?.toString().split(' ').first ??
            "Student";

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      borderColor: Colors.cyanAccent.withValues(alpha: 0.3),
      child: Row(
        children: [
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
                      backgroundImage: user?.userMetadata?['avatar_url'] != null
                          ? NetworkImage(user!.userMetadata!['avatar_url']!)
                          : null,
                      child: user?.userMetadata?['avatar_url'] == null
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
                        "$greeting,",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 75, height: 75, child: SkyAnimationWidget()),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(Map<String, dynamic> data) {
    final status = data['status'];
    final reason = data['reason'] ?? "";
    final displayDate = data['displayDate'] ?? "";
    final schedule = data['schedule'] as List<ScheduleItem>? ?? [];
    final targetDate = data['targetDate'] as DateTime;

    final isTomorrow = targetDate.day != DateTime.now().day;
    final title = isTomorrow ? "Tomorrow's Schedule" : "Today's Schedule";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
            Text(
              displayDate,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (status == 'holiday' || status == 'chill')
          _buildHeroCard(
            "☕",
            "Chill Mode",
            reason.isNotEmpty ? reason : "No classes scheduled.",
            Colors.purpleAccent,
          )
        else if (schedule.isEmpty)
          _buildHeroCard(
            "✨",
            "All Clear",
            "No more classes for today.",
            Colors.greenAccent,
          )
        else
          ...schedule.map((item) => _buildScheduleCard(item)),
      ],
    );
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    final bool isLab = item.sessionType == 'Lab';
    Color accentColor = isLab ? Colors.orangeAccent : Colors.cyanAccent;
    String badgeText = item.sessionType;
    if (item.isMakeup) {
      accentColor = Colors.purpleAccent;
      badgeText = "MAKEUP";
    } else if (item.isCancelled) {
      accentColor = Colors.redAccent;
      badgeText = "CANCELLED";
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      opacity: item.isCancelled ? 0.05 : 0.1,
      borderColor: accentColor.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                _extractTimeNumber(item.startTime),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
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
                          decoration: item.isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                          decorationThickness: 2.5,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
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
                        fontSize: 14,
                        decoration: item.isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                        decorationThickness: 2.5,
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
                            fontWeight: FontWeight.w500,
                            decoration: item.isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                            decorationThickness: 2.5,
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
    );
  }

  Widget _buildTasksSection() {
    final upcomingTasks = _tasks.where((task) => !task.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Upcoming Tasks",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: widget.onSeeAllTasks ?? () => context.push('/tasks'),
              child: const Text(
                "See All",
                style: TextStyle(color: Colors.cyanAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (upcomingTasks.isEmpty)
          _buildHeroCard(
            Icons.task_alt,
            "All Done!",
            "No pending tasks.",
            Colors.blueAccent,
            iconMode: true,
          )
        else
          ...upcomingTasks.take(3).map(
                (t) => TaskCard(
                  task: t,
                  onTap: () => _showTaskEditor(t),
                  onStatusChange: (v) async {
                    await _taskRepo.toggleTaskCompletion(t.id, v);
                    _refreshTasks();
                  },
                  onDelete: () {}, // Optional
                ),
              ),
      ],
    );
  }

  Widget _buildHeroCard(
    dynamic iconInfo,
    String title,
    String subtitle,
    Color color, {
    bool iconMode = false,
  }) {
    return GlassContainer(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      opacity: 0.1,
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          if (iconMode)
            Icon(
              iconInfo as IconData,
              size: 40,
              color: color.withValues(alpha: 0.8),
            )
          else
            Text(iconInfo as String, style: const TextStyle(fontSize: 48)),
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

  void _showTaskEditor(Task item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskEditorModal(
        availableCourses: _enrolledCourses,
        taskToEdit: item,
        onTaskSaved: (t) => _refreshTasks(),
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
