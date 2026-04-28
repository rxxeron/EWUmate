import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/task.dart';
import '../../../../core/repositories/task_repository.dart';
import '../../../../core/widgets/ewumate_app_bar.dart';
import 'widgets/add_task_bottom_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: EWUmateAppBar(
        title: "My Tasks",
        showMenu: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.cyanAccent),
            onPressed: () => _openTaskModal(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorColor: const Color(0xFF22D3EE),
          labelColor: const Color(0xFF22D3EE),
          unselectedLabelColor: Colors.white.withOpacity(0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Overdue"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: tasksAsync.when(
        data: (allTasks) {
          final now = DateTime.now();
          final upcomingTasks = <Task>[];
          final overdueTasks = <Task>[];
          final completedTasks = <Task>[];

          for (final task in allTasks) {
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
              _buildTaskList("Upcoming", upcomingTasks),
              _buildTaskList("Overdue", overdueTasks),
              _buildTaskList("Completed", completedTasks),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0891B2).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => _openTaskModal(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildTaskList(String type, List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 60, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              "No $type tasks found",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isOverdue = type == "Overdue";
        final isCompleted = type == "Completed";

        String dateSubtitle = "No due date";
        if (task.dueDate != null) {
          dateSubtitle = "Due: ${DateFormat('MMM d, yyyy - h:mm a').format(task.dueDate!.toLocal())}";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(isCompleted ? 0.3 : 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(isCompleted ? 0.04 : 0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => _openTaskModal(existingTask: task),
            leading: Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: task.isCompleted,
                activeColor: const Color(0xFF22D3EE),
                checkColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                side: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                onChanged: (val) async {
                  if (val != null) {
                    await ref.read(taskRepositoryProvider).updateTaskStatus(task.id, val);
                    ref.invalidate(allTasksStreamProvider);
                  }
                },
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                color: isCompleted ? Colors.white.withOpacity(0.4) : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white.withOpacity(0.4),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.courseCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.courseCode!,
                        style: const TextStyle(
                          color: Color(0xFF22D3EE),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded, 
                        size: 12, 
                        color: isOverdue ? const Color(0xFFF43F5E) : Colors.white.withOpacity(0.4)
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateSubtitle,
                        style: TextStyle(
                          color: isOverdue ? const Color(0xFFF43F5E) : Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: isOverdue ? FontWeight.w900 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.3)),
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18, color: Colors.white70),
                      SizedBox(width: 12),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF43F5E)),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Color(0xFFF43F5E))),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  _openTaskModal(existingTask: task);
                } else if (value == 'delete') {
                  await ref.read(taskRepositoryProvider).deleteTask(task.id);
                  ref.invalidate(allTasksStreamProvider);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
