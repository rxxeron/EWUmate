import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/ewu_theme_extension.dart';
import '../../../../core/widgets/animated_progress_ring.dart';

class CourseProgressSummaryCard extends StatelessWidget {
  final double obtained;
  final double total;
  final String grade;

  const CourseProgressSummaryCard({
    super.key,
    required this.obtained,
    required this.total,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final double ratio = total > 0 ? (obtained / total).clamp(0.0, 1.0) : 0.0;
    final double pct = ratio * 100;

    Color gradeColor;
    if (pct >= 80) {
      gradeColor = colors.primaryCyan;
    } else if (pct >= 65) {
      gradeColor = const Color(0xFF10B981);
    } else if (pct >= 50) {
      gradeColor = const Color(0xFFF59E0B);
    } else {
      gradeColor = const Color(0xFFEF4444);
    }

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
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (colors.isDark)
            BoxShadow(
              color: colors.primaryCyan.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          // Circular Progress Gauge
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedProgressRing(
                progress: ratio,
                size: 130,
                strokeWidth: 11,
                activeColor: gradeColor,
                backgroundColor: colors.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE2E8F0),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: GoogleFonts.sora(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: gradeColor.withValues(alpha: 0.40),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      grade,
                      style: GoogleFonts.sora(
                        color: gradeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Flanking 3 Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem(
                context,
                obtained.toStringAsFixed(1),
                'Obtained',
                gradeColor,
              ),
              Container(
                width: 1,
                height: 28,
                color: colors.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : colors.borderSubtle,
              ),
              _buildSummaryItem(
                context,
                total.toStringAsFixed(0),
                'Total Outline',
                colors.textPrimary,
              ),
              Container(
                width: 1,
                height: 28,
                color: colors.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : colors.borderSubtle,
              ),
              _buildSummaryItem(
                context,
                (total - obtained).clamp(0, 100).toStringAsFixed(1),
                'Remaining',
                colors.secondaryText,
              ),
            ],
          ),

          // Motivational Academic Insight Card
          _buildEncouragementCard(context, ratio, grade),
        ],
      ),
    );
  }

  Widget _buildEncouragementCard(BuildContext context, double ratio, String grade) {
    final colors = context.ewuColors;
    String message;
    IconData icon;
    Color accent;
    if (ratio >= 0.75) {
      message = "Exceptional performance! You are well positioned for an $grade grade.";
      icon = Icons.emoji_events_rounded;
      accent = const Color(0xFF10B981);
    } else if (ratio >= 0.55) {
      message = "Consistent progress. Target upcoming quizzes and midterms to secure your target grade.";
      icon = Icons.trending_up_rounded;
      accent = colors.primaryCyan;
    } else {
      message = "Focus on upcoming evaluations and review weak areas to recover marks.";
      icon = Icons.lightbulb_rounded;
      accent = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.sora(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String value, String label, Color valueColor) {
    final colors = context.ewuColors;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.sora(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.sora(
            color: colors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
