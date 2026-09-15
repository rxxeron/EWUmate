import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/semester_course_marks.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ewu_theme_extension.dart';

class CourseProgressCard extends StatefulWidget {
  final Map<String, dynamic> courseData;
  final String? courseName;
  final VoidCallback onTap;

  const CourseProgressCard({
    super.key,
    required this.courseData,
    this.courseName,
    required this.onTap,
  });

  @override
  State<CourseProgressCard> createState() => _CourseProgressCardState();
}

class _CourseProgressCardState extends State<CourseProgressCard> {
  bool _isPressed = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final code = (widget.courseData['course_code'] ?? 'Course').toString().toUpperCase();
    final name = widget.courseName ?? 'Course Full Name';

    // Parse into the model to use single-source-of-truth totalObtained calculator
    final safeData = Map<String, dynamic>.from(widget.courseData);
    safeData['id'] ??= 'fallback_id_$code';
    safeData['user_id'] ??= 'fallback_user';
    safeData['semester_code'] ??= 'unknown_sem';
    safeData['course_code'] ??= code;

    final courseModel = SemesterCourseMarks.fromJson(safeData);
    final double totalObtained = courseModel.totalObtained;

    // Attendance calculation
    final extra = widget.courseData['marks_data'] ?? {};
    final attendance = extra['attendance'] ?? {};
    final dates = attendance['dates'] as Map<dynamic, dynamic>? ?? {};
    final types = attendance['types'] as Map<dynamic, dynamic>? ?? {};

    // Filter out duplicate plain date keys if their suffix-based equivalents exist
    final Set<String> keysToIgnore = {};
    dates.forEach((keyStr, _) {
      final key = keyStr.toString();
      if (key.contains('_')) {
        final plainKey = key.split('_')[0];
        keysToIgnore.add(plainKey);
      }
    });

    int joinedTheory = 0;
    int conductedTheory = 0;
    int joinedLab = 0;
    int conductedLab = 0;

    dates.forEach((keyStr, status) {
      final key = keyStr.toString();
      if (keysToIgnore.contains(key)) return;

      final type = types[key]?.toString() ?? (key.endsWith('_Lab') ? 'Lab' : 'Theory');

      if (status == 'joined') {
        if (type == 'Lab') {
          joinedLab++;
          conductedLab++;
        } else {
          joinedTheory++;
          conductedTheory++;
        }
      } else if (status == 'missed') {
        if (type == 'Lab') {
          conductedLab++;
        } else {
          conductedTheory++;
        }
      }
    });

    final double theoryPct = conductedTheory > 0 ? (joinedTheory / conductedTheory) * 100 : 0;
    final double labPct = conductedLab > 0 ? (joinedLab / conductedLab) * 100 : 0;
    final bool hasTheory = conductedTheory > 0;
    final bool hasLab = conductedLab > 0;

    // Letter grade and status color
    String grade = 'F';
    Color gradeColor = const Color(0xFFF43F5E);

