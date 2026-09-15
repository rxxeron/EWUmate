import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ewumate/core/models/semester_summary.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/theme/app_colors.dart';
import 'package:ewumate/core/theme/ewu_theme_extension.dart';
import 'package:ewumate/core/utils/error_utils.dart';
import '../../semester_summary_providers.dart';

class AcademicYearsTimeline extends ConsumerWidget {
  final AsyncValue<List<AcademicYear>> asyncYears;
  final AsyncValue<List<ScholarshipAward>> awardsAsync;

  const AcademicYearsTimeline({
    super.key,
    required this.asyncYears,
    required this.awardsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ewuColors;
    final runningSemesterCode = ref.watch(academicStateProvider).valueOrNull?.currentSemesterCode;
    final livePredictedSgpa = ref.watch(projectedSGPAProvider);

    return asyncYears.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.primaryCyan)),
      error: (e, _) => Text(
        AuthErrorUtils.getFriendlyMessage(e),
        textAlign: TextAlign.center,
        style: GoogleFonts.sora(color: AppColors.error, fontSize: 12),
      ),
      data: (years) {
        if (years.isEmpty) {
          return Text(
            'No academic history found.',
            style: GoogleFonts.sora(color: colors.secondaryText, fontStyle: FontStyle.italic),
          );
        }

        return Column(
          children: years.map((ay) {
            final awards = awardsAsync.valueOrNull ?? [];
            final ayAward = awards.where((a) => a.forYear == ay.yearNumber + 1).firstOrNull;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school_rounded, color: colors.primaryCyan, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Year ${ay.yearNumber}',
                            style: GoogleFonts.sora(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${ay.totalCreditsEarned.toStringAsFixed(1)} Cr Earned',
                          style: GoogleFonts.sora(color: colors.primaryCyan, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (ayAward != null)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: colors.primaryCyan.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Icon(Icons.workspace_premium_rounded, color: colors.primaryCyan, size: 14),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ay.semesters.isEmpty
                      ? Center(
                          child: Text(
                            'Upcoming Year',
                            style: GoogleFonts.sora(color: colors.secondaryText, fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        )
                      : Row(
                          children: ay.semesters.map((SemesterSummary s) {
                            final isOngoing = s.id == 'ongoing' || (runningSemesterCode != null && s.semesterCode == runningSemesterCode && (s.tgpa == null || s.tgpa == 0.0));
                            final displayValue = isOngoing
                                ? (livePredictedSgpa > 0 ? livePredictedSgpa.toStringAsFixed(2) : '--')
                                : (s.tgpa ?? 0.0).toStringAsFixed(2);
                            final labelBadge = isOngoing ? ' (LIVE)' : '';

                            return Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    "${s.semesterCode.toUpperCase().replaceAll('_', '').replaceAllMapped(RegExp(r'(\d{4})$'), (m) => " '${m.group(1)!.substring(2)}")}$labelBadge",
                                    style: GoogleFonts.sora(
                                      color: isOngoing ? colors.primaryCyan : colors.secondaryText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isOngoing ? colors.primaryCyan.withValues(alpha: 0.12) : (colors.isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                                      border: isOngoing ? Border.all(color: colors.primaryCyan.withValues(alpha: 0.45), width: 1.2) : null,
                                    ),
                                    child: Text(
                                      displayValue,
                                      style: GoogleFonts.sora(
                                        color: isOngoing ? colors.primaryCyan : colors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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
