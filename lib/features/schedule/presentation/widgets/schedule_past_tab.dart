import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/task.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primitives/ewu_empty_state.dart';
import '../../../dashboard/dashboard_logic.dart';
import '../../../dashboard/schedule_card.dart';

class SchedulePastTab extends StatelessWidget {
  final List<Map<String, dynamic>> twoWeekSchedule;
  final List<Task> allTasks;
  final void Function(ScheduleItem item, String dateStr) onDeleteClass;
  final void Function(ScheduleItem item, String dateStr) onCancelClass;

  const SchedulePastTab({
    super.key,
    required this.twoWeekSchedule,
    required this.allTasks,
    required this.onDeleteClass,
    required this.onCancelClass,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pastDays = twoWeekSchedule.where((day) {
      final date = day['date'] as DateTime;
      return date.isBefore(today);
    }).toList()..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (pastDays.isEmpty) {
      return const Center(
        child: EwuEmptyState(
          icon: Icons.history_toggle_off_rounded,
          title: "No Past Sessions",
          subtitle: "No previous classes recorded for this period.",
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: pastDays.length,
      itemBuilder: (ctx, idx) {
        final day = pastDays[idx];
        final isHoliday = day['isHoliday'] == true;
        final holidayReason = day['holidayReason']?.toString() ?? '';
        final events = List<Map<String, dynamic>>.from(day['events'] ?? []);
        final classes = day['classes'] as List<ScheduleItem>? ?? [];
        final dateStr = day['dateStr'] as String;
        final dateRaw = day['date'];
        final DateTime dateVal = dateRaw is String
            ? (DateTime.tryParse(dateRaw) ?? DateTime.now())
            : (dateRaw as DateTime? ?? DateTime.now());
        final headerStr = DateFormat('EEEE - MMMM d').format(dateVal);

        List<Widget> children = [
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 10),
            child: Text(
              headerStr,
              style: GoogleFonts.sora(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ];

        if (isHoliday) {
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.celebration_rounded, color: Colors.purpleAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      holidayReason,
                      style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        for (var ev in events) {
          final title = (ev['title'] ?? ev['name'] ?? '').toString();
          if (title.toLowerCase() == holidayReason.toLowerCase()) continue;
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondarySoftBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoftBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event_note_rounded, color: AppColors.secondarySoftBlue, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final dTime = dateVal;
        final currentDayTasks = allTasks.where((t) {
          if (t.dueDate == null) return false;
          final isSameDay = t.dueDate!.year == dTime.year &&
              t.dueDate!.month == dTime.month &&
              t.dueDate!.day == dTime.day;
          return isSameDay && !t.isCompleted;
        }).toList();

        for (final task in currentDayTasks) {
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_rounded, color: Colors.orangeAccent, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.courseCode != null ? "${task.courseCode}: ${task.title}" : task.title,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        for (int i = 0; i < classes.length; i++) {
          final c = classes[i];
          children.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScheduleCard(
                  item: c,
                  compact: true,
                  trailing: c.isCancelled
                      ? null
                      : (c.isManual || c.isMakeup)
                          ? TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => onDeleteClass(c, dateStr),
                              child: Text(
                                'Delete',
                                style: GoogleFonts.sora(
                                  color: const Color(0xFFF43F5E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => onCancelClass(c, dateStr),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.sora(
                                  color: const Color(0xFFF43F5E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                ),
              ],
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
      },
    );
  }
}
