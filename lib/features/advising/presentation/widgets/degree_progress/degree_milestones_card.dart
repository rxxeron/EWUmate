import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';

class DegreeMilestonesCard extends StatelessWidget {
  final double progressPercent;

  const DegreeMilestonesCard({
    super.key,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    final bool phase1Done = progressPercent >= 0.30;
    final bool phase2Done = progressPercent >= 0.75;
    final bool phase2Active = progressPercent >= 0.30 && !phase2Done;
    final bool phase3Active = phase2Done;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.borderSubtle,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Journey Milestones',
            style: GoogleFonts.sora(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildMilestoneRow(
            context: context,
            stepNumber: '1',
            title: 'Foundation & General Education',
            subtitle: 'Core Math, English & Science prerequisites',
            isCompleted: phase1Done,
            isActive: !phase1Done,
            isLast: false,
          ),
          _buildMilestoneRow(
            context: context,
            stepNumber: '2',
            title: 'Core Major Requirements',
            subtitle: 'Department major & advanced coursework',
            isCompleted: phase2Done,
            isActive: phase2Active,
            isLast: false,
          ),
          _buildMilestoneRow(
            context: context,
            stepNumber: '3',
            title: 'Capstone & Degree Completion',
            subtitle: 'Final project/thesis & elective credits',
            isCompleted: progressPercent >= 1.0,
            isActive: phase3Active,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final colors = context.ewuColors;

    Color stepColor;
    if (isCompleted) {
      stepColor = const Color(0xFF10B981);
    } else if (isActive) {
      stepColor = colors.primaryCyan;
    } else {
      stepColor = colors.secondaryText.withValues(alpha: 0.4);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : isActive
                        ? colors.primaryCyan.withValues(alpha: 0.20)
                        : colors.surfaceNavyBlue,
                border: Border.all(
                  color: stepColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Color(0xFF071426), size: 16)
                    : Text(
                        stepNumber,
                        style: GoogleFonts.sora(
                          color: isActive ? colors.primaryCyan : colors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                    : colors.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : colors.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: isCompleted || isActive
                        ? colors.textPrimary
                        : colors.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.sora(
                    color: colors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                if (!isLast) const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
