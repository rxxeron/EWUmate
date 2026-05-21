import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../../core/models/task.dart';
import '../../../core/repositories/task_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/utils/error_utils.dart';
import 'widgets/add_task_bottom_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _offlineHeartbeat;

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
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              AuthErrorUtils.getFriendlyMessage(err),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
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
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allTasksStreamProvider);
        await _pushSyncQueue();
      },
      color: Colors.cyanAccent,
      backgroundColor: const Color(0xFF1E293B),
      child: tasks.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
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
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      try {
                        await ref.read(taskRepositoryProvider).updateTaskStatus(user.id, task.id, val);
                        ref.invalidate(allTasksStreamProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
                          );
                        }
                      }
                    }
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
                  final user = ref.read(currentUserProvider);
                  if (user != null) {
                    try {
                      await ref.read(taskRepositoryProvider).deleteTask(user.id, task.id);
                      ref.invalidate(allTasksStreamProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ),
        );
      },
    ),
  );
}
}
