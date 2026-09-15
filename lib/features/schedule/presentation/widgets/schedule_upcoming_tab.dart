import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/task.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/course_utils.dart';
import '../../../../core/widgets/primitives/ewu_empty_state.dart';
import '../../../dashboard/dashboard_logic.dart';
import '../../../dashboard/schedule_card.dart';
class ScheduleUpcomingTab extends StatelessWidget {
  final String semCode;
  final List<Task> allTasks;
  final List<Map<String, dynamic>> twoWeekSchedule;
  final DateTime? selectedScheduleDate;
  final ValueChanged<DateTime>? onDateSelected;
  final VoidCallback onSyncRoutine;
  final void Function(ScheduleItem item, String dateStr) onDeleteClass;
  final void Function(ScheduleItem item, String dateStr) onCancelClass;

  const ScheduleUpcomingTab({
    super.key,
    required this.semCode,
    required this.allTasks,
    required this.twoWeekSchedule,
    this.selectedScheduleDate,
    this.onDateSelected,
    required this.onSyncRoutine,
    required this.onDeleteClass,
    required this.onCancelClass,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingDays = twoWeekSchedule.where((day) {
      final date = day['date'] as DateTime;
      return !date.isBefore(today);
    }).toList();

    if (upcomingDays.isEmpty) {
      return Center(
        child: EwuEmptyState(
          icon: Icons.calendar_today_rounded,
          title: "No Upcoming Sessions",
          subtitle: "No classes scheduled for semester $semCode",
          ctaLabel: "Sync Routine",
          onCtaPressed: onSyncRoutine,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: upcomingDays.length,
      itemBuilder: (ctx, idx) {
                    final day = upcomingDays[idx];
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
                    final isToday = dateVal.year == now.year && dateVal.month == now.month && dateVal.day == now.day;

                    List<Widget> children = [
                      Padding(
                        padding: const EdgeInsets.only(top: 22, bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              headerStr,
                              style: GoogleFonts.sora(
                                color: isToday ? AppColors.primaryCyan : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  "TODAY",
                                  style: GoogleFonts.sora(
                                    color: AppColors.primaryCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
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
                            border: Border.all(color: AppColors.secondarySoftBlue.withValues(alpha: 0.25)),
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
                            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.25)),
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
                      bool hasConflict = false;

                      for (int j = 0; j < classes.length; j++) {
                        if (i == j) continue;
                        final other = classes[j];
                        final startA = CourseUtils.parseTimeToDouble(c.startTime);
                        final endA = CourseUtils.parseTimeToDouble(c.endTime);
                        final startB = CourseUtils.parseTimeToDouble(other.startTime);
                        final endB = CourseUtils.parseTimeToDouble(other.endTime);

                        if (startA < endB && startB < endA) {
                          hasConflict = true;
                          break;
                        }
                      }

                      children.add(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasConflict)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 15),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Time Conflict Detected',
                                      style: GoogleFonts.sora(
                                        color: Colors.orangeAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
