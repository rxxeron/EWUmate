import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';

class DegreeCgpaActionCard extends StatelessWidget {
  final double cgpa;

  const DegreeCgpaActionCard({
    super.key,
    required this.cgpa,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    String cgpaLabel = "Good Standing";
    Color labelColor = const Color(0xFF10B981);
    if (cgpa >= 3.8) {
      cgpaLabel = "Highest Distinction";
      labelColor = colors.primaryCyan;
    } else if (cgpa >= 3.5) {
      cgpaLabel = "Dean's List / Excellent";
      labelColor = const Color(0xFF10B981);
    } else if (cgpa < 2.5 && cgpa > 0) {
      cgpaLabel = "Academic Warning";
      labelColor = const Color(0xFFF43F5E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: labelColor.withValues(alpha: 0.30),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: labelColor.withValues(alpha: 0.15),
              border: Border.all(color: labelColor.withValues(alpha: 0.40), width: 1.2),
            ),
            alignment: Alignment.center,
            child: Text(
              cgpa.toStringAsFixed(2),
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cumulative CGPA',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cgpaLabel,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.emoji_events_rounded, color: labelColor, size: 28),
        ],
      ),
    );
  }
}

class DegreeSemesterSummaryLinkCard extends StatelessWidget {
  const DegreeSemesterSummaryLinkCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/semester-summary'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceNavyBlue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colors.borderSubtle,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primaryCyan.withValues(alpha: 0.28),
                    width: 0.8,
                  ),
                ),
                child: Icon(Icons.analytics_rounded, color: colors.primaryCyan, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester Analytics & Goals',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View grade analysis & scholarship tracking',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
