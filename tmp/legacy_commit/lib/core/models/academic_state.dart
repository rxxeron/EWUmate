import 'package:freezed_annotation/freezed_annotation.dart';

part 'academic_state.freezed.dart';
part 'academic_state.g.dart';

@freezed
class AcademicState with _$AcademicState {
  const factory AcademicState({
    required String track,
    @JsonKey(name: 'current_semester_code') required String currentSemesterCode,
    @JsonKey(name: 'next_semester_code') required String nextSemesterCode,
    @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
    @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
    @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
    @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
    @JsonKey(name: 'upcoming_classes_start_date') DateTime? upcomingClassesStartDate,
  }) = _AcademicState;

  factory AcademicState.fromJson(Map<String, dynamic> json) =>
      _$AcademicStateFromJson(json);
}
