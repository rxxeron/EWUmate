import 'package:freezed_annotation/freezed_annotation.dart';

part 'semester_summary.freezed.dart';
part 'semester_summary.g.dart';

@freezed
class SemesterSummary with _$SemesterSummary {
  const factory SemesterSummary({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'semester_code') required String semesterCode,
    double? tgpa,
    double? cgpa,
    @JsonKey(name: 'credits_earned') double? creditsEarned,
    @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
    @Default([]) List<dynamic> courses,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SemesterSummary;

  factory SemesterSummary.fromJson(Map<String, dynamic> json) =>
      _$SemesterSummaryFromJson(json);
}
