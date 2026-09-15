import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ewumate/core/theme/ewu_theme_extension.dart';

class GradeScaleReferenceCard extends StatelessWidget {
  const GradeScaleReferenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    const scale = [
      ('A+', '4.00', '80% and above'),
      ('A', '3.75', '75% to 79%'),
      ('A-', '3.50', '70% to 74%'),
      ('B+', '3.25', '65% to 69%'),
      ('B', '3.00', '60% to 64%'),
      ('B-', '2.75', '55% to 59%'),
      ('C+', '2.50', '50% to 54%'),
      ('C', '2.25', '45% to 49%'),
      ('D', '2.00', '40% to 44%'),
      ('F', '0.00', 'Less than 40%'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Official EWU Grading Scale',
            style: GoogleFonts.sora(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...scale.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(row.$1, style: GoogleFonts.sora(color: colors.primaryCyan, fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                      const SizedBox(width: 12),
                      Text(row.$3, style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11)),
                    ],
                  ),
                  Text(row.$2, style: GoogleFonts.sora(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
