import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/widgets/primitives/ewu_surface_card.dart';

class AssessmentCategoryItem {
  final String title;
  final double obtained;
  final double max;
  final IconData? icon;

  const AssessmentCategoryItem({
    required this.title,
    required this.obtained,
    required this.max,
    this.icon,
  });

  double get ratio => max > 0 ? (obtained / max).clamp(0.0, 1.0) : 0.0;
  double get percentage => ratio * 100;
}

class CourseAssessmentBars extends StatelessWidget {
  final List<AssessmentCategoryItem> items;

  const CourseAssessmentBars({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final activeItems = items.where((i) => i.max > 0).toList();

    if (activeItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return EwuSurfaceCard(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primaryCyan.withValues(alpha: colors.isDark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bar_chart_rounded, color: colors.primaryCyan, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assessment Breakdown',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryText,
                    ),
                  ),
                  Text(
                    'Performance across current evaluations',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: colors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...activeItems.map((item) => _buildBar(context, item)),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, AssessmentCategoryItem item) {
    final colors = context.ewuColors;
    final pct = item.percentage;

    // Determine performance color
    Color barColor;
    if (pct >= 80) {
      barColor = const Color(0xFF10B981); // Emerald
    } else if (pct >= 65) {
      barColor = colors.primaryCyan;
    } else if (pct >= 50) {
      barColor = const Color(0xFFF59E0B); // Amber
    } else {
      barColor = const Color(0xFFEF4444); // Red
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.title,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryText,
                ),
              ),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.sora(fontSize: 12),
                  children: [
                    TextSpan(
                      text: item.obtained.toStringAsFixed(item.obtained.truncateToDouble() == item.obtained ? 0 : 1),
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w800,
                        color: barColor,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${item.max.toStringAsFixed(0)}',
                      style: GoogleFonts.sora(
                        color: colors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Stack(
            children: [
              Container(
                height: 7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: item.ratio,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor.withValues(alpha: 0.7),
                        barColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
