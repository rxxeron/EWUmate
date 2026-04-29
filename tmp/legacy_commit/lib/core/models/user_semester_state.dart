import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_semester_state.freezed.dart';
part 'user_semester_state.g.dart';

@freezed
class UserSemesterState with _$UserSemesterState {
  const factory UserSemesterState({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'semester_code') required String semesterCode,
    @JsonKey(name: 'weekly_grid_cache') Map<String, dynamic>? weeklyGridCache,
    @JsonKey(name: 'progress_summary') Map<String, dynamic>? progressSummary,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserSemesterState;

  factory UserSemesterState.fromJson(Map<String, dynamic> json) =>
      _$UserSemesterStateFromJson(json);
}
