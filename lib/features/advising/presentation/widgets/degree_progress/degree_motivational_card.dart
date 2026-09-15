import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';

class DegreeMotivationalCard extends StatelessWidget {
  const DegreeMotivationalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Color(0xFFF59E0B),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Small progress each day adds up to big results.',
              style: GoogleFonts.sora(
                color: colors.textPrimary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
