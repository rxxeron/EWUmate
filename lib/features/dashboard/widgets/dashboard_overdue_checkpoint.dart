import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ewu_theme_extension.dart';

/// Interactive overdue task decision checkpoint widget.
class DashboardOverdueCheckpoint extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  final ValueChanged<String> onComplete;
  final ValueChanged<String> onMiss;
  final ValueChanged<Map<String, dynamic>> onReschedule;

  const DashboardOverdueCheckpoint({
    super.key,
    required this.tasks,
    required this.onComplete,
    required this.onMiss,
    required this.onReschedule,
  });

  @override
  State<DashboardOverdueCheckpoint> createState() => _DashboardOverdueCheckpointState();
}

class _DashboardOverdueCheckpointState extends State<DashboardOverdueCheckpoint> {
  final Set<String> _reschedulePromptIds = {};

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overdueTasks = widget.tasks.where((t) {
      if ((t['is_completed'] ?? false) || (t['is_missed'] ?? false)) return false;
      final dueDate = DateTime.tryParse(t['due_date']?.toString() ?? '');
      return dueDate != null && dueDate.isBefore(now);
    }).toList();

    if (overdueTasks.isEmpty) return const SizedBox.shrink();

    final colors = context.ewuColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.history_toggle_off_rounded, color: Colors.orangeAccent),
              const SizedBox(width: 10),
              Text(
                "Task Checkpoint",
                style: GoogleFonts.sora(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryText,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        ...overdueTasks.map((task) => _buildDecisionCard(context, task, colors)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDecisionCard(BuildContext context, Map<String, dynamic> task, EwuColors colors) {
    final taskId = task['id']?.toString() ?? '';
    final isPromptingReschedule = _reschedulePromptIds.contains(taskId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPromptingReschedule
              ? Colors.orangeAccent.withValues(alpha: 0.4)
              : colors.borderSubtle,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: isPromptingReschedule
            ? Column(
                key: ValueKey('prompt_$taskId'),
                children: [
                  Text(
                    "Want to reschedule this task for another time?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => _reschedulePromptIds.remove(taskId));
                          widget.onMiss(taskId);
                        },
                        child: Text(
                          "No, hide it",
                          style: GoogleFonts.sora(
                            color: colors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => widget.onReschedule(task),
                        child: Text(
                          "Yes, Reschedule",
                          style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                key: ValueKey('decision_$taskId'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high_rounded, color: Colors.orangeAccent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title']?.toString() ?? 'Untitled Task',
                              style: GoogleFonts.sora(
                                color: colors.primaryText,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Deadline has passed. What happened?",
                              style: GoogleFonts.sora(
                                color: colors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            setState(() => _reschedulePromptIds.add(taskId));
                          },
                          child: Text(
                            "Missed",
                            style: GoogleFonts.sora(color: Colors.redAccent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => widget.onComplete(taskId),
                          child: Text(
                            "Completed",
                            style: GoogleFonts.sora(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
