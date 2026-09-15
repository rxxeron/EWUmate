import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/ewu_theme_extension.dart';
import '../../controllers/course_marks_controller.dart';

class CourseOutlineSetupTab extends StatelessWidget {
  final CourseMarksController marksController;
  final ValueChanged<String> onStrategyChanged;

  const CourseOutlineSetupTab({
    super.key,
    required this.marksController,
    required this.onStrategyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 50),
      children: [
        _buildSectionHeader(context, 'Mark Distribution (Max 100)'),
        _buildPremiumField(context, 'Mid Term', marksController.distMidCtrl),
        _buildPremiumField(context, 'Final Term', marksController.distFinalCtrl),
        _buildPremiumField(context, 'Assignment', marksController.distAssignmentCtrl),
        _buildPremiumField(context, 'Project', marksController.distProjectCtrl),
        _buildPremiumField(context, 'Presentation', marksController.distPresentationCtrl),
        _buildPremiumField(context, 'Viva', marksController.distVivaCtrl),
        _buildPremiumField(context, 'Lab', marksController.distLabCtrl),
        _buildPremiumField(context, 'Attendance', marksController.distAttendanceCtrl),
        _buildPremiumField(context, 'Term Paper', marksController.distTermPaperCtrl),
        _buildPremiumField(context, 'Class Performance', marksController.distClassPerfCtrl),

        const Divider(color: Colors.white10, height: 40),
        _buildSectionHeader(context, 'Other Options'),
        _buildPremiumField(context, 'Optional 1', marksController.distOpt1Ctrl),
        _buildPremiumField(context, 'Optional 2', marksController.distOpt2Ctrl),
        _buildPremiumField(context, 'Optional 3', marksController.distOpt3Ctrl),

        const Divider(color: Colors.white10, height: 40),
        _buildSectionHeader(context, 'Quiz Strategy'),
        _buildPremiumField(context, 'Quiz Total Marks', marksController.distQuizCtrl),
        _buildPremiumField(context, 'Short Quiz Total', marksController.distShortQuizCtrl),

        _buildPremiumDropdown(
          context,
          'Quiz Strategy',
          marksController.quizStrategy,
          (val) {
            if (val != null) onStrategyChanged(val);
          },
        ),

        if (marksController.quizStrategy == 'best_n' || marksController.quizStrategy == 'average_n')
          Row(
            children: [
              Expanded(child: _buildPremiumField(context, 'N for Quiz', marksController.quizNCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildPremiumField(context, 'N for Short Quiz', marksController.shortQuizNCtrl)),
            ],
          ),
      ],
    );
  }

  Widget _buildPremiumField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    final colors = context.ewuColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceNavyBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.sora(color: colors.primaryText, fontWeight: FontWeight.w700, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: colors.secondaryText),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDropdown(
    BuildContext context,
    String label,
    String value,
    Function(String?) onChanged,
  ) {
    final colors = context.ewuColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: colors.surfaceNavyBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: colors.surfaceNavyBlue,
                icon: Icon(Icons.arrow_drop_down_rounded, color: colors.secondaryText),
                style: GoogleFonts.sora(color: colors.primaryText, fontWeight: FontWeight.w700, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'best_one', child: Text('Best One')),
                  DropdownMenuItem(value: 'best_n', child: Text('Best N (Total of Top N)')),
                  DropdownMenuItem(value: 'average_n', child: Text('Best N (Average of Top N)')),
                  DropdownMenuItem(value: 'sum_all', child: Text('Sum of all')),
                  DropdownMenuItem(value: 'average_all', child: Text('Avg of all')),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.ewuColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.sora(
          color: colors.primaryCyan,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
