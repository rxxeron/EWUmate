import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/profile_repository.dart';
import '../../core/utils/course_utils.dart';
import 'semester_progress_repository.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/refresh_utils.dart';
import '../../core/widgets/premium_banner_ad.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class AttendanceSession {
  final DateTime date;
  final String type; // 'Theory' or 'Lab'
  AttendanceSession(this.date, this.type);
}

class _CourseProgressDetailScreenState
    extends ConsumerState<CourseProgressDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _data;
  bool _isSaving = false;

  Map<String, String> _markedDates = {};
  Map<String, String> _dateTypes = {};
  List<AttendanceSession> _generatedClassSessions = [];
  bool _isLoadingAttendance = false;
  String _attendanceError = '';
  bool _showAllAttendanceSessions = false;

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
    _tabController = TabController(length: 3, vsync: this);

    Map<String, dynamic> extra = _data['marks_data'] ?? {};
    Map<String, dynamic> attendance = extra['attendance'] ?? {};
    Map<String, dynamic> datesRaw = attendance['dates'] ?? {};
    _markedDates = Map<String, String>.from(datesRaw);
    _loadAttendanceCalendar();
    // Refresh marks from the repository to pick up any changes that happened
    // after the cached snapshot was passed to this screen (background sync may
    // have updated the data since the parent built the widget).
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMarksFromRepo());

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

    extra = _data['marks_data'] ?? {};
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
    setState(() {});
    if (_tabController.index == 1 && _generatedClassSessions.isEmpty && !_isLoadingAttendance) {
      _loadAttendanceCalendar();
    }
  }

  /// Fetches the latest saved marks from the repository and updates [_markedDates].
  /// This corrects stale cache snapshots that may have been passed in as [widget.courseData].
  Future<void> _refreshMarksFromRepo() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !mounted) return;
    try {
      final progressList = await ref
          .read(semesterProgressRepositoryProvider)
          .getSemesterProgressData(user.id, widget.semesterCode);

      final courseCode = (_data['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
      final freshData = progressList.firstWhere(
        (c) => (c['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '') == courseCode,
        orElse: () => <String, dynamic>{},
      );

      if (freshData.isNotEmpty && mounted) {
        final freshMarksData = freshData['marks_data'] as Map<String, dynamic>? ?? {};
        final freshAttendance = freshMarksData['attendance'] as Map<String, dynamic>? ?? {};
        final freshDates = freshAttendance['dates'] as Map<String, dynamic>? ?? {};
        setState(() {
          _markedDates = Map<String, String>.from(freshDates);
        });
      }
    } catch (e) {
      debugPrint('[CourseDetail] Could not refresh marks from repo: $e');
    }
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
    _data['marks_data']['attendance'] = {
      'dates': _markedDates,
      'types': _dateTypes,
    };

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
            Tab(text: 'Attendance'),
            Tab(text: 'Setup'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildObtainedTab(),
          _buildAttendanceTab(),
          _buildOutlineTab(),
        ],
      ),
    );
  }

  Future<void> _loadAttendanceCalendar() async {
    setState(() {
      _isLoadingAttendance = true;
      _attendanceError = '';
    });
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      
      final profile = ref.read(userProfileProvider).valueOrNull;
      final resolvedTrack = profile?.track == 'bi' ? 'bi_semester' : 'tri_semester';
      
      // 1. Fetch active semester start/end dates
      final activeSemRes = await Supabase.instance.client
          .from('active_semester')
          .select('classes_start_date, classes_end_date')
          .eq('track', resolvedTrack)
          .maybeSingle();
      
      DateTime? startDate = DateTime.tryParse(activeSemRes?['classes_start_date']?.toString() ?? '');
      DateTime? endDate = DateTime.tryParse(activeSemRes?['classes_end_date']?.toString() ?? '');
      startDate ??= DateTime.now().subtract(const Duration(days: 45));
      endDate ??= DateTime.now().add(const Duration(days: 45));
      
      // 2. Fetch weekly grid template to identify class weekdays
      final stateData = await Supabase.instance.client
          .from('user_semester_states')
          .select('weekly_grid_cache')
          .eq('user_id', user.id)
          .eq('semester_code', widget.semesterCode)
          .maybeSingle();
      final grid = stateData?['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
      
      final String currentCourseCodeNormalized = (widget.courseData['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
      
      final List<Map<String, String>> scheduledTemplates = [];
      final Map<String, int> weekdayMap = {
        'Monday': DateTime.monday,
        'Tuesday': DateTime.tuesday,
        'Wednesday': DateTime.wednesday,
        'Thursday': DateTime.thursday,
        'Friday': DateTime.friday,
        'Saturday': DateTime.saturday,
        'Sunday': DateTime.sunday,
      };
      
      for (final entry in grid.entries) {
        final day = entry.key;
        final dayClasses = entry.value;
        if (dayClasses is List) {
          for (final c in dayClasses) {
            final code = (c['courseCode'] ?? c['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
            if (code == currentCourseCodeNormalized) {
              final startTime = (c['startTime'] ?? c['start_time'] ?? '').toString();
              final endTime = (c['endTime'] ?? c['end_time'] ?? '').toString();
              final isLab = CourseUtils.isLab(startTime, endTime, code);
              final type = c['type']?.toString() ?? (isLab ? 'Lab' : 'Theory');
              scheduledTemplates.add({
                'day': day,
                'type': type,
              });
            }
          }
        }
      }
      
      // 3. Fetch academic calendar holidays
      final tableName = CourseUtils.semesterTable(
        'calendar',
        widget.semesterCode,
        cycleType: resolvedTrack,
      );
      
      final Set<String> holidayDates = {};
      try {
        final calendarRes = await Supabase.instance.client.from(tableName).select();
        if (calendarRes is List) {
          for (final ev in calendarRes) {
            final dateStr = (ev['event_date'] ?? ev['date'] ?? '').toString();
            final title = (ev['title'] ?? ev['name'] ?? '').toString().toLowerCase();
            final isHoliday = ev['is_holiday'] == true ||
                ev['type']?.toString().toLowerCase() == 'holiday' ||
                title.contains('holiday') ||
                title.contains('vacation') ||
                title.contains('break') ||
                title.contains('leave') ||
                title.contains('off day') ||
                title.contains('no classes');
            if (isHoliday && dateStr.isNotEmpty) {
              holidayDates.add(dateStr);
            }
          }
        }
      } catch (e) {
        debugPrint('[Attendance] Calendar fetch failed or table does not exist: $e');
      }
      
      // 4. Fetch cancellations and makeups from schedule exceptions
      final Set<String> cancelledDates = {};
      final List<Map<String, dynamic>> courseMakeups = [];
      try {
        final exceptionsRes = await Supabase.instance.client
            .from('schedule_exceptions')
            .select()
            .eq('user_id', user.id)
            .eq('course_code', currentCourseCodeNormalized);
        if (exceptionsRes is List) {
          for (final ex in exceptionsRes) {
            final dateStr = ex['date']?.toString();
            final type = ex['type']?.toString();
            if (dateStr != null && dateStr.isNotEmpty) {
              if (type == 'cancel') {
                cancelledDates.add(dateStr);
              } else if (type == 'makeup' || type == 'manual') {
                courseMakeups.add(ex);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[Attendance] Exceptions fetch failed: $e');
      }
      
      // 5. Generate matching weekdays up to today's date
      final List<AttendanceSession> generatedSessions = [];
      final List<int> weekdaysInt = scheduledTemplates.map((t) => weekdayMap[t['day']!]!).toSet().toList();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final DateTime endLimit = endDate.isAfter(today) ? today : endDate;
      
      for (DateTime d = startDate; d.isBefore(endLimit) || d.isAtSameMomentAs(endLimit); d = d.add(const Duration(days: 1))) {
        if (weekdaysInt.contains(d.weekday)) {
          final dayName = DateFormat('EEEE').format(d);
          final dayTemplates = scheduledTemplates.where((t) => t['day'] == dayName).toList();
          for (final temp in dayTemplates) {
            generatedSessions.add(AttendanceSession(
              DateTime(d.year, d.month, d.day),
              temp['type'] ?? 'Theory',
            ));
          }
        }
      }
      
      // Load saved dates and types from DB
      Map<String, dynamic> extra = _data['marks_data'] ?? {};
      Map<String, dynamic> attendance = extra['attendance'] ?? {};
      Map<String, dynamic> datesRaw = attendance['dates'] ?? {};
      Map<String, dynamic> typesRaw = attendance['types'] ?? {};
      _markedDates = Map<String, String>.from(datesRaw);
      _dateTypes = Map<String, String>.from(typesRaw);
      
      // Populate scheduled day types first
      for (final session in generatedSessions) {
        final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
        final key = '${dateStr}_${session.type}';
        if (!_dateTypes.containsKey(key)) {
          _dateTypes[key] = session.type;
        }
        if (!_dateTypes.containsKey(dateStr)) {
          _dateTypes[dateStr] = session.type; // legacy fallback
        }
      }

      // Add makeup classes/manual entries that have occurred up to endLimit
      for (final makeup in courseMakeups) {
        final dateStr = makeup['date']?.toString() ?? '';
        final mDate = DateTime.tryParse(dateStr);
        if (mDate != null && (mDate.isBefore(endLimit) || mDate.isAtSameMomentAs(endLimit))) {
          final normalizedDate = DateTime(mDate.year, mDate.month, mDate.day);
          final sessionType = makeup['session_type']?.toString() ?? makeup['sessionType']?.toString() ?? 'Theory';
          
          final exists = generatedSessions.any((s) => s.date == normalizedDate && s.type == sessionType);
          if (!exists) {
            generatedSessions.add(AttendanceSession(normalizedDate, sessionType));
          }
          final key = '${dateStr}_$sessionType';
          _dateTypes[key] = sessionType;
          _dateTypes[dateStr] = sessionType; // legacy fallback
        }
      }
      
      // Sort generated list in reverse order (newest first)
      generatedSessions.sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return a.type.compareTo(b.type);
      });
      
      // Auto-mark holidays and cancellations if not already set by the user
      for (final session in generatedSessions) {
        final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
        final key = '${dateStr}_${session.type}';
        if (!_markedDates.containsKey(key) && !_markedDates.containsKey(dateStr)) {
          if (holidayDates.contains(dateStr)) {
            _markedDates[key] = 'holiday';
          } else if (cancelledDates.contains(dateStr)) {
            _markedDates[key] = 'cancelled';
          }
        }
      }

      // Silent auto-save of updated/missing type mappings
      bool typesChanged = false;
      for (final entry in _dateTypes.entries) {
        if (typesRaw[entry.key]?.toString() != entry.value) {
          typesChanged = true;
          break;
        }
      }

      if (typesChanged) {
        final updatedData = Map<String, dynamic>.from(_data);
        if (updatedData['marks_data'] == null) updatedData['marks_data'] = {};
        final marksData = Map<String, dynamic>.from(updatedData['marks_data']);
        marksData['attendance'] = {
          'dates': _markedDates,
          'types': _dateTypes,
        };
        updatedData['marks_data'] = marksData;
        _data = updatedData;

        ref.read(semesterProgressRepositoryProvider)
           .saveCourseMarks(user.id, widget.semesterCode, updatedData)
           .then((_) {
             if (mounted) {
               ref.invalidate(semesterProgressDataProvider(widget.semesterCode));
             }
           })
           .catchError((err) {
             debugPrint('[DetailScreen] Silent types sync failed: $err');
           });
      }
      
      if (mounted) {
        setState(() {
          _generatedClassSessions = generatedSessions;
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
          _attendanceError = e.toString();
        });
      }
    }
  }

  void _addCustomClassDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      
      final String? selectedType = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Session Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Is this makeup class a Theory session or a Lab session?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'Theory'),
              child: const Text('Theory', style: TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'Lab'),
              child: const Text('Lab', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      
      final type = selectedType ?? 'Theory';
      
      setState(() {
        final key = '${dateStr}_$type';
        _dateTypes[key] = type;
        _dateTypes[dateStr] = type; // fallback
        
        if (!_markedDates.containsKey(key)) {
          _markedDates[key] = 'joined';
        }
        if (!_markedDates.containsKey(dateStr)) {
          _markedDates[dateStr] = 'joined'; // fallback
        }
        
        final exists = _generatedClassSessions.any((s) => s.date == picked && s.type == type);
        if (!exists) {
          _generatedClassSessions.add(AttendanceSession(picked, type));
          _generatedClassSessions.sort((a, b) {
            final cmp = b.date.compareTo(a.date);
            if (cmp != 0) return cmp;
            return a.type.compareTo(b.type);
          });
        }
      });
    }
  }

  String _getSessionStatus(String dateStr, String type) {
    final key = '${dateStr}_$type';
    if (_markedDates.containsKey(key)) {
      return _markedDates[key]!;
    }
    final hasTypedKey = _markedDates.containsKey('${dateStr}_Theory') || _markedDates.containsKey('${dateStr}_Lab');
    if (!hasTypedKey && _markedDates.containsKey(dateStr)) {
      return _markedDates[dateStr]!;
    }
    return 'unmarked';
  }

  void _showBulkMarkDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: const Text(
            'Bulk Mark Attendance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Mark all unmarked class sessions up to today as:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _bulkMarkSessions('joined');
              },
              child: const Text(
                'Joined (Present)',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _bulkMarkSessions('missed');
              },
              child: const Text(
                'Missed (Absent)',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        );
      },
    );
  }

  void _bulkMarkSessions(String status) {
    setState(() {
      for (final session in _generatedClassSessions) {
        final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
        final sessionKey = '${dateStr}_${session.type}';
        final currentStatus = _getSessionStatus(dateStr, session.type);
        if (currentStatus == 'unmarked') {
          _markedDates[sessionKey] = status;
          _markedDates[dateStr] = status;
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All unmarked past classes marked as ${status == 'joined' ? 'Joined' : 'Missed'}.'),
        backgroundColor: status == 'joined' ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_isLoadingAttendance) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
      );
    }
    
    if (_attendanceError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load calendar: $_attendanceError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22D3EE)),
                onPressed: _loadAttendanceCalendar,
                child: const Text('Retry', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    int joined = 0;
    int missed = 0;

    int joinedTheory = 0;
    int conductedTheory = 0;
    int joinedLab = 0;
    int conductedLab = 0;

    for (final session in _generatedClassSessions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
      final status = _getSessionStatus(dateStr, session.type);
      
      if (status == 'joined') {
        joined++;
        if (session.type == 'Lab') {
          joinedLab++;
          conductedLab++;
        } else {
          joinedTheory++;
          conductedTheory++;
        }
      } else if (status == 'missed') {
        missed++;
        if (session.type == 'Lab') {
          conductedLab++;
        } else {
          conductedTheory++;
        }
      }
    }

    final conducted = joined + missed;
    final double percentage = conducted > 0 ? (joined / conducted) * 100 : 100.0;

    final filteredSessions = _showAllAttendanceSessions
        ? _generatedClassSessions
        : _generatedClassSessions.where((session) {
            final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
            final status = _getSessionStatus(dateStr, session.type);
            if (status == 'unmarked') return true;
            
            final difference = DateTime.now().difference(session.date).inDays;
            return difference.abs() <= 7;
          }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildAttendanceGauge(
          percentage, 
          joined, 
          missed,
          joinedTheory: joinedTheory,
          conductedTheory: conductedTheory,
          joinedLab: joinedLab,
          conductedLab: conductedLab,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Class Sessions'),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _showBulkMarkDialog,
                  icon: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF10B981), size: 18),
                  label: const Text(
                    'Bulk Mark',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: _addCustomClassDate,
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF22D3EE), size: 16),
                  label: const Text(
                    'Add Makeup',
                    style: TextStyle(color: Color(0xFF22D3EE), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Recent & Unmarked'),
              selected: !_showAllAttendanceSessions,
              onSelected: (val) {
                if (val) {
                  setState(() => _showAllAttendanceSessions = false);
                }
              },
              selectedColor: const Color(0xFF22D3EE).withOpacity(0.15),
              checkmarkColor: const Color(0xFF22D3EE),
              labelStyle: TextStyle(
                color: !_showAllAttendanceSessions ? const Color(0xFF22D3EE) : Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
              side: BorderSide(
                color: !_showAllAttendanceSessions 
                    ? const Color(0xFF22D3EE).withOpacity(0.3) 
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('All Sessions'),
              selected: _showAllAttendanceSessions,
              onSelected: (val) {
                if (val) {
                  setState(() => _showAllAttendanceSessions = true);
                }
              },
              selectedColor: const Color(0xFF22D3EE).withOpacity(0.15),
              checkmarkColor: const Color(0xFF22D3EE),
              labelStyle: TextStyle(
                color: _showAllAttendanceSessions ? const Color(0xFF22D3EE) : Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
              side: BorderSide(
                color: _showAllAttendanceSessions 
                    ? const Color(0xFF22D3EE).withOpacity(0.3) 
                    : Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredSessions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Center(
              child: Text(
                _showAllAttendanceSessions 
                    ? 'No scheduled classes generated for this course.\nTry adding a custom makeup class!'
                    : 'No recent or unmarked classes found.\nToggle "All Sessions" above to view full history.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSessions.length,
            itemBuilder: (context, index) {
              final session = filteredSessions[index];
              final date = session.date;
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final sessionKey = '${dateStr}_${session.type}';
              
              final status = _getSessionStatus(dateStr, session.type);
              final sessionType = session.type;
              
              final isHoliday = status == 'holiday';
              final isCancelled = status == 'cancelled';
              final isSystemEvent = isHoliday || isCancelled;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSystemEvent 
                        ? Colors.white.withOpacity(0.03)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat('EEEE').format(date),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (sessionType == 'Lab' ? Colors.orange : const Color(0xFF22D3EE)).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (sessionType == 'Lab' ? Colors.orange : const Color(0xFF22D3EE)).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  sessionType.toUpperCase(),
                                  style: TextStyle(
                                    color: sessionType == 'Lab' ? Colors.orangeAccent : const Color(0xFF22D3EE),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM d, yyyy').format(date),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isHoliday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Holiday',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        ),
                        child: const Text(
                          'Cancelled',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      _buildActionButtons(sessionKey, status),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAttendanceGauge(
    double percentage, 
    int joined, 
    int missed, {
    required int joinedTheory, 
    required int conductedTheory, 
    required int joinedLab, 
    required int conductedLab,
  }) {
    final conducted = joined + missed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 80
                        ? const Color(0xFF10B981)
                        : percentage >= 60
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Attendance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLASSES ATTENDED',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$joined / $conducted classes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniCounterPill('Theory', '$joinedTheory/$conductedTheory', const Color(0xFF22D3EE)),
                    const SizedBox(width: 8),
                    if (conductedLab > 0)
                      _buildMiniCounterPill('Lab', '$joinedLab/$conductedLab', const Color(0xFFF59E0B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCounterPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(String sessionKey, String currentStatus) {
    final bool isJoined = currentStatus == 'joined';
    final bool isMissed = currentStatus == 'missed';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (isJoined) {
                _markedDates.remove(sessionKey);
                final parts = sessionKey.split('_');
                if (parts.isNotEmpty) {
                  _markedDates.remove(parts[0]);
                }
              } else {
                _markedDates[sessionKey] = 'joined';
                final parts = sessionKey.split('_');
                if (parts.isNotEmpty) {
                  _markedDates[parts[0]] = 'joined';
                }
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isJoined ? const Color(0xFF10B981) : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isJoined ? const Color(0xFF10B981) : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: isJoined ? Colors.white : Colors.white24,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              if (isMissed) {
                _markedDates.remove(sessionKey);
                final parts = sessionKey.split('_');
                if (parts.isNotEmpty) {
                  _markedDates.remove(parts[0]);
                }
              } else {
                _markedDates[sessionKey] = 'missed';
                final parts = sessionKey.split('_');
                if (parts.isNotEmpty) {
                  _markedDates[parts[0]] = 'missed';
                }
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMissed ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMissed ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: isMissed ? Colors.white : Colors.white24,
            ),
          ),
        ),
      ],
    );
  }
}
