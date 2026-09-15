import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/models/profile.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';
import '../../../../../core/widgets/animated_progress_ring.dart';

class DegreeHeroCard extends StatelessWidget {
  final Profile profile;
  final double earnedCredits;
  final double requiredCredits;
  final int coursesDone;
  final double progressPercent;
  final int displayPercent;
  final String programName;
  final String currentTrack;

  const DegreeHeroCard({
    super.key,
    required this.profile,
    required this.earnedCredits,
    required this.requiredCredits,
    required this.coursesDone,
    required this.progressPercent,
    required this.displayPercent,
    required this.programName,
    required this.currentTrack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (colors.isDark)
            BoxShadow(
              color: colors.primaryCyan.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          // Central Glowing Circular Gauge
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedProgressRing(
                progress: progressPercent,
                size: 154,
                strokeWidth: 12,
                activeColor: colors.primaryCyan,
                backgroundColor: colors.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE2E8F0),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primaryCyan.withValues(alpha: 0.14),
                      border: Border.all(
                        color: colors.primaryCyan.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: colors.primaryCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$displayPercent%',
                    style: GoogleFonts.sora(
                      color: colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Completed',
                    style: GoogleFonts.sora(
                      color: colors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Program Badge & Subtitle
          Text(
            programName,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primaryCyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.primaryCyan.withValues(alpha: 0.30),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  currentTrack,
                  style: GoogleFonts.sora(
                    color: colors.primaryCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Credit Progress Subtitle
          Text(
            coursesDone > 0
                ? '${earnedCredits.toStringAsFixed(1)} / ${requiredCredits.toStringAsFixed(0)} credits completed ($coursesDone courses)'
                : '${earnedCredits.toStringAsFixed(1)} / ${requiredCredits.toStringAsFixed(0)} credits completed',
            style: GoogleFonts.sora(
              color: colors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
