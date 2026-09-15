import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/refresh_utils.dart';
import '../semester_progress_repository.dart';
import '../widgets/course_assessment_bars.dart';

class CourseMarksController {
  final Map<String, dynamic> initialData;
  final String semesterCode;
  final VoidCallback onStateChanged;

  late Map<String, dynamic> data;

  late TextEditingController distMidCtrl, distFinalCtrl, distAttendanceCtrl;
  late TextEditingController distQuizCtrl, distShortQuizCtrl, distProjectCtrl;
  late TextEditingController distAssignmentCtrl, distTermPaperCtrl, distLabCtrl;
  late TextEditingController distPresentationCtrl, distVivaCtrl, distClassPerfCtrl;
  late TextEditingController distOpt1Ctrl, distOpt2Ctrl, distOpt3Ctrl;

  late TextEditingController obtMidCtrl, obtFinalCtrl, obtAttendanceCtrl;
  late TextEditingController obtProjectCtrl, obtAssignmentCtrl, obtTermPaperCtrl, obtLabCtrl;
  late TextEditingController obtPresentationCtrl, obtVivaCtrl, obtClassPerfCtrl;
  late TextEditingController obtOpt1Ctrl, obtOpt2Ctrl, obtOpt3Ctrl;

  List<TextEditingController> obtQuizzesCtrls = [];
  List<TextEditingController> obtShortQuizzesCtrls = [];

  String quizStrategy = 'best_n';
  TextEditingController quizNCtrl = TextEditingController(text: '1');

  String shortQuizStrategy = 'best_n';
  TextEditingController shortQuizNCtrl = TextEditingController(text: '1');

  CourseMarksController({
    required this.initialData,
    required this.semesterCode,
    required this.onStateChanged,
  }) {
    data = Map<String, dynamic>.from(initialData);
    _initControllers();
  }

