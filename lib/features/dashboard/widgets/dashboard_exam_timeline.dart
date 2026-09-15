import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ewu_theme_extension.dart';

class DashboardExamTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final void Function(Map<String, dynamic> exam) onExamTap;

  const DashboardExamTimeline({
    super.key,
    required this.tasks,
    required this.onExamTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final fiveDaysFromNow = todayStart.add(const Duration(days: 5));

    final upcomingExams = tasks.where((t) {
      if ((t['is_completed'] ?? false) || (t['is_missed'] ?? false)) return false;
      final type = t['type']?.toString() ?? '';
      if (type != 'Midterm' && type != 'Final Exam') return false;
      final dueDate = DateTime.tryParse(t['due_date']?.toString() ?? '');
      return dueDate != null && dueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) && dueDate.isBefore(fiveDaysFromNow);
    }).toList();

    if (upcomingExams.isEmpty) return const SizedBox.shrink();

    final colors = context.ewuColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.av_timer_rounded, color: Color(0xFFF43F5E), size: 20),
            const SizedBox(width: 8),
            Text(
              "Exam Timeline",
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.primaryText,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...upcomingExams.map((exam) {
          final dueDate = (DateTime.tryParse(exam['due_date']?.toString() ?? '') ?? DateTime.now()).toLocal();
          final diff = dueDate.difference(DateTime.now());
          final String countdown;
          if (diff.inDays > 0) {
            countdown = "In ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}";
          } else if (diff.inHours > 0) {
            countdown = "In ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}";
          } else if (diff.inMinutes > 0) {
            countdown = "In ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}";
          } else {
            countdown = "Today";
          }

          final isFinal = exam['type'] == 'Final Exam';
          final color = isFinal ? Colors.pinkAccent : Colors.orangeAccent;
          final label = isFinal ? "FINAL EXAM" : "MIDTERM";

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.75 : 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: InkWell(
              onTap: () => onExamTap(exam),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.assignment_late_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.sora(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          exam['course_code']?.toString() ?? 'Course',
                          style: GoogleFonts.sora(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          exam['title']?.toString() ?? '',
                          style: GoogleFonts.sora(
                            color: colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      countdown,
                      style: GoogleFonts.sora(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}
