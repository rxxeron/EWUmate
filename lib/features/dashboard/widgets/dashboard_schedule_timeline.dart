import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/utils/date_utils.dart' as date_util;
import '../../../core/utils/time_utils.dart';
import '../dashboard_logic.dart';
import '../hero_card.dart';
import '../schedule_card.dart';
import 'next_class_card.dart';

class DashboardScheduleTimeline extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onScheduleManagerTap;
  final void Function(ScheduleItem item) onMarkAttendance;

  const DashboardScheduleTimeline({
    super.key,
    required this.data,
    required this.onScheduleManagerTap,
    required this.onMarkAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final status = data['status'];
    final reason = data['reason'] ?? "";
    final schedule = (data['schedule'] as List?)?.cast<ScheduleItem>() ?? [];
    final targetDateRaw = data['targetDate'] ?? data['date'];
    final DateTime? targetDate = targetDateRaw is String
        ? DateTime.tryParse(targetDateRaw)
        : targetDateRaw as DateTime?;

    final isToday = targetDate != null && date_util.DateUtils.isToday(targetDate);
    final isTomorrow = targetDate != null && date_util.DateUtils.isTomorrow(targetDate);

    String title = targetDate != null ? DateFormat('EEEE').format(targetDate) : "Schedule";
    if (isToday) title = "Today's Schedule";
    if (isTomorrow) title = "Tomorrow's Schedule";

    final displayDate = targetDate != null ? DateFormat('EEEE, MMM d').format(targetDate) : "";

    // Hero NextClassCard should only be shown for an upcoming or ongoing active class (never cancelled)
    final upcomingActiveClasses = schedule.where((item) {
      if (item.isCancelled) return false;
      if (isToday) {
        final now = DateTime.now();
        final currentMins = now.hour * 60 + now.minute;
        final endMins = TimeUtils.parseTime(item.endTime);
        return currentMins < endMins;
      }
      return true;
    }).toList();

    final ScheduleItem? candidate = data['next_class'] as ScheduleItem? ?? upcomingActiveClasses.firstOrNull;
    final nextClassItem = (candidate != null && !candidate.isCancelled) ? candidate : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nextClassItem != null && status != 'holiday') ...[
          NextClassCard(
            item: nextClassItem,
            isToday: isToday,
            targetDate: targetDate,
            onMarkAttendance: () => onMarkAttendance(nextClassItem),
            onOpenMap: onScheduleManagerTap,
            onViewDetails: onScheduleManagerTap,
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.primaryText,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              displayDate,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (status == 'holiday') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  const Color(0xFFD97706).withValues(alpha: 0.08),
                  colors.surfaceNavyBlue.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    size: 38,
                    color: Color(0xFFFBBF24),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "CAMPUS CLOSED",
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFBBF24),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reason.isNotEmpty ? reason : "University Holiday",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "No regular classes scheduled today. Relax, unwind & recharge! ✨",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (schedule.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Scheduled Makeup Classes",
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.primaryCyan,
              ),
            ),
            const SizedBox(height: 8),
            ...schedule.map((item) => ScheduleCard(item: item)),
          ],
        ]
        else if (status == 'chill')
          HeroCard(
            iconInfo: Icons.self_improvement_rounded,
            title: "Chill Mode",
            subtitle: reason.isNotEmpty ? reason : "No classes scheduled.",
            color: colors.secondarySoftBlue,
            iconMode: true,
          )
        else if (schedule.isEmpty)
          HeroCard(
            iconInfo: Icons.done_all_rounded,
            title: isToday ? "All Clear" : "Nothing Found",
            subtitle: isToday ? "No more classes for today." : "No classes scheduled for this day.",
            color: colors.primaryCyan,
            iconMode: true,
          )
        else
          ...schedule.map((item) => ScheduleCard(item: item)),
      ],
    );
  }
}
