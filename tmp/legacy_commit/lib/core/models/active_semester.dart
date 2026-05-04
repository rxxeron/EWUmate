import 'package:freezed_annotation/freezed_annotation.dart';

part 'active_semester.freezed.dart';
part 'active_semester.g.dart';

@freezed
class ActiveSemester with _$ActiveSemester {
  const factory ActiveSemester({
    required String track,
    @JsonKey(name: 'current_semester_code') String? currentSemesterCode,
    @JsonKey(name: 'next_semester_code') String? nextSemesterCode,
    @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
    @JsonKey(name: 'classes_end_date') DateTime? classesEndDate,
    @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
    @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
    @JsonKey(name: 'final_exam_start') DateTime? finalExamStart,
    @JsonKey(name: 'final_exam_end') DateTime? finalExamEnd,
    @JsonKey(name: 'grade_submission_start') DateTime? gradeSubmissionStart,
    @JsonKey(name: 'grade_submission_deadline')
    DateTime? gradeSubmissionDeadline,
    @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
    @JsonKey(name: 'upcoming_classes_start_date')
    DateTime? upcomingClassesStartDate,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ActiveSemester;

  factory ActiveSemester.fromJson(Map<String, dynamic> json) =>
      _$ActiveSemesterFromJson(json);
}
