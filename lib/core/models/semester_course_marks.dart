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
    @JsonKey(name: 'dist_term_paper') double? distTermPaper,
    @JsonKey(name: 'dist_class_performance') double? distClassPerformance,
    @JsonKey(name: 'obt_mid') double? obtMid,
    @JsonKey(name: 'obt_final') double? obtFinal,
    @JsonKey(name: 'obt_assignment') double? obtAssignment,
    @JsonKey(name: 'obt_presentation') double? obtPresentation,
    @JsonKey(name: 'obt_viva') double? obtViva,
    @JsonKey(name: 'obt_attendance') double? obtAttendance,
    @JsonKey(name: 'obt_lab') double? obtLab,
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

  factory SemesterCourseMarks.fromJson(Map<String, dynamic> json) =>
      _$SemesterCourseMarksFromJson(json);
}
