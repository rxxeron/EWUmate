import 'package:freezed_annotation/freezed_annotation.dart';

part 'semester_analytics.freezed.dart';
part 'semester_analytics.g.dart';

@freezed
class SemesterAnalytics with _$SemesterAnalytics {
  const factory SemesterAnalytics({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'semester_code') required String semesterCode,
    @JsonKey(name: 'live_sgpa') double? liveSgpa,
    @JsonKey(name: 'live_cgpa') double? liveCgpa,
    double? target,
    @JsonKey(name: 'required_credit') double? requiredCredit,
    @JsonKey(name: 'completed_credit') double? completedCredit,
    @JsonKey(name: 'taken_in_this_sem') double? takenInThisSem,
    @JsonKey(name: 'credits_left') double? creditsLeft,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SemesterAnalytics;

  factory SemesterAnalytics.fromJson(Map<String, dynamic> json) =>
      _$SemesterAnalyticsFromJson(json);
}
