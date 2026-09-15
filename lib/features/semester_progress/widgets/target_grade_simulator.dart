import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/widgets/primitives/ewu_surface_card.dart';

class TargetGradeSimulator extends StatefulWidget {
  final double currentObtained;
  final double totalOutline;
  final double evaluatedMax;

  const TargetGradeSimulator({
    super.key,
    required this.currentObtained,
    required this.totalOutline,
    required this.evaluatedMax,
  });

  @override
  State<TargetGradeSimulator> createState() => _TargetGradeSimulatorState();
}

class _TargetGradeSimulatorState extends State<TargetGradeSimulator> {
  String _selectedGrade = 'A';

  static const Map<String, double> _gradeThresholds = {
    'A+': 80.0,
    'A': 75.0,
    'A-': 70.0,
    'B+': 65.0,
    'B': 60.0,
    'B-': 55.0,
    'C+': 50.0,
    'C': 45.0,
    'D': 40.0,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final targetThreshold = _gradeThresholds[_selectedGrade] ?? 80.0;
    final needed = targetThreshold - widget.currentObtained;
    final remainingMarks = (widget.totalOutline - widget.evaluatedMax).clamp(0.0, 100.0);
    final maxAchievable = widget.currentObtained + remainingMarks;

    final isSecured = needed <= 0;
    final isUnachievable = !isSecured && needed > remainingMarks;

    Color statusColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    if (isSecured) {
      statusColor = const Color(0xFF10B981);
      statusTitle = 'Target Secured!';
      statusSubtitle = 'You already have ${widget.currentObtained.toStringAsFixed(1)} marks, which meets the $_selectedGrade threshold ($targetThreshold).';
      statusIcon = Icons.check_circle_rounded;
    } else if (isUnachievable) {
      statusColor = const Color(0xFFEF4444);
      statusTitle = 'Mathematically Out of Reach';
      statusSubtitle = 'With ${remainingMarks.toStringAsFixed(1)} marks remaining, maximum achievable is ${maxAchievable.toStringAsFixed(1)} (Threshold: $targetThreshold).';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      final pctRequired = remainingMarks > 0 ? (needed / remainingMarks * 100).clamp(0.0, 100.0) : 0.0;
      statusColor = colors.primaryCyan;
      statusTitle = 'Need ${needed.toStringAsFixed(1)} of ${remainingMarks.toStringAsFixed(0)} Remaining';
      statusSubtitle = 'Score ${pctRequired.toStringAsFixed(0)}% or higher on upcoming exams/assignments to secure $_selectedGrade.';
      statusIcon = Icons.track_changes_rounded;
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
                child: Icon(Icons.auto_graph_rounded, color: colors.primaryCyan, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Grade Simulator',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryText,
                    ),
                  ),
                  Text(
                    'Simulate final exam scores needed for your goal',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: colors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grade selection pills
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _gradeThresholds.keys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final grade = _gradeThresholds.keys.elementAt(index);
                final isSelected = grade == _selectedGrade;
                final threshold = _gradeThresholds[grade]!.toStringAsFixed(0);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedGrade = grade);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primaryCyan
                          : (colors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? colors.primaryCyan : colors.borderSubtle,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          Text(
                            grade,
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? (colors.isDark ? colors.primaryNavy : Colors.white)
                                  : colors.primaryText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($threshold)',
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              color: isSelected
                                  ? (colors.isDark ? colors.primaryNavy.withValues(alpha: 0.8) : Colors.white70)
                                  : colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Target status feedback container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: colors.isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        statusSubtitle,
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: colors.primaryText.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
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
