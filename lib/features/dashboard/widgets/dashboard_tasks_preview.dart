import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../hero_card.dart';

/// Clean, high-contrast task preview section for the Dashboard.
class DashboardTasksPreview extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final VoidCallback onSeeAll;
  final void Function(Map<String, dynamic> task) onTaskTap;

  const DashboardTasksPreview({
    super.key,
    required this.tasks,
    required this.onSeeAll,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final pendingTasks = tasks.where((t) {
      if ((t['is_completed'] ?? false) || (t['is_missed'] ?? false)) return false;
      return true;
    }).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Upcoming Tasks",
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.primaryText,
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                "See All",
                style: GoogleFonts.sora(
                  color: colors.primaryCyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (pendingTasks.isEmpty)
          HeroCard(
            iconInfo: Icons.task_alt_rounded,
            title: "All Done!",
            subtitle: "No pending tasks.",
            color: colors.secondarySoftBlue,
            iconMode: true,
          )
        else ...[
          ...pendingTasks.map((t) {
            final dueDateStr = t['due_date']?.toString();
            final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
            final formattedDue = dueDate != null
                ? DateFormat('MMM d, h:mm a').format(dueDate.toLocal())
                : 'No due date';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.7 : 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryCyan.withValues(alpha: colors.isDark ? 0.14 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.assignment_rounded, color: colors.primaryCyan, size: 20),
                  ),
                  title: Text(
                    t['title']?.toString() ?? 'Untitled Task',
                    style: GoogleFonts.sora(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "${t['course_code']?.toString() ?? 'General'} • $formattedDue",
                    style: GoogleFonts.sora(
                      color: colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.secondaryText),
                  onTap: () => onTaskTap(t),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
