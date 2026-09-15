import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/widgets/animated_progress_ring.dart';

class GradeDistributionChart extends StatelessWidget {
  final Map<String, int> gradeCounts;
  final int totalCourses;

  const GradeDistributionChart({
    super.key,
    required this.gradeCounts,
    required this.totalCourses,
  });

  Color _getGradeColor(String grade, EwuColors colors) {
    if (grade.startsWith('A')) {
      return colors.primaryCyan;
    } else if (grade.startsWith('B')) {
      return const Color(0xFF10B981);
    } else if (grade.startsWith('C')) {
      return const Color(0xFFF59E0B);
    } else if (grade == 'D') {
      return const Color(0xFFF97316);
    } else {
      return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    const grades = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'F'];

    // Find max count to scale bar heights
    int maxCount = 1;
    for (final g in grades) {
      final c = gradeCounts[g] ?? 0;
      if (c > maxCount) maxCount = c;
    }

    final int failedCourses = gradeCounts['F'] ?? 0;
    final int passedCourses = totalCourses > 0 ? (totalCourses - failedCourses) : 0;
    final double passRate = totalCourses > 0 ? (passedCourses / totalCourses) : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.30)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primaryCyan.withValues(alpha: 0.12),
                      border: Border.all(
                        color: colors.primaryCyan.withValues(alpha: 0.28),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(Icons.bar_chart_rounded, color: colors.primaryCyan, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade Distribution',
                        style: GoogleFonts.sora(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Performance histogram across $totalCourses courses',
                        style: GoogleFonts.sora(
                          color: colors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main Content: Histogram + Pass Rate Gauge
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bars Histogram
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: grades.map((grade) {
                      final count = gradeCounts[grade] ?? 0;
                      final double ratio = maxCount > 0 ? (count / maxCount) : 0.0;
                      final barColor = _getGradeColor(grade, colors);
                      const double minHeight = 6.0;
                      final double calculatedHeight = (ratio * 90).clamp(minHeight, 90.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Count badge
                          Text(
                            count > 0 ? '$count' : '',
                            style: GoogleFonts.sora(
                              color: count > 0 ? barColor : Colors.transparent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Glowing vertical bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            width: 18,
                            height: calculatedHeight,
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? barColor
                                  : (colors.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: count > 0
                                  ? [
                                      BoxShadow(
                                        color: barColor.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Grade Letter
                          Text(
                            grade,
                            style: GoogleFonts.sora(
                              color: count > 0 ? colors.textPrimary : colors.secondaryText,
                              fontSize: 10,
                              fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // Circular Pass Rate Meter
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : colors.borderSubtle,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedProgressRing(
                          progress: passRate,
                          size: 68,
                          strokeWidth: 6,
                          activeColor: const Color(0xFF10B981),
                          backgroundColor: colors.isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFE2E8F0),
                        ),
                        Text(
                          '${(passRate * 100).toInt()}%',
                          style: GoogleFonts.sora(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pass Rate',
                      style: GoogleFonts.sora(
                        color: colors.secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
