import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/auth_repository.dart';
import 'semester_progress_repository.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/refresh_utils.dart';

class CourseProgressDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> courseData;
  final String semesterCode;

  const CourseProgressDetailScreen({
    super.key,
    required this.courseData,
    required this.semesterCode,
  });

  @override
  ConsumerState<CourseProgressDetailScreen> createState() =>
      _CourseProgressDetailScreenState();
}

class _CourseProgressDetailScreenState
    extends ConsumerState<CourseProgressDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _data;
  bool _isSaving = false;

  late TextEditingController distMidCtrl, distFinalCtrl, distAttendanceCtrl;
  late TextEditingController distQuizCtrl, distShortQuizCtrl, distProjectCtrl;
  late TextEditingController distAssignmentCtrl, distTermPaperCtrl, distLabCtrl;
  late TextEditingController distPresentationCtrl, distVivaCtrl, distClassPerfCtrl;
  late TextEditingController distOpt1Ctrl, distOpt2Ctrl, distOpt3Ctrl;

  late TextEditingController obtMidCtrl, obtFinalCtrl, obtAttendanceCtrl;
  late TextEditingController obtProjectCtrl,
      obtAssignmentCtrl,
      obtTermPaperCtrl,
      obtLabCtrl;
  late TextEditingController obtPresentationCtrl, obtVivaCtrl, obtClassPerfCtrl;
  late TextEditingController obtOpt1Ctrl, obtOpt2Ctrl, obtOpt2Ctrl_Legacy, obtOpt3Ctrl;

  List<TextEditingController> obtQuizzesCtrls = [];
  List<TextEditingController> obtShortQuizzesCtrls = [];

  String _quizStrategy = 'best_n';
  TextEditingController _quizNCtrl = TextEditingController(text: '1');

  String _shortQuizStrategy = 'best_n';
  TextEditingController _shortQuizNCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.courseData);
    _tabController = TabController(length: 2, vsync: this);

    String normalizeStrategy(String? s) {
      if (s == null) return 'best_one';
      final cleaned = s.toLowerCase().replaceAll(' ', '_');
      if (cleaned == 'bestn') return 'best_n';
      if (cleaned == 'averagen') return 'average_n';
      return cleaned;
    }

    _quizStrategy = normalizeStrategy(_data['quiz_strategy']?.toString());
    // Removed legacy sum_all overwrite to support Best N correctly
    _quizNCtrl = TextEditingController(
      text: _data['quiz_n']?.toString() ?? '1',
    );

    Map<String, dynamic> extra = _data['marks_data'] ?? {};
    _shortQuizStrategy = normalizeStrategy(extra['short_quiz_strategy']?.toString());
    // Removed legacy sum_all overwrite to support Best N correctly
    _shortQuizNCtrl = TextEditingController(
      text: _data['short_quiz_n']?.toString() ?? '1',
    );

    distMidCtrl = TextEditingController(
      text: _data['dist_mid']?.toString() ?? '',
    );
    distFinalCtrl = TextEditingController(
      text: _data['dist_final']?.toString() ?? '',
    );
    distQuizCtrl = TextEditingController(
      text: _data['dist_quiz']?.toString() ?? '',
    );
    distShortQuizCtrl = TextEditingController(
      text: _data['dist_short_quiz']?.toString() ?? '',
    );
    distAttendanceCtrl = TextEditingController(
      text: _data['dist_attendance']?.toString() ?? '',
    );
    distProjectCtrl = TextEditingController(
      text: _data['dist_project']?.toString() ?? '',
    );
    distAssignmentCtrl = TextEditingController(
      text: _data['dist_assignment']?.toString() ?? '',
    );
    distTermPaperCtrl = TextEditingController(
      text: _data['dist_term_paper']?.toString() ?? '',
    );
    distLabCtrl = TextEditingController(
      text: _data['dist_lab']?.toString() ?? '',
    );
    distPresentationCtrl = TextEditingController(
      text: _data['dist_presentation']?.toString() ?? '',
    );
    distVivaCtrl = TextEditingController(
      text: _data['dist_viva']?.toString() ?? '',
    );
    distClassPerfCtrl = TextEditingController(
      text: _data['dist_class_performance']?.toString() ?? '',
    );
    distOpt1Ctrl = TextEditingController(
      text: _data['dist_optional_1']?.toString() ?? '',
    );
    distOpt2Ctrl = TextEditingController(
      text: _data['dist_optional_2']?.toString() ?? '',
    );
    distOpt3Ctrl = TextEditingController(
      text: _data['dist_optional_3']?.toString() ?? '',
    );

    obtMidCtrl = TextEditingController(
      text: _data['obt_mid']?.toString() ?? '',
    );
    obtFinalCtrl = TextEditingController(
      text: _data['obt_final']?.toString() ?? '',
    );
    obtAttendanceCtrl = TextEditingController(
      text: _data['obt_attendance']?.toString() ?? '',
    );
    obtProjectCtrl = TextEditingController(
      text: _data['obt_project']?.toString() ?? '',
    );
    obtAssignmentCtrl = TextEditingController(
      text: _data['obt_assignment']?.toString() ?? '',
    );
    obtTermPaperCtrl = TextEditingController(
      text: _data['obt_term_paper']?.toString() ?? '',
    );
    obtLabCtrl = TextEditingController(
      text: _data['obt_lab']?.toString() ?? '',
    );
    obtPresentationCtrl = TextEditingController(
      text: _data['obt_presentation']?.toString() ?? '',
    );
    obtVivaCtrl = TextEditingController(
      text: _data['obt_viva']?.toString() ?? '',
    );
    obtClassPerfCtrl = TextEditingController(
      text: _data['obt_class_performance']?.toString() ?? '',
    );
    obtOpt1Ctrl = TextEditingController(
      text: _data['obt_optional_1']?.toString() ?? '',
    );
    obtOpt2Ctrl = TextEditingController(
      text: _data['obt_optional_2']?.toString() ?? '',
    );
    obtOpt3Ctrl = TextEditingController(
      text: _data['obt_optional_3']?.toString() ?? '',
    );

    final List<dynamic>? qArr = _data['obt_quizzes'];
    if (qArr != null && qArr.isNotEmpty) {
      for (var q in qArr) {
        obtQuizzesCtrls.add(TextEditingController(text: q.toString()));
      }
    }
    final List<dynamic>? sqArr = _data['obt_short_quizzes'];
    if (sqArr != null && sqArr.isNotEmpty) {
      for (var sq in sqArr) {
        obtShortQuizzesCtrls.add(TextEditingController(text: sq.toString()));
      }
    }

    _tabController.addListener(_handleTabChange);

    for (var c in [
      distMidCtrl,
      distFinalCtrl,
      distQuizCtrl,
      distShortQuizCtrl,
      distAttendanceCtrl,
      distProjectCtrl,
      distAssignmentCtrl,
      distTermPaperCtrl,
      distLabCtrl,
      distPresentationCtrl,
      distVivaCtrl,
      distClassPerfCtrl,
      distOpt1Ctrl,
      distOpt2Ctrl,
      distOpt3Ctrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  void _handleTabChange() {
    if (_tabController.index == 0) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    distMidCtrl.dispose();
    distFinalCtrl.dispose();
    distQuizCtrl.dispose();
    distShortQuizCtrl.dispose();
    distAttendanceCtrl.dispose();
    distProjectCtrl.dispose();
    distAssignmentCtrl.dispose();
    distTermPaperCtrl.dispose();
    distLabCtrl.dispose();
    distPresentationCtrl.dispose();
    distVivaCtrl.dispose();
    distClassPerfCtrl.dispose();
    distOpt1Ctrl.dispose();
    distOpt2Ctrl.dispose();
    distOpt3Ctrl.dispose();

    obtMidCtrl.dispose();
    obtFinalCtrl.dispose();
    obtAttendanceCtrl.dispose();
    obtProjectCtrl.dispose();
    obtAssignmentCtrl.dispose();
    obtTermPaperCtrl.dispose();
    obtLabCtrl.dispose();
    obtPresentationCtrl.dispose();
    obtVivaCtrl.dispose();
    obtClassPerfCtrl.dispose();
    obtOpt1Ctrl.dispose();
    obtOpt2Ctrl.dispose();
    obtOpt3Ctrl.dispose();

    _quizNCtrl.dispose();
    _shortQuizNCtrl.dispose();
    for (var c in obtQuizzesCtrls) {
      c.dispose();
    }
    for (var c in obtShortQuizzesCtrls) {
      c.dispose();
    }

    super.dispose();
  }

  double _getTotalOutline() {
    double total = 0;
    for (var c in [
      distMidCtrl,
      distFinalCtrl,
      distQuizCtrl,
      distShortQuizCtrl,
      distAttendanceCtrl,
      distProjectCtrl,
      distAssignmentCtrl,
      distTermPaperCtrl,
      distLabCtrl,
      distPresentationCtrl,
      distVivaCtrl,
      distClassPerfCtrl,
      distOpt1Ctrl,
      distOpt2Ctrl,
      distOpt3Ctrl,
    ]) {
      total += double.tryParse(c.text) ?? 0;
    }
    return total;
  }

  double _calculateQuizMark(
    List<TextEditingController> ctrls,
    String strategy,
    int n,
    double maxMark,
  ) {
    if (ctrls.isEmpty) return 0.0;
    List<double> marks = ctrls
        .map((c) => double.tryParse(c.text) ?? 0.0)
        .toList();
    marks.sort((a, b) => b.compareTo(a));

    double total = 0.0;
    if (strategy == 'best_one') {
      total = marks.first;
    } else if (strategy == 'best_n') {
      for (int i = 0; i < n && i < marks.length; i++) {
        total += marks[i];
      }
    } else if (strategy == 'average_n' || strategy == 'n_average') {
      double sum = 0;
      int count = 0;
      for (int i = 0; i < n && i < marks.length; i++) {
        sum += marks[i];
        count++;
      }
      total = count > 0 ? sum / count : 0;
    } else if (strategy == 'average_all') {
      total = marks.reduce((a, b) => a + b) / marks.length;
    } else if (strategy == 'sum_all') {
      total = marks.reduce((a, b) => a + b);
    }
    return total > maxMark ? maxMark : total;
  }

  double _getTotalObtained() {
    double total = 0;
    for (var c in [
      obtMidCtrl,
      obtFinalCtrl,
      obtAttendanceCtrl,
      obtProjectCtrl,
      obtAssignmentCtrl,
      obtTermPaperCtrl,
      obtLabCtrl,
      obtPresentationCtrl,
      obtVivaCtrl,
      obtClassPerfCtrl,
      obtOpt1Ctrl,
      obtOpt2Ctrl,
      obtOpt3Ctrl,
    ]) {
      total += double.tryParse(c.text) ?? 0;
    }

    double maxQuiz = double.tryParse(distQuizCtrl.text) ?? 0;
    double maxShortQuiz = double.tryParse(distShortQuizCtrl.text) ?? 0;

    int qN = int.tryParse(_quizNCtrl.text) ?? 1;
    total += _calculateQuizMark(obtQuizzesCtrls, _quizStrategy, qN, maxQuiz);

    int sqN = int.tryParse(_shortQuizNCtrl.text) ?? 1;
    total += _calculateQuizMark(
      obtShortQuizzesCtrls,
      _shortQuizStrategy,
      sqN,
      maxShortQuiz,
    );

    return total;
  }

  String _getExpectedGrade(double totalMark) {
    if (totalMark >= 80) return 'A+';
    if (totalMark >= 75) return 'A';
    if (totalMark >= 70) return 'A-';
    if (totalMark >= 65) return 'B+';
    if (totalMark >= 60) return 'B';
    if (totalMark >= 55) return 'B-';
    if (totalMark >= 50) return 'C+';
    if (totalMark >= 45) return 'C';
    if (totalMark >= 40) return 'D';
    return 'F';
  }

  double _calculateQuizzes(List<TextEditingController> ctrls) {
    if (ctrls == obtQuizzesCtrls) {
      double max = double.tryParse(distQuizCtrl.text) ?? 0;
      int n = int.tryParse(_quizNCtrl.text) ?? 1;
      return _calculateQuizMark(ctrls, _quizStrategy, n, max);
    } else {
      double max = double.tryParse(distShortQuizCtrl.text) ?? 0;
      int n = int.tryParse(_shortQuizNCtrl.text) ?? 1;
      return _calculateQuizMark(ctrls, _shortQuizStrategy, n, max);
    }
  }

  Future<void> _saveData() async {
    final double outlineSum = _getTotalOutline();
    if (outlineSum > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Total outline marks cannot exceed 100.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    _data['dist_mid'] = double.tryParse(distMidCtrl.text);
    _data['dist_final'] = double.tryParse(distFinalCtrl.text);
    _data['dist_quiz'] = double.tryParse(distQuizCtrl.text);
    _data['dist_short_quiz'] = double.tryParse(distShortQuizCtrl.text);
    _data['dist_attendance'] = double.tryParse(distAttendanceCtrl.text);
    _data['dist_project'] = double.tryParse(distProjectCtrl.text);
    _data['dist_assignment'] = double.tryParse(distAssignmentCtrl.text);
    _data['dist_term_paper'] = double.tryParse(distTermPaperCtrl.text);
    _data['dist_lab'] = double.tryParse(distLabCtrl.text);
    _data['dist_presentation'] = double.tryParse(distPresentationCtrl.text);
    _data['dist_viva'] = double.tryParse(distVivaCtrl.text);
    _data['dist_class_performance'] = double.tryParse(distClassPerfCtrl.text);
    _data['dist_optional_1'] = double.tryParse(distOpt1Ctrl.text);
    _data['dist_optional_2'] = double.tryParse(distOpt2Ctrl.text);
    _data['dist_optional_3'] = double.tryParse(distOpt3Ctrl.text);

    _data['obt_mid'] = double.tryParse(obtMidCtrl.text);
    _data['obt_final'] = double.tryParse(obtFinalCtrl.text);
    _data['obt_attendance'] = double.tryParse(obtAttendanceCtrl.text);
    _data['obt_project'] = double.tryParse(obtProjectCtrl.text);
    _data['obt_assignment'] = double.tryParse(obtAssignmentCtrl.text);
    _data['obt_term_paper'] = double.tryParse(obtTermPaperCtrl.text);
    _data['obt_lab'] = double.tryParse(obtLabCtrl.text);
    _data['obt_presentation'] = double.tryParse(obtPresentationCtrl.text);
    _data['obt_viva'] = double.tryParse(obtVivaCtrl.text);
    _data['obt_class_performance'] = double.tryParse(obtClassPerfCtrl.text);
    _data['obt_optional_1'] = double.tryParse(obtOpt1Ctrl.text);
    _data['obt_optional_2'] = double.tryParse(obtOpt2Ctrl.text);
    _data['obt_optional_3'] = double.tryParse(obtOpt3Ctrl.text);

    _data['quiz_strategy'] = _quizStrategy;
    _data['quiz_n'] = int.tryParse(_quizNCtrl.text) ?? 1;

    if (_data['marks_data'] == null) _data['marks_data'] = {};
    _data['marks_data']['short_quiz_strategy'] = _shortQuizStrategy;

    _data['short_quiz_n'] = int.tryParse(_shortQuizNCtrl.text) ?? 1;

    _data['obt_quizzes'] = obtQuizzesCtrls
        .map((c) => double.tryParse(c.text))
        .where((e) => e != null)
        .toList();
    _data['obt_short_quizzes'] = obtShortQuizzesCtrls
        .map((c) => double.tryParse(c.text))
        .where((e) => e != null)
        .toList();

    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref
            .read(semesterProgressRepositoryProvider)
            .saveCourseMarks(user.id, widget.semesterCode, _data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        RefreshUtils.refreshAcademicData(ref);
        ref.invalidate(semesterProgressDataProvider(widget.semesterCode));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AuthErrorUtils.getFriendlyMessage(e),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    setState(() => _isSaving = false);
  }

  Widget _buildPremiumField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDropdown(
    String label,
    String value,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.white24,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
                items: const [
                  DropdownMenuItem(value: 'best_one', child: Text('Best One')),
                  DropdownMenuItem(
                    value: 'best_n',
                    child: Text('Best N (Total of Top N)'),
                  ),
                  DropdownMenuItem(
                    value: 'average_n',
                    child: Text('Best N (Average of Top N)'),
                  ),
                  DropdownMenuItem(value: 'sum_all', child: Text('Sum of all')),
                  DropdownMenuItem(
                    value: 'average_all',
                    child: Text('Avg of all'),
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF22D3EE),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOutlineTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 50),
      children: [
        _buildSectionHeader('Mark Distribution (Max 100)'),
        _buildPremiumField('Mid Term', distMidCtrl),
        _buildPremiumField('Final Term', distFinalCtrl),
        _buildPremiumField('Assignment', distAssignmentCtrl),
        _buildPremiumField('Project', distProjectCtrl),
        _buildPremiumField('Presentation', distPresentationCtrl),
        _buildPremiumField('Viva', distVivaCtrl),
        _buildPremiumField('Lab', distLabCtrl),
        _buildPremiumField('Attendance', distAttendanceCtrl),
        _buildPremiumField('Term Paper', distTermPaperCtrl),
        _buildPremiumField('Class Performance', distClassPerfCtrl),

        const Divider(color: Colors.white10, height: 40),
        _buildSectionHeader('Other Options'),
        _buildPremiumField('Optional 1', distOpt1Ctrl),
        _buildPremiumField('Optional 2', distOpt2Ctrl),
        _buildPremiumField('Optional 3', distOpt3Ctrl),

        const Divider(color: Colors.white10, height: 40),
        _buildSectionHeader('Quiz Strategy'),
        _buildPremiumField('Quiz Total Marks', distQuizCtrl),
        _buildPremiumField('Short Quiz Total', distShortQuizCtrl),

        _buildPremiumDropdown(
          'Quiz Strategy',
          _quizStrategy,
          (val) => setState(() => _quizStrategy = val!),
        ),

        if (_quizStrategy == 'best_n' || _quizStrategy == 'average_n')
          Row(
            children: [
              Expanded(child: _buildPremiumField('N for Quiz', _quizNCtrl)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumField('N for Short Quiz', _shortQuizNCtrl),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildObtainedTab() {
    double currentObtained = _getTotalObtained();
    double totalMarks = _getTotalOutline();
    String grade = _getExpectedGrade(currentObtained);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        _buildSummaryCard(currentObtained, totalMarks, grade),
        const SizedBox(height: 24),

        _buildMarkInputRow('Mid Term', obtMidCtrl, distMidCtrl),
        _buildMarkInputRow('Final Exam', obtFinalCtrl, distFinalCtrl),
        _buildMarkInputRow(
          'Presentation',
          obtPresentationCtrl,
          distPresentationCtrl,
        ),
        _buildMarkInputRow('Lab', obtLabCtrl, distLabCtrl),
        _buildMarkInputRow('Attendance', obtAttendanceCtrl, distAttendanceCtrl),
        _buildMarkInputRow('Assignment', obtAssignmentCtrl, distAssignmentCtrl),
        _buildMarkInputRow('Project', obtProjectCtrl, distProjectCtrl),
        _buildMarkInputRow('Viva', obtVivaCtrl, distVivaCtrl),
        _buildMarkInputRow('Term Paper', obtTermPaperCtrl, distTermPaperCtrl),
        _buildMarkInputRow('Class Performance', obtClassPerfCtrl, distClassPerfCtrl),
        _buildMarkInputRow('Optional 1', obtOpt1Ctrl, distOpt1Ctrl),
        _buildMarkInputRow('Optional 2', obtOpt2Ctrl, distOpt2Ctrl),
        _buildMarkInputRow('Optional 3', obtOpt3Ctrl, distOpt3Ctrl),

        const Divider(color: Colors.white10, height: 40),
        _buildQuizSection('Quizzes', obtQuizzesCtrls, distQuizCtrl),
        const SizedBox(height: 16),
        _buildQuizSection(
          'Short Quizzes',
          obtShortQuizzesCtrls,
          distShortQuizCtrl,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double obtained, double total, String grade) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryItem(obtained.toStringAsFixed(1), 'Obtained'),
          _buildSummaryItem(total.toStringAsFixed(0), 'Total'),
          _buildSummaryItem(grade, 'Grade'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkInputRow(
    String label,
    TextEditingController ctrl,
    TextEditingController distCtrl,
  ) {
    // Only show if the distribution is not 0
    double dist = double.tryParse(distCtrl.text) ?? 0;
    if (dist <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: 140,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Text(
                  '/ ',
                  style: TextStyle(color: Colors.white24, fontSize: 13),
                ),
                Text(
                  dist.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white24, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_rounded,
            size: 20,
            color: ctrl.text.isNotEmpty ? Colors.greenAccent : Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSection(
    String title,
    List<TextEditingController> ctrls,
    TextEditingController distCtrl,
  ) {
    double dist = double.tryParse(distCtrl.text) ?? 0;
    if (dist <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF22D3EE),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Calc: ${_calculateQuizzes(ctrls).toStringAsFixed(1)} / ${dist.toStringAsFixed(1)} ($_quizStrategy)',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Existing list of quizzes
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
                      color: const Color(0xFF1E293B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Center(
                      child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Quiz ${index + 1} mark',
                          hintStyle: const TextStyle(
                            color: Colors.white24,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => setState(() => ctrls.removeAt(index)),
                ),
              ],
            ),
          );
        }),

        // Add new mark field
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Center(
                  child: TextField(
                    readOnly: true, // Just a placeholder field to trigger add
                    onTap: () =>
                        setState(() => ctrls.add(TextEditingController())),
                    decoration: const InputDecoration(
                      hintText: 'Add mark',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => ctrls.add(TextEditingController())),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22D3EE).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF22D3EE).withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF22D3EE),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    var courseCode = widget.courseData['course_code'] ?? 'Course';
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          courseCode,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF22D3EE),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF22D3EE),
                    size: 28,
                  ),
            onPressed: _isSaving ? null : _saveData,
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF22D3EE),
          indicatorWeight: 4,
          labelColor: const Color(0xFF22D3EE),
          unselectedLabelColor: Colors.white.withOpacity(0.4),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(text: 'Marks'),
            Tab(text: 'Setup'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildObtainedTab(), _buildOutlineTab()],
      ),
    );
  }
}
