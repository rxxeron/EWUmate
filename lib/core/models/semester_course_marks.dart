import 'package:freezed_annotation/freezed_annotation.dart';

part 'semester_course_marks.freezed.dart';
part 'semester_course_marks.g.dart';

@freezed
class SemesterCourseMarks with _$SemesterCourseMarks {
  const factory SemesterCourseMarks({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'semester_code') required String semesterCode,
    @JsonKey(name: 'course_code') required String courseCode,
    @JsonKey(name: 'course_name') String? courseName,
    String? section,
    @JsonKey(name: 'quiz_strategy') @Default('bestN') String quizStrategy,
    @JsonKey(name: 'quiz_n') @Default(2) int quizN,
    @JsonKey(name: 'short_quiz_n') @Default(2) int shortQuizN,
    @JsonKey(name: 'dist_mid') @Default(30.0) double distMid,
    @JsonKey(name: 'dist_final') @Default(40.0) double distFinal,
    @JsonKey(name: 'dist_quiz') @Default(10.0) double distQuiz,
    @JsonKey(name: 'dist_short_quiz') double? distShortQuiz,
    @JsonKey(name: 'dist_assignment') double? distAssignment,
    @JsonKey(name: 'dist_presentation') double? distPresentation,
    @JsonKey(name: 'dist_viva') double? distViva,
    @JsonKey(name: 'dist_attendance') double? distAttendance,
    @JsonKey(name: 'dist_lab') double? distLab,
    @JsonKey(name: 'dist_project') double? distProject,
    @JsonKey(name: 'dist_term_paper') double? distTermPaper,
    @JsonKey(name: 'dist_class_performance') double? distClassPerformance,
    @JsonKey(name: 'obt_mid') double? obtMid,
    @JsonKey(name: 'obt_final') double? obtFinal,
    @JsonKey(name: 'obt_assignment') double? obtAssignment,
    @JsonKey(name: 'obt_presentation') double? obtPresentation,
    @JsonKey(name: 'obt_viva') double? obtViva,
    @JsonKey(name: 'obt_attendance') double? obtAttendance,
    @JsonKey(name: 'obt_lab') double? obtLab,
    @JsonKey(name: 'obt_project') double? obtProject,
    @JsonKey(name: 'obt_term_paper') double? obtTermPaper,
    @JsonKey(name: 'obt_class_performance') double? obtClassPerformance,
    @JsonKey(name: 'obt_quizzes') @Default([]) List<double> obtQuizzes,
    @JsonKey(name: 'obt_short_quizzes')
    @Default([])
    List<double> obtShortQuizzes,
    @JsonKey(name: 'grade_goal') String? gradeGoal,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SemesterCourseMarks;

  const SemesterCourseMarks._();

  factory SemesterCourseMarks.fromJson(Map<String, dynamic> json) =>
      _$SemesterCourseMarksFromJson(json);

  double _calculateQuizValue(List<double> marks, String strategy, int n, double maxMark) {
    if (marks.isEmpty) return 0.0;
    List<double> sortedMarks = List.from(marks);
    sortedMarks.sort((a, b) => b.compareTo(a));

    double total = 0.0;
    if (strategy == 'best_one') {
      total = sortedMarks.first;
    } else if (strategy == 'best_n' || strategy == 'bestN') {
      for (int i = 0; i < n && i < sortedMarks.length; i++) {
        total += sortedMarks[i];
      }
    } else if (strategy == 'average_n' || strategy == 'n_average') {
      double sum = 0;
      int count = 0;
      for (int i = 0; i < n && i < sortedMarks.length; i++) {
        sum += sortedMarks[i];
        count++;
      }
      total = count > 0 ? sum / count : 0;
    } else if (strategy == 'average_all') {
      total = sortedMarks.reduce((a, b) => a + b) / sortedMarks.length;
    } else if (strategy == 'sum_all') {
      total = sortedMarks.reduce((a, b) => a + b);
    }
    return total > maxMark ? maxMark : total;
  }

  double get totalObtained {
    double total = 0.0;
    total += obtMid ?? 0.0;
    total += obtFinal ?? 0.0;
    total += obtAssignment ?? 0.0;
    total += obtPresentation ?? 0.0;
    total += obtViva ?? 0.0;
    total += obtAttendance ?? 0.0;
    total += obtLab ?? 0.0;
    total += obtProject ?? 0.0;
    total += obtTermPaper ?? 0.0;
    total += obtClassPerformance ?? 0.0;

    if (obtQuizzes.isNotEmpty) {
      total += _calculateQuizValue(obtQuizzes, quizStrategy, quizN, distQuiz);
    }
    if (obtShortQuizzes.isNotEmpty) {
      total += _calculateQuizValue(obtShortQuizzes, 'best_one', shortQuizN, distShortQuiz ?? 0.0);
    }
    return total;
  }

  double get totalEvaluated {
    double total = 0.0;
    if (obtMid != null) total += distMid;
    if (obtFinal != null) total += distFinal;
    if (obtAssignment != null) total += (distAssignment ?? 0.0);
    if (obtPresentation != null) total += (distPresentation ?? 0.0);
    if (obtViva != null) total += (distViva ?? 0.0);
    if (obtAttendance != null) total += (distAttendance ?? 0.0);
    if (obtLab != null) total += (distLab ?? 0.0);
    if (obtProject != null) total += (distProject ?? 0.0);
    if (obtTermPaper != null) total += (distTermPaper ?? 0.0);
    if (obtClassPerformance != null) total += (distClassPerformance ?? 0.0);

    if (obtQuizzes.isNotEmpty) total += distQuiz;
    if (obtShortQuizzes.isNotEmpty) total += (distShortQuiz ?? 0.0);
    
    return total;
  }
}