  void _initControllers() {
    String normalizeStrategy(String? s) {
      if (s == null) return 'best_one';
      final cleaned = s.toLowerCase().replaceAll(' ', '_');
      if (cleaned == 'bestn') return 'best_n';
      if (cleaned == 'averagen') return 'average_n';
      return cleaned;
    }

    quizStrategy = normalizeStrategy(data['quiz_strategy']?.toString());
    quizNCtrl = TextEditingController(text: data['quiz_n']?.toString() ?? '1');

    final extra = data['marks_data'] ?? {};
    shortQuizStrategy = normalizeStrategy(extra['short_quiz_strategy']?.toString());
    shortQuizNCtrl = TextEditingController(text: data['short_quiz_n']?.toString() ?? '1');

    distMidCtrl = TextEditingController(text: data['dist_mid']?.toString() ?? '');
    distFinalCtrl = TextEditingController(text: data['dist_final']?.toString() ?? '');
    distQuizCtrl = TextEditingController(text: data['dist_quiz']?.toString() ?? '');
    distShortQuizCtrl = TextEditingController(text: data['dist_short_quiz']?.toString() ?? '');
    distAttendanceCtrl = TextEditingController(text: data['dist_attendance']?.toString() ?? '');
    distProjectCtrl = TextEditingController(text: data['dist_project']?.toString() ?? '');
    distAssignmentCtrl = TextEditingController(text: data['dist_assignment']?.toString() ?? '');
    distTermPaperCtrl = TextEditingController(text: data['dist_term_paper']?.toString() ?? '');
    distLabCtrl = TextEditingController(text: data['dist_lab']?.toString() ?? '');
    distPresentationCtrl = TextEditingController(text: data['dist_presentation']?.toString() ?? '');
    distVivaCtrl = TextEditingController(text: data['dist_viva']?.toString() ?? '');
    distClassPerfCtrl = TextEditingController(text: data['dist_class_performance']?.toString() ?? '');
    distOpt1Ctrl = TextEditingController(text: data['dist_optional_1']?.toString() ?? '');
    distOpt2Ctrl = TextEditingController(text: data['dist_optional_2']?.toString() ?? '');
    distOpt3Ctrl = TextEditingController(text: data['dist_optional_3']?.toString() ?? '');

    obtMidCtrl = TextEditingController(text: data['obt_mid']?.toString() ?? '');
    obtFinalCtrl = TextEditingController(text: data['obt_final']?.toString() ?? '');
    obtAttendanceCtrl = TextEditingController(text: data['obt_attendance']?.toString() ?? '');
    obtProjectCtrl = TextEditingController(text: data['obt_project']?.toString() ?? '');
    obtAssignmentCtrl = TextEditingController(text: data['obt_assignment']?.toString() ?? '');
    obtTermPaperCtrl = TextEditingController(text: data['obt_term_paper']?.toString() ?? '');
    obtLabCtrl = TextEditingController(text: data['obt_lab']?.toString() ?? '');
    obtPresentationCtrl = TextEditingController(text: data['obt_presentation']?.toString() ?? '');
    obtVivaCtrl = TextEditingController(text: data['obt_viva']?.toString() ?? '');
    obtClassPerfCtrl = TextEditingController(text: data['obt_class_performance']?.toString() ?? '');
    obtOpt1Ctrl = TextEditingController(text: data['obt_optional_1']?.toString() ?? '');
    obtOpt2Ctrl = TextEditingController(text: data['obt_optional_2']?.toString() ?? '');
    obtOpt3Ctrl = TextEditingController(text: data['obt_optional_3']?.toString() ?? '');

    final List<dynamic>? qArr = data['obt_quizzes'];
    if (qArr != null && qArr.isNotEmpty) {
      for (var q in qArr) {
        obtQuizzesCtrls.add(TextEditingController(text: q.toString()));
      }
    }
    final List<dynamic>? sqArr = data['obt_short_quizzes'];
    if (sqArr != null && sqArr.isNotEmpty) {
      for (var sq in sqArr) {
        obtShortQuizzesCtrls.add(TextEditingController(text: sq.toString()));
      }
    }

    for (var c in [
      distMidCtrl, distFinalCtrl, distQuizCtrl, distShortQuizCtrl, distAttendanceCtrl,
      distProjectCtrl, distAssignmentCtrl, distTermPaperCtrl, distLabCtrl,
      distPresentationCtrl, distVivaCtrl, distClassPerfCtrl, distOpt1Ctrl, distOpt2Ctrl, distOpt3Ctrl,
      obtMidCtrl, obtFinalCtrl, obtAttendanceCtrl, obtProjectCtrl, obtAssignmentCtrl,
      obtTermPaperCtrl, obtLabCtrl, obtPresentationCtrl, obtVivaCtrl, obtClassPerfCtrl,
      obtOpt1Ctrl, obtOpt2Ctrl, obtOpt3Ctrl,
    ]) {
      c.addListener(onStateChanged);
    }
  }

  void dispose() {
    for (var c in [
      distMidCtrl, distFinalCtrl, distQuizCtrl, distShortQuizCtrl, distAttendanceCtrl,
      distProjectCtrl, distAssignmentCtrl, distTermPaperCtrl, distLabCtrl,
      distPresentationCtrl, distVivaCtrl, distClassPerfCtrl, distOpt1Ctrl, distOpt2Ctrl, distOpt3Ctrl,
      obtMidCtrl, obtFinalCtrl, obtAttendanceCtrl, obtProjectCtrl, obtAssignmentCtrl,
      obtTermPaperCtrl, obtLabCtrl, obtPresentationCtrl, obtVivaCtrl, obtClassPerfCtrl,
      obtOpt1Ctrl, obtOpt2Ctrl, obtOpt3Ctrl, quizNCtrl, shortQuizNCtrl,
    ]) {
      c.dispose();
    }
    for (var c in obtQuizzesCtrls) {
      c.dispose();
    }
    for (var c in obtShortQuizzesCtrls) {
      c.dispose();
    }
  }

