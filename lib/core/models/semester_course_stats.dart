import 'package:freezed_annotation/freezed_annotation.dart';

part 'semester_course_stats.freezed.dart';
part 'semester_course_stats.g.dart';

@freezed
class SemesterCourseStats with _$SemesterCourseStats {
  const factory SemesterCourseStats({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String semester,
    @JsonKey(name: 'course_code') required String courseCode,
    @JsonKey(name: 'marks_obtained') double? marksObtained,
    @JsonKey(name: 'total_possible') @Default(100.0) double totalPossible,
    @JsonKey(name: 'grade_goal') String? gradeGoal,
    @JsonKey(name: 'last_updated') DateTime? lastUpdated,
  }) = _SemesterCourseStats;

  factory SemesterCourseStats.fromJson(Map<String, dynamic> json) =>
      _$SemesterCourseStatsFromJson(json);
}
