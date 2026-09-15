import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/ewu_theme_extension.dart';

/// Horizontal calendar weekday selector strip matching Figma routine UI.
class ScheduleDaySelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<String> daysWithClasses; // Format: 'yyyy-MM-dd'

  const ScheduleDaySelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysWithClasses = const {},
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate 14 days starting from 2 days before today up to 12 days ahead
    final days = List.generate(14, (i) => today.subtract(const Duration(days: 2)).add(Duration(days: i)));

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;
          final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
          final dateKey = DateFormat('yyyy-MM-dd').format(day);
          final hasClasses = daysWithClasses.contains(dateKey);

          return _DayPill(
            day: day,
            isSelected: isSelected,
            isToday: isToday,
            hasClasses: hasClasses,
            onTap: () {
              HapticFeedback.selectionClick();
              onDateSelected(day);
            },
          );
        },
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool hasClasses;
  final VoidCallback onTap;

  const _DayPill({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasClasses,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final weekdayName = DateFormat('EEE').format(day);
    final dayNum = day.day.toString();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryCyan
              : (isToday
                  ? colors.primaryCyan.withValues(alpha: colors.isDark ? 0.15 : 0.10)
                  : colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.6 : 0.9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.primaryCyan
                : (isToday ? colors.primaryCyan.withValues(alpha: 0.4) : colors.borderSubtle),
            width: isSelected || isToday ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primaryCyan.withValues(alpha: colors.isDark ? 0.35 : 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekdayName.toUpperCase(),
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? (colors.isDark ? colors.primaryNavy : Colors.white)
                    : colors.secondaryText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNum,
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? (colors.isDark ? colors.primaryNavy : Colors.white)
                    : colors.primaryText,
              ),
            ),
            const SizedBox(height: 3),
            // Class dot indicator
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasClasses
                    ? (isSelected
                        ? (colors.isDark ? colors.primaryNavy : Colors.white)
                        : colors.primaryCyan)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
