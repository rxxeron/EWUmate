import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/ewu_theme_extension.dart';
import '../../../../core/widgets/premium_banner_ad.dart';
import '../../controllers/course_marks_controller.dart';
import 'course_progress_summary_card.dart';

class CourseMarksInputTab extends StatelessWidget {
  final CourseMarksController marksController;
  final VoidCallback onMarksChanged;

  const CourseMarksInputTab({
    super.key,
    required this.marksController,
    required this.onMarksChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final currentObtained = marksController.getTotalObtained();
    final totalMarks = marksController.getTotalOutline();
    final grade = marksController.getExpectedGrade(currentObtained);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        const PremiumBannerAd(
          screenName: 'semester_progress',
          margin: EdgeInsets.only(bottom: 16),
        ),
        CourseProgressSummaryCard(
          obtained: currentObtained,
          total: totalMarks,
          grade: grade,
        ),
        const SizedBox(height: 20),

        Text(
          'Assessment Marks',
          style: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 12),

        _buildMarkInputRow(context, 'Mid Term', marksController.obtMidCtrl, marksController.distMidCtrl),
        _buildMarkInputRow(context, 'Final Exam', marksController.obtFinalCtrl, marksController.distFinalCtrl),
        _buildMarkInputRow(context, 'Presentation', marksController.obtPresentationCtrl, marksController.distPresentationCtrl),
        _buildMarkInputRow(context, 'Lab', marksController.obtLabCtrl, marksController.distLabCtrl),
        _buildMarkInputRow(context, 'Attendance', marksController.obtAttendanceCtrl, marksController.distAttendanceCtrl),
        _buildMarkInputRow(context, 'Assignment', marksController.obtAssignmentCtrl, marksController.distAssignmentCtrl),
        _buildMarkInputRow(context, 'Project', marksController.obtProjectCtrl, marksController.distProjectCtrl),
        _buildMarkInputRow(context, 'Viva', marksController.obtVivaCtrl, marksController.distVivaCtrl),
        _buildMarkInputRow(context, 'Term Paper', marksController.obtTermPaperCtrl, marksController.distTermPaperCtrl),
        _buildMarkInputRow(context, 'Class Performance', marksController.obtClassPerfCtrl, marksController.distClassPerfCtrl),
        _buildMarkInputRow(context, 'Optional 1', marksController.obtOpt1Ctrl, marksController.distOpt1Ctrl),
        _buildMarkInputRow(context, 'Optional 2', marksController.obtOpt2Ctrl, marksController.distOpt2Ctrl),
        _buildMarkInputRow(context, 'Optional 3', marksController.obtOpt3Ctrl, marksController.distOpt3Ctrl),

        const Divider(color: Colors.white10, height: 40),
        _buildQuizSection(context, 'Quizzes', marksController.obtQuizzesCtrls, marksController.distQuizCtrl),
        const SizedBox(height: 16),
        _buildQuizSection(context, 'Short Quizzes', marksController.obtShortQuizzesCtrls, marksController.distShortQuizCtrl),
      ],
    );
  }

  Widget _buildMarkInputRow(
    BuildContext context,
    String label,
    TextEditingController ctrl,
    TextEditingController distCtrl,
  ) {
    double dist = double.tryParse(distCtrl.text) ?? 0;
    if (dist <= 0) return const SizedBox.shrink();

    final colors = context.ewuColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.sora(
                color: colors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 140,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surfaceNavyBlue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Text('/ ', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
                Text(dist.toStringAsFixed(0), style: TextStyle(color: colors.secondaryText, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.end,
                    style: GoogleFonts.sora(
                      color: colors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                    onChanged: (v) => onMarksChanged(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_rounded,
            size: 20,
            color: ctrl.text.isNotEmpty ? const Color(0xFF10B981) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSection(
    BuildContext context,
    String title,
    List<TextEditingController> ctrls,
    TextEditingController distCtrl,
  ) {
    double dist = double.tryParse(distCtrl.text) ?? 0;
    if (dist <= 0) return const SizedBox.shrink();

    final colors = context.ewuColors;
    final calc = marksController.calculateQuizzes(ctrls);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.sora(
                color: colors.primaryCyan,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Calc: ${calc.toStringAsFixed(1)} / ${dist.toStringAsFixed(1)} (${marksController.quizStrategy})',
              style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...ctrls.asMap().entries.map((entry) {
          int index = entry.key;
          var ctrl = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colors.surfaceNavyBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Center(
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.sora(color: colors.primaryText, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Quiz ${index + 1} mark',
                          hintStyle: TextStyle(color: colors.secondaryText, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (v) => onMarksChanged(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    ctrls.removeAt(index);
                    onMarksChanged();
                  },
                ),
              ],
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceNavyBlue,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Center(
                  child: TextField(
                    readOnly: true,
                    onTap: () {
                      ctrls.add(TextEditingController());
                      onMarksChanged();
                    },
                    decoration: InputDecoration(
                      hintText: 'Add mark',
                      hintStyle: TextStyle(color: colors.secondaryText, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                ctrls.add(TextEditingController());
                onMarksChanged();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primaryCyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primaryCyan.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.add_rounded, color: colors.primaryCyan, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
