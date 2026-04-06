import 'package:freezed_annotation/freezed_annotation.dart';

part 'enrollment.freezed.dart';
part 'enrollment.g.dart';

@freezed
class Enrollment with _$Enrollment {
  const factory Enrollment({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'semester_code') required String semesterCode,
    @JsonKey(name: 'course_code') required String courseCode,
    @JsonKey(name: 'section_id') String? sectionId,
    String? section,
    @Default('enrolled') String status,
    String? grade,
    @JsonKey(name: 'grade_points') double? gradePoints,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Enrollment;

  factory Enrollment.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentFromJson(json);
}