  double calculateQuizMark(List<TextEditingController> ctrls, String strategy, int n, double maxMark) {
    if (ctrls.isEmpty) return 0.0;
    List<double> marks = ctrls.map((c) => double.tryParse(c.text) ?? 0.0).toList();
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

  double calculateQuizzes(List<TextEditingController> ctrls) {
    if (ctrls == obtQuizzesCtrls) {
      double max = double.tryParse(distQuizCtrl.text) ?? 0;
      int n = int.tryParse(quizNCtrl.text) ?? 1;
      return calculateQuizMark(ctrls, quizStrategy, n, max);
    } else {
      double max = double.tryParse(distShortQuizCtrl.text) ?? 0;
      int n = int.tryParse(shortQuizNCtrl.text) ?? 1;
      return calculateQuizMark(ctrls, shortQuizStrategy, n, max);
    }
  }

  double getTotalOutline() {
    double total = 0;
    for (var c in [
      distMidCtrl, distFinalCtrl, distQuizCtrl, distShortQuizCtrl, distAttendanceCtrl,
      distProjectCtrl, distAssignmentCtrl, distTermPaperCtrl, distLabCtrl,
      distPresentationCtrl, distVivaCtrl, distClassPerfCtrl, distOpt1Ctrl, distOpt2Ctrl, distOpt3Ctrl,
    ]) {
      total += double.tryParse(c.text) ?? 0;
    }
    return total;
  }

  double getTotalObtained() {
    double total = 0;
    for (var c in [
      obtMidCtrl, obtFinalCtrl, obtAttendanceCtrl, obtProjectCtrl, obtAssignmentCtrl,
      obtTermPaperCtrl, obtLabCtrl, obtPresentationCtrl, obtVivaCtrl, obtClassPerfCtrl,
      obtOpt1Ctrl, obtOpt2Ctrl, obtOpt3Ctrl,
    ]) {
      total += double.tryParse(c.text) ?? 0;
    }

    double maxQuiz = double.tryParse(distQuizCtrl.text) ?? 0;
    double maxShortQuiz = double.tryParse(distShortQuizCtrl.text) ?? 0;
    int qN = int.tryParse(quizNCtrl.text) ?? 1;
    total += calculateQuizMark(obtQuizzesCtrls, quizStrategy, qN, maxQuiz);
    int sqN = int.tryParse(shortQuizNCtrl.text) ?? 1;
    total += calculateQuizMark(obtShortQuizzesCtrls, shortQuizStrategy, sqN, maxShortQuiz);
    return total;
  }

  String getExpectedGrade(double totalMark) {
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

  List<AssessmentCategoryItem> getBreakdownItems() {
    return [
      if ((double.tryParse(distMidCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Mid Term',
          obtained: double.tryParse(obtMidCtrl.text) ?? 0,
          max: double.tryParse(distMidCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distFinalCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Final Exam',
          obtained: double.tryParse(obtFinalCtrl.text) ?? 0,
          max: double.tryParse(distFinalCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distQuizCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Quizzes',
          obtained: calculateQuizzes(obtQuizzesCtrls),
          max: double.tryParse(distQuizCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distShortQuizCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Short Quizzes',
          obtained: calculateQuizzes(obtShortQuizzesCtrls),
          max: double.tryParse(distShortQuizCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distAttendanceCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Attendance',
          obtained: double.tryParse(obtAttendanceCtrl.text) ?? 0,
          max: double.tryParse(distAttendanceCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distAssignmentCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Assignment',
          obtained: double.tryParse(obtAssignmentCtrl.text) ?? 0,
          max: double.tryParse(distAssignmentCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distPresentationCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Presentation',
          obtained: double.tryParse(obtPresentationCtrl.text) ?? 0,
          max: double.tryParse(distPresentationCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distLabCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Lab',
          obtained: double.tryParse(obtLabCtrl.text) ?? 0,
          max: double.tryParse(distLabCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distProjectCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Project',
          obtained: double.tryParse(obtProjectCtrl.text) ?? 0,
          max: double.tryParse(distProjectCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distVivaCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Viva',
          obtained: double.tryParse(obtVivaCtrl.text) ?? 0,
          max: double.tryParse(distVivaCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distTermPaperCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Term Paper',
          obtained: double.tryParse(obtTermPaperCtrl.text) ?? 0,
          max: double.tryParse(distTermPaperCtrl.text) ?? 0,
        ),
      if ((double.tryParse(distClassPerfCtrl.text) ?? 0) > 0)
        AssessmentCategoryItem(
          title: 'Class Performance',
          obtained: double.tryParse(obtClassPerfCtrl.text) ?? 0,
          max: double.tryParse(distClassPerfCtrl.text) ?? 0,
        ),
    ];
  }

  double getEvaluatedMax() {
    double sum = 0;
    for (final item in getBreakdownItems()) {
      if (item.obtained > 0) sum += item.max;
    }
    return sum;
  }

  Future<void> saveMarks({
    required WidgetRef ref,
    required Map<String, String> markedDates,
    required Map<String, String> dateTypes,
  }) async {
    final double outlineSum = getTotalOutline();
    if (outlineSum > 100) {
      throw Exception('Total outline marks cannot exceed 100.');
    }

    data['dist_mid'] = double.tryParse(distMidCtrl.text);
    data['dist_final'] = double.tryParse(distFinalCtrl.text);
    data['dist_quiz'] = double.tryParse(distQuizCtrl.text);
    data['dist_short_quiz'] = double.tryParse(distShortQuizCtrl.text);
    data['dist_attendance'] = double.tryParse(distAttendanceCtrl.text);
    data['dist_project'] = double.tryParse(distProjectCtrl.text);
    data['dist_assignment'] = double.tryParse(distAssignmentCtrl.text);
    data['dist_term_paper'] = double.tryParse(distTermPaperCtrl.text);
    data['dist_lab'] = double.tryParse(distLabCtrl.text);
    data['dist_presentation'] = double.tryParse(distPresentationCtrl.text);
    data['dist_viva'] = double.tryParse(distVivaCtrl.text);
    data['dist_class_performance'] = double.tryParse(distClassPerfCtrl.text);
    data['dist_optional_1'] = double.tryParse(distOpt1Ctrl.text);
    data['dist_optional_2'] = double.tryParse(distOpt2Ctrl.text);
    data['dist_optional_3'] = double.tryParse(distOpt3Ctrl.text);

    data['obt_mid'] = double.tryParse(obtMidCtrl.text);
    data['obt_final'] = double.tryParse(obtFinalCtrl.text);
    data['obt_attendance'] = double.tryParse(obtAttendanceCtrl.text);
    data['obt_project'] = double.tryParse(obtProjectCtrl.text);
    data['obt_assignment'] = double.tryParse(obtAssignmentCtrl.text);
    data['obt_term_paper'] = double.tryParse(obtTermPaperCtrl.text);
    data['obt_lab'] = double.tryParse(obtLabCtrl.text);
    data['obt_presentation'] = double.tryParse(obtPresentationCtrl.text);
    data['obt_viva'] = double.tryParse(obtVivaCtrl.text);
    data['obt_class_performance'] = double.tryParse(obtClassPerfCtrl.text);
    data['obt_optional_1'] = double.tryParse(obtOpt1Ctrl.text);
    data['obt_optional_2'] = double.tryParse(obtOpt2Ctrl.text);
    data['obt_optional_3'] = double.tryParse(obtOpt3Ctrl.text);

    data['quiz_strategy'] = quizStrategy;
    data['quiz_n'] = int.tryParse(quizNCtrl.text) ?? 1;

    if (data['marks_data'] == null) data['marks_data'] = {};
    data['marks_data']['short_quiz_strategy'] = shortQuizStrategy;
    data['marks_data']['attendance'] = {
      'dates': markedDates,
      'types': dateTypes,
    };
    data['short_quiz_n'] = int.tryParse(shortQuizNCtrl.text) ?? 1;

    data['obt_quizzes'] = obtQuizzesCtrls
        .map((c) => double.tryParse(c.text))
        .where((e) => e != null)
        .toList();
    data['obt_short_quizzes'] = obtShortQuizzesCtrls
        .map((c) => double.tryParse(c.text))
        .where((e) => e != null)
        .toList();

    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(semesterProgressRepositoryProvider).saveCourseMarks(user.id, semesterCode, data);
      RefreshUtils.refreshAcademicData(ref);
      ref.invalidate(semesterProgressDataProvider(semesterCode));
    }
  }
}
