import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/models/task_model.dart';
import '../../core/widgets/glass_kit.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  /// Callback for status changes: (isCompleted, isMissed)
  final Function(bool, bool)? onStatusChange; 

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isLate = now.isAfter(task.dueDate) && !task.isCompleted && !task.isMissed;
    final Color typeColor = _getTypeColor(task.type);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      opacity: 0.08,
      borderColor: Colors.white.withValues(alpha: 0.1),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Icon Box
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getTypeIcon(task.type), color: typeColor),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLate)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
                              child: const Text("LATE",
                                  style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${task.courseCode} • ${task.submissionType.name.toUpperCase()}",
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: isLate ? Colors.redAccent : Colors.cyanAccent),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, h:mm a').format(task.dueDate),
                            style: TextStyle(
                                color: isLate ? Colors.redAccent : Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                // Status / Action Button
                if (task.isCompleted)
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onStatusChange?.call(false, false); // Mark Incomplete
                    },
                  )
                else if (task.isMissed)
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onStatusChange?.call(false, false); // Mark Incomplete
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.circle_outlined, color: Colors.white24),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onStatusChange?.call(true, false); // Mark Complete
                    },
                  ),
              ],
            ),

            // Overdue Actions
            if (isLate) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showIncompleteOptions(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text("Mark Incomplete"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onStatusChange?.call(true, false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text("Mark Complete"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showIncompleteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Task Incomplete",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            ListTile(
              leading: const Icon(Icons.edit_calendar, color: Colors.cyanAccent),
              title: const Text("Ask for Extension", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Update the due date", style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                onTap?.call();
              },
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.redAccent),
              title: const Text("Mark as Missed", style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text("Keep in history as missed", style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                onStatusChange?.call(false, true); // (Completed=false, Missed=true)
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(TaskType type) {
    switch (type) {
      case TaskType.quiz: return Colors.orange;
      case TaskType.viva: return Colors.purple;
      case TaskType.presentation: return Colors.blue;
      case TaskType.assignment: return Colors.green;
      case TaskType.labReport: return Colors.cyan;
      case TaskType.midTerm: return Colors.redAccent;
      case TaskType.finalExam: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.quiz: return Icons.quiz;
      case TaskType.viva: return Icons.mic;
      case TaskType.presentation: return Icons.slideshow;
      case TaskType.assignment: return Icons.assignment;
      case TaskType.labReport: return Icons.biotech_rounded;
      case TaskType.midTerm: return Icons.assignment_late;
      case TaskType.finalExam: return Icons.assignment_turned_in;
      default: return Icons.task;
    }
  }
}
