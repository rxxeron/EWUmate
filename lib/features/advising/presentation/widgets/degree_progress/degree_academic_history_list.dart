import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/models/semester_summary.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';

class DegreeAcademicHistoryList extends StatelessWidget {
  final List<SemesterSummary> summaries;

  const DegreeAcademicHistoryList({
    super.key,
    required this.summaries,
  });

  static String formatSemester(String? semester) {
    if (semester == null || semester.isEmpty) return "Unknown";
    return semester.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic History (${summaries.length} Semesters)',
          style: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final summary = summaries[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : colors.borderSubtle,
                  width: 1,
                ),
              ),
              child: ExpansionTile(
                iconColor: colors.primaryCyan,
                collapsedIconColor: colors.secondaryText,
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatSemester(summary.semesterCode),
                          style: GoogleFonts.sora(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${summary.courses.length} Courses · ${(summary.creditsEarned ?? 0.0).toStringAsFixed(1)} Cr',
                          style: GoogleFonts.sora(
                            color: colors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildMiniStat(context, 'TGPA', (summary.tgpa ?? 0.0).toStringAsFixed(2)),
                        const SizedBox(width: 8),
                        _buildMiniStat(context, 'CGPA', (summary.cgpa ?? 0.0).toStringAsFixed(2)),
                      ],
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: summary.courses.map((course) {
                        String code = '';
                        String grade = '';
                        if (course is Map) {
                          code = (course['course_code'] ?? course['code'] ?? course['courseCode'] ?? '').toString();
                          grade = (course['grade'] ?? course['Grade'] ?? '').toString();
                        } else {
                          try {
                            code = (course.courseCode ?? course.code ?? '').toString();
                          } catch (_) {}
                          try {
                            grade = (course.grade ?? '').toString();
                          } catch (_) {}
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                code,
                                style: GoogleFonts.sora(
                                  color: colors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primaryCyan.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  grade,
                                  style: GoogleFonts.sora(
                                    color: colors.primaryCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value) {
    final colors = context.ewuColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.sora(
              color: colors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.sora(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
