import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ewumate/core/theme/app_colors.dart';
import 'package:ewumate/core/theme/ewu_theme_extension.dart';
import 'package:ewumate/core/utils/error_utils.dart';
import 'package:ewumate/core/utils/grade_helper.dart';
import '../../semester_summary_providers.dart';

class GoalInputGrid extends ConsumerWidget {
  final AsyncValue currentMarksAsync;

  const GoalInputGrid({
    super.key,
    required this.currentMarksAsync,
  });

  double _getDynamicRequiredMarksFallback(String grade, String policy) {
    if (policy == 'legacy') {
      switch (grade) {
        case 'A+': return 80;
        case 'A': return 75;
        case 'A-': return 70;
        case 'B+': return 65;
        case 'B': return 60;
        case 'B-': return 55;
        case 'C+': return 50;
        case 'C': return 45;
        case 'C-': return 40;
        case 'D+': return 35;
        case 'D': return 30;
        default: return 0;
      }
    } else {
      switch (grade) {
        case 'A+': return 80;
        case 'A': return 75;
        case 'A-': return 70;
        case 'B+': return 65;
        case 'B': return 60;
        case 'B-': return 55;
        case 'C+': return 50;
        case 'C': return 45;
        case 'D': return 40;
        default: return 0;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ewuColors;

    return currentMarksAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.primaryCyan)),
      error: (e, _) => Text(
        AuthErrorUtils.getFriendlyMessage(e),
        textAlign: TextAlign.center,
        style: GoogleFonts.sora(color: AppColors.error, fontSize: 12),
      ),
      data: (marks) {
        if (marks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No enrolled courses found to set goals.',
                style: GoogleFonts.sora(color: colors.secondaryText),
              ),
            ),
          );
        }

        return Column(
          children: marks.map<Widget>((course) {
            final goals = ref.watch(goalGradesProvider);
            final cleanCode = course.courseCode.toUpperCase().replaceAll(' ', '');
            final currentGoal = goals[cleanCode] ?? goals[course.courseCode] ?? course.gradeGoal ?? 'A';
            final policy = GradeHelper.getPolicyForSemester(course.semesterCode);
            final gradeScaleMap = ref.watch(gradeScaleMapProvider(policy)).valueOrNull ?? {};

            final double evaluatedMarks = course.totalEvaluated;
            final double obtained = course.totalObtained;
            final double reqMarks = gradeScaleMap[currentGoal] ?? _getDynamicRequiredMarksFallback(currentGoal, policy);

            final double lostMarks = evaluatedMarks - obtained;
            final double maxPossibleFinalScore = 100.0 - lostMarks;
            final double remainingRequired = reqMarks - obtained;

            final bool achievable = maxPossibleFinalScore >= reqMarks;
            final String statusText = achievable
                ? 'Need ${remainingRequired > 0 ? remainingRequired.toStringAsFixed(1) : "0"} more marks'
                : 'Target mathematically out of reach';
            final Color statusColor = achievable ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.borderSubtle,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.courseCode,
                            style: GoogleFonts.sora(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (course.courseName != null)
                            Text(
                              course.courseName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(
                                color: colors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      // Grade Selector Dropdown Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.primaryCyan.withValues(alpha: 0.35), width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentGoal,
                            dropdownColor: const Color(0xFF09182D),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: colors.primaryCyan),
                            style: GoogleFonts.sora(color: colors.primaryCyan, fontWeight: FontWeight.w800, fontSize: 12),
                            items: ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D'].map((g) {
                              return DropdownMenuItem(value: g, child: Text(g));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(goalGradesProvider.notifier).updateGoal(course.courseCode, val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress bar to goal
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: reqMarks > 0 ? (obtained / reqMarks).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: colors.isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                      color: statusColor,
                      minHeight: 7,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Obtained: ${obtained.toStringAsFixed(1)} / ${reqMarks.toStringAsFixed(0)} required',
                        style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        statusText,
                        style: GoogleFonts.sora(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
