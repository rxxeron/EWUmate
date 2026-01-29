import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/task_model.dart';
import '../../core/widgets/glass_kit.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(bool)?
      onStatusChange; // true = complete, false = dismiss/delete

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onDelete,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final isLate = DateTime.now().isAfter(task.dueDate) && !task.isCompleted;
    final Color typeColor = _getTypeColor(task.type);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      opacity:
          0.08, // Slightly more transparent than default 0.1 if needed, or stick to 0.1
      borderColor: Colors.white.withValues(alpha: 0.1),
      onTap: onTap,
      onLongPress: onDelete != null ? () => _showDeleteMenu(context) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // 1. Icon Box
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

                // 2. Info
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white), // Ensure white text
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLate)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.red[
                                      50], // Might look bright on glass? sticking to existing
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text("LATE",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${task.courseCode} • ${task.submissionType.name.toUpperCase()}",
                        style: const TextStyle(
                            color: Colors
                                .white70, // Explicitly white70 instead of grey[600]
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14,
                              color: isLate
                                  ? Colors.redAccent
                                  : Colors
                                      .cyanAccent), // indigo -> cyanAccent for dark theme
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, h:mm a').format(task.dueDate),
                            style: TextStyle(
                                color: isLate
                                    ? Colors.redAccent
                                    : Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                // 3. Status
                if (task.isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),

            // 4. Overdue Actions
            if (isLate && !task.isCompleted) ...[
              const SizedBox(height: 16),
              Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1)), // Styled divider
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onStatusChange?.call(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text("Mark Incomplete"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onStatusChange?.call(true),
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

  void _showDeleteMenu(BuildContext context) async {
    final result = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(
        100,
        100,
        0,
        0,
      ), // Position doesn't matter much as it adjusts to tap usually, but needed for API
      items: const [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Delete Task', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );

    if (result == 'delete') {
      onDelete?.call();
    }
  }

  Color _getTypeColor(TaskType type) {
    switch (type) {
      case TaskType.quiz:
        return Colors.orange;
      case TaskType.viva:
        return Colors.purple;
      case TaskType.presentation:
        return Colors.blue;
      case TaskType.assignment:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.quiz:
        return Icons.quiz;
      case TaskType.viva:
        return Icons.mic;
      case TaskType.presentation:
        return Icons.slideshow;
      case TaskType.assignment:
        return Icons.assignment;
      default:
        return Icons.task;
    }
  }
}