    if (totalObtained >= 80) {
      grade = 'A+';
      gradeColor = AppColors.primaryCyan;
    } else if (totalObtained >= 75) {
      grade = 'A';
      gradeColor = AppColors.primaryCyan;
    } else if (totalObtained >= 70) {
      grade = 'A-';
      gradeColor = AppColors.primaryCyan;
    } else if (totalObtained >= 65) {
      grade = 'B+';
      gradeColor = const Color(0xFF10B981);
    } else if (totalObtained >= 60) {
      grade = 'B';
      gradeColor = const Color(0xFF10B981);
    } else if (totalObtained >= 55) {
      grade = 'B-';
      gradeColor = const Color(0xFFF59E0B);
    } else if (totalObtained >= 50) {
      grade = 'C+';
      gradeColor = const Color(0xFFF59E0B);
    } else if (totalObtained >= 45) {
      grade = 'C';
      gradeColor = const Color(0xFFF59E0B);
    } else if (totalObtained >= 40) {
      grade = 'D';
      gradeColor = const Color(0xFFF43F5E);
    } else {
      grade = 'F';
      gradeColor = const Color(0xFFF43F5E);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: colors.surfaceNavyBlue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colors.borderSubtle,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Code + Percentage & Grade Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      code,
                      style: GoogleFonts.sora(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalObtained.toStringAsFixed(1)}%',
                        style: GoogleFonts.sora(
                          color: gradeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: gradeColor.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          grade,
                          style: GoogleFonts.sora(
                            color: gradeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 3),

              // Course Name
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  color: colors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Attendance Badges
              if (hasTheory || hasLab) ...[
                const SizedBox(height: 8),
                if (hasTheory) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (theoryPct >= 80
                          ? const Color(0xFF10B981)
                          : theoryPct >= 60
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444)).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (theoryPct >= 80
                            ? const Color(0xFF10B981)
                            : theoryPct >= 60
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444)).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 11,
                          color: theoryPct >= 80
                              ? const Color(0xFF10B981)
                              : theoryPct >= 60
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Theory: ${theoryPct.toStringAsFixed(0)}% ($joinedTheory/$conductedTheory)',
                            style: GoogleFonts.sora(
                              color: theoryPct >= 80
                                  ? const Color(0xFF10B981)
                                  : theoryPct >= 60
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasLab) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (labPct >= 80
                          ? const Color(0xFF10B981)
                          : labPct >= 60
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444)).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (labPct >= 80
                            ? const Color(0xFF10B981)
                            : labPct >= 60
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444)).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.science_rounded,
                          size: 11,
                          color: labPct >= 80
                              ? const Color(0xFF10B981)
                              : labPct >= 60
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Lab: ${labPct.toStringAsFixed(0)}% ($joinedLab/$conductedLab)',
                            style: GoogleFonts.sora(
                              color: labPct >= 80
                                  ? const Color(0xFF10B981)
                                  : labPct >= 60
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              // Progress Bar
              const SizedBox(height: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (totalObtained / 100).clamp(0.0, 1.0),
                      backgroundColor: colors.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      color: gradeColor,
                      minHeight: 5,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 0,
                    child: Text(
                      '100 Max',
                      style: GoogleFonts.sora(
                        color: colors.textTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // Obtained Marks Breakdown List
              const SizedBox(height: 12),
              Expanded(
                child: _buildMarksList(widget.courseData, colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasMark(dynamic val) {
    if (val == null) return false;
    if (val is String) {
      final trimmed = val.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return false;
      return double.tryParse(trimmed) != null;
    }
    if (val is num) return true;
    return false;
  }

  String _formatMark(dynamic val) {
    if (val == null) return '';
    final d = double.tryParse(val.toString().trim());
    if (d == null) return val.toString().trim();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(1);
  }

  Widget _buildMarksList(Map<String, dynamic> data, EwuColors colors) {
    final List<Widget> items = [];

    // Quizzes logic
    final dynamic qArr = data['obt_quizzes'];
    if (qArr is List && qArr.isNotEmpty) {
      for (int i = 0; i < qArr.length; i++) {
        final val = qArr[i];
        if (_hasMark(val)) {
          items.add(_buildMarkRow('Quiz ${i + 1}', _formatMark(val), colors));
        }
      }
    }

    // Short Quizzes logic
    final dynamic sqArr = data['obt_short_quizzes'];
    if (sqArr is List && sqArr.isNotEmpty) {
      for (int i = 0; i < sqArr.length; i++) {
        final val = sqArr[i];
        if (_hasMark(val)) {
          items.add(_buildMarkRow('S. Quiz ${i + 1}', _formatMark(val), colors));
        }
      }
    }

    // All possible assessments in standard academic order
    if (_hasMark(data['obt_mid'])) {
      items.add(_buildMarkRow('Mid', _formatMark(data['obt_mid']), colors));
    }
    if (_hasMark(data['obt_final'])) {
      items.add(_buildMarkRow('Final', _formatMark(data['obt_final']), colors));
    }
    if (_hasMark(data['obt_lab'])) {
      items.add(_buildMarkRow('Lab', _formatMark(data['obt_lab']), colors));
    }
    if (_hasMark(data['obt_assignment'])) {
      items.add(_buildMarkRow('Assignment', _formatMark(data['obt_assignment']), colors));
    }
    if (_hasMark(data['obt_presentation'])) {
      items.add(_buildMarkRow('Presentation', _formatMark(data['obt_presentation']), colors));
    }
    if (_hasMark(data['obt_project'])) {
      items.add(_buildMarkRow('Project', _formatMark(data['obt_project']), colors));
    }
    if (_hasMark(data['obt_viva'])) {
      items.add(_buildMarkRow('Viva', _formatMark(data['obt_viva']), colors));
    }
    if (_hasMark(data['obt_attendance'])) {
      items.add(_buildMarkRow('Attendance', _formatMark(data['obt_attendance']), colors));
    }
    if (_hasMark(data['obt_class_performance'])) {
      items.add(_buildMarkRow('Class Perf.', _formatMark(data['obt_class_performance']), colors));
    }
    if (_hasMark(data['obt_term_paper'])) {
      items.add(_buildMarkRow('Term Paper', _formatMark(data['obt_term_paper']), colors));
    }
    if (_hasMark(data['obt_optional_1'])) {
      items.add(_buildMarkRow('Optional 1', _formatMark(data['obt_optional_1']), colors));
    }
    if (_hasMark(data['obt_optional_2'])) {
      items.add(_buildMarkRow('Optional 2', _formatMark(data['obt_optional_2']), colors));
    }
    if (_hasMark(data['obt_optional_3'])) {
      items.add(_buildMarkRow('Optional 3', _formatMark(data['obt_optional_3']), colors));
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          'Tap to add marks',
          style: GoogleFonts.sora(
            color: colors.textTertiary,
            fontSize: 10.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return RawScrollbar(
      controller: _scrollController,
      thumbVisibility: items.length > 8,
      thickness: 2.5,
      radius: const Radius.circular(2),
      thumbColor: colors.primaryCyan.withValues(alpha: 0.45),
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: items,
      ),
    );
  }

  Widget _buildMarkRow(String label, String value, EwuColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.sora(
                color: colors.secondaryText,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.sora(
              color: colors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
