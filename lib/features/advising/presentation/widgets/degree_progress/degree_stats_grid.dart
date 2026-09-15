import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';

class DegreeStatsGrid extends StatelessWidget {
  final double creditsCompleted;
  final double creditsRemaining;
  final int semestersCompleted;
  final int semestersLeft;

  const DegreeStatsGrid({
    super.key,
    required this.creditsCompleted,
    required this.creditsRemaining,
    required this.semestersCompleted,
    required this.semestersLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildStatTile(
                context: context,
                label: 'Credits Done',
                value: creditsCompleted.toStringAsFixed(1),
                icon: Icons.check_circle_rounded,
                accentColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildStatTile(
                context: context,
                label: 'Semesters Done',
                value: semestersCompleted.toString(),
                icon: Icons.calendar_month_rounded,
                accentColor: const Color(0xFFA855F7),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _buildStatTile(
                context: context,
                label: 'Credits Left',
                value: creditsRemaining.toStringAsFixed(1),
                icon: Icons.timelapse_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _buildStatTile(
                context: context,
                label: 'Semesters Left',
                value: '~$semestersLeft',
                icon: Icons.flag_rounded,
                accentColor: AppColors.primaryCyan,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    final colors = context.ewuColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
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
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.sora(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
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
    );
  }
}
