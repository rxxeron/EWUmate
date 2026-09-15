import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/task.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/task_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/widgets/primitives/ewu_empty_state.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';
import 'widgets/add_task_bottom_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _offlineHeartbeat;

  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Quiz', 'Lab', 'Assignment', 'Project'];
  final Set<String> _animatingTaskIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Heartbeat every 2 minutes
    _offlineHeartbeat = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        ref.invalidate(allTasksStreamProvider);
        _pushSyncQueue();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.tasksKey,
          steps: OnboardingSteps.tasks,
        );
      }
    });
  }

  Future<void> _pushSyncQueue() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final cacheService = ref.read(cacheServiceProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    final queue = cacheService.getSyncQueue(user.id);
    if (queue.isEmpty) return;

    if (kDebugMode) debugPrint('[Offline Sync] Processing ${queue.length} items from tasks screen...');
    bool anySuccess = false;

    for (final item in queue) {
      final action = item['action'];
      try {
        if (action == 'update_task_status') {
          await taskRepo.updateTaskStatus(user.id, item['taskId'], item['isCompleted']);
        } else if (action == 'delete_task') {
          await taskRepo.deleteTask(user.id, item['taskId']);
        } else if (action == 'create_task') {
          await taskRepo.createTask(user.id, Task.fromJson(item['task']));
        } else if (action == 'update_task') {
          await taskRepo.updateTask(user.id, Task.fromJson(item['task']));
        }

        // Remove from queue after success
        if (item.containsKey('taskId')) {
          await cacheService.removeQueueItem(user.id, item['taskId']);
        } else if (item.containsKey('task')) {
          await cacheService.removeQueueItem(user.id, item['task']['id']);
        }
        anySuccess = true;
      } catch (e) {
        if (kDebugMode) debugPrint('[Offline Sync] Still offline for action $action');
      }
    }

    if (anySuccess) {
      ref.invalidate(allTasksStreamProvider);
    }
  }

  @override
  void dispose() {
    _offlineHeartbeat?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _openTaskModal({Task? existingTask}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTaskBottomSheet(existingTask: existingTask),
      ),
    );
  }

  bool _matchesCategory(Task task, String category) {
    if (category == 'All') return true;
    final type = task.type?.toLowerCase() ?? '';
    final title = task.title.toLowerCase();
    final catLower = category.toLowerCase();

    if (catLower == 'quiz') {
      return type.contains('quiz') || title.contains('quiz');
    } else if (catLower == 'lab') {
      return type.contains('lab') || title.contains('lab');
    } else if (catLower == 'assignment') {
      return type.contains('assignment') || type.contains('paper') || title.contains('assignment');
    } else if (catLower == 'project') {
      return type.contains('project') || title.contains('project');
    }
    return type.contains(catLower) || title.contains(catLower);
  }

  Future<void> _toggleTask(Task task) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _animatingTaskIds.add(task.id);
    });

    try {
      final newStatus = !task.isCompleted;
      await ref.read(taskRepositoryProvider).updateTaskStatus(user.id, task.id, newStatus);
      ref.invalidate(allTasksStreamProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _animatingTaskIds.remove(task.id);
            });
          }
        });
      }
    }
  }

  Map<String, List<Task>> _groupUpcomingTasks(List<Task> tasks) {
    final now = DateTime.now();
    final startOfThisWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
    final endOfThisWeek = startOfThisWeek.add(const Duration(days: 7));
    final endOfNextWeek = endOfThisWeek.add(const Duration(days: 7));

    final thisWeek = <Task>[];
    final nextWeek = <Task>[];
    final later = <Task>[];

    for (final task in tasks) {
      if (task.dueDate == null) {
        later.add(task);
      } else {
        final due = task.dueDate!.toLocal();
        if (due.isBefore(endOfThisWeek)) {
          thisWeek.add(task);
        } else if (due.isBefore(endOfNextWeek)) {
          nextWeek.add(task);
        } else {
          later.add(task);
        }
      }
    }

    final result = <String, List<Task>>{};
    if (thisWeek.isNotEmpty) result['This Week'] = thisWeek;
    if (nextWeek.isNotEmpty) result['Next Week'] = nextWeek;
    if (later.isNotEmpty) result['Later'] = later;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final tasksAsync = ref.watch(allTasksStreamProvider);

    return FullGradientScaffold(
      appBar: EWUmateAppBar(
        title: "My Tasks",
        showMenu: true,
        actions: [
          GestureDetector(
            onTap: () => _openTaskModal(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.primaryCyan,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primaryCyan.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, color: colors.primaryNavy, size: 22),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.borderSubtle,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: colors.primaryCyan,
              labelColor: colors.primaryCyan,
              unselectedLabelColor: colors.textSecondary,
              labelStyle: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: GoogleFonts.sora(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "Upcoming"),
                Tab(text: "Overdue"),
                Tab(text: "Completed"),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 14),
          _buildCategoryFilterRow(colors),
          const SizedBox(height: 8),
          Expanded(
            child: tasksAsync.when(
              data: (allTasks) {
                final now = DateTime.now();
                final filteredAll = allTasks.where((t) => _matchesCategory(t, _selectedCategory)).toList();

                final upcomingTasks = <Task>[];
                final overdueTasks = <Task>[];
                final completedTasks = <Task>[];

                for (final task in filteredAll) {
                  if (task.isCompleted) {
                    completedTasks.add(task);
                  } else {
                    if (task.dueDate == null) {
                      upcomingTasks.add(task);
                    } else if (task.dueDate!.isBefore(now)) {
                      overdueTasks.add(task);
                    } else {
                      upcomingTasks.add(task);
                    }
                  }
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUpcomingTab(upcomingTasks),
                    _buildFlatTab("Overdue", overdueTasks, isOverdue: true),
                    _buildFlatTab("Completed", completedTasks, isCompleted: true),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.primaryCyan),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    AuthErrorUtils.getFriendlyMessage(err),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(color: colors.accentAlert),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: colors.primaryCyan,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.primaryCyan.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => _openTaskModal(),
          child: Icon(Icons.add_rounded, color: colors.primaryNavy, size: 28),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow(EwuColors colors) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryCyan : colors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? colors.primaryCyan : colors.borderSubtle,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.primaryCyan.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: GoogleFonts.sora(
                    color: isSelected ? colors.primaryNavy : colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader(String title, int count) {
    final colors = context.ewuColors;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '$count ${count == 1 ? "task" : "tasks"}',
            style: GoogleFonts.sora(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab(List<Task> tasks) {
    final colors = context.ewuColors;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allTasksStreamProvider);
        await _pushSyncQueue();
      },
      color: colors.primaryCyan,
      backgroundColor: colors.surfaceNavyBlue,
      child: tasks.isEmpty
          ? _buildEmptyState("No upcoming tasks found")
          : Builder(
              builder: (context) {
                final groups = _groupUpcomingTasks(tasks);
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    for (final entry in groups.entries) ...[
                      _buildGroupHeader(entry.key, entry.value.length),
                      for (final task in entry.value)
                        _buildTaskCard(task, isOverdue: false, isCompleted: false),
                    ],
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildFlatTab(String type, List<Task> tasks, {bool isOverdue = false, bool isCompleted = false}) {
    final colors = context.ewuColors;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allTasksStreamProvider);
        await _pushSyncQueue();
      },
      color: colors.primaryCyan,
      backgroundColor: colors.surfaceNavyBlue,
      child: tasks.isEmpty
          ? _buildEmptyState("No $type tasks found")
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildGroupHeader(type == "Overdue" ? "Overdue Tasks" : "Completed Tasks", tasks.length),
                for (final task in tasks)
                  _buildTaskCard(task, isOverdue: isOverdue, isCompleted: isCompleted),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: EwuEmptyState(
        icon: Icons.task_alt_rounded,
        title: message,
        subtitle: "Stay ahead of your coursework and deadlines",
        ctaLabel: "Add New Task",
        onCtaPressed: () => _openTaskModal(),
      ),
    );
  }

  Widget _buildTaskCard(Task task, {required bool isOverdue, required bool isCompleted}) {
    final colors = context.ewuColors;
    String dateSubtitle = "No due date";
    if (task.dueDate != null) {
      dateSubtitle = DateFormat('EEE, MMM d · h:mm a').format(task.dueDate!.toLocal());
    }

    final isAnimating = _animatingTaskIds.contains(task.id);
    final badgeInfo = _getBadgeInfo(task.type, task.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? colors.borderSubtle.withValues(alpha: 0.5)
              : colors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openTaskModal(existingTask: task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Custom Checkbox with animated scale & glow
                GestureDetector(
                  onTap: () => _toggleTask(task),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedScale(
                    scale: isAnimating ? 1.25 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? colors.primaryCyan
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: task.isCompleted
                              ? colors.primaryCyan
                              : colors.textTertiary,
                          width: 2,
                        ),
                        boxShadow: task.isCompleted
                            ? [
                                BoxShadow(
                                  color: colors.primaryCyan.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: task.isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colors.primaryNavy,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Course Code, and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.sora(
                          color: task.isCompleted
                              ? colors.textTertiary
                              : colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: colors.textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (task.courseCode != null && task.courseCode!.isNotEmpty) ...[
                            Text(
                              task.courseCode!,
                              style: GoogleFonts.sora(
                                color: colors.secondarySoftBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                "•",
                                style: GoogleFonts.sora(
                                  color: colors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              dateSubtitle,
                              style: GoogleFonts.sora(
                                color: isOverdue ? colors.accentAlert : colors.textSecondary,
                                fontSize: 12,
                                fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Category Badge Pill
                if (badgeInfo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeInfo.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeInfo.textColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      badgeInfo.label,
                      style: GoogleFonts.sora(
                        color: badgeInfo.textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                // 3-dots popup menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.textTertiary,
                    size: 20,
                  ),
                  color: colors.surfaceNavyBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.borderSubtle),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: colors.textSecondary),
                          const SizedBox(width: 10),
                          Text('Edit', style: GoogleFonts.sora(color: colors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: colors.accentAlert),
                          const SizedBox(width: 10),
                          Text('Delete', style: GoogleFonts.sora(color: colors.accentAlert, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _openTaskModal(existingTask: task);
                    } else if (value == 'delete') {
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        try {
                          await ref.read(taskRepositoryProvider).deleteTask(user.id, task.id);
                          ref.invalidate(allTasksStreamProvider);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
                            );
                          }
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _BadgeInfo? _getBadgeInfo(String? type, String title) {
    final t = (type ?? '').toLowerCase();
    final tit = title.toLowerCase();

    if (t.contains('quiz') || tit.contains('quiz')) {
      return const _BadgeInfo(label: 'Quiz', bg: Color(0xFF142B47), textColor: Color(0xFF38BDF8));
    } else if (t.contains('lab') || tit.contains('lab')) {
      return const _BadgeInfo(label: 'Lab', bg: Color(0xFF12362C), textColor: Color(0xFF34D399));
    } else if (t.contains('assignment') || t.contains('paper') || tit.contains('assignment')) {
      return const _BadgeInfo(label: 'Assignment', bg: Color(0xFF3A2C12), textColor: Color(0xFFFBBF24));
    } else if (t.contains('project') || tit.contains('project')) {
      return const _BadgeInfo(label: 'Project', bg: Color(0xFF361424), textColor: Color(0xFFF43F5E));
    } else if (t.contains('exam') || tit.contains('mid') || tit.contains('final')) {
      return const _BadgeInfo(label: 'Exam', bg: Color(0xFF2A1845), textColor: Color(0xFFC084FC));
    }
    if (type != null && type.isNotEmpty) {
      return _BadgeInfo(label: type, bg: const Color(0xFF1C2E4A), textColor: const Color(0xFF94A3B8));
    }
    return null;
  }
}

class _BadgeInfo {
  final String label;
  final Color bg;
  final Color textColor;
  const _BadgeInfo({required this.label, required this.bg, required this.textColor});
}
