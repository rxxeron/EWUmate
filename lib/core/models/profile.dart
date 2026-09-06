import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    @JsonKey(name: 'student_id') String? studentId,
    @JsonKey(name: 'full_name') String? fullName,
    String? nickname,
    @JsonKey(name: 'program_code') String? programCode,
    @JsonKey(name: 'admitted_semester') String? admittedSemester,
    double? cgpa,
    @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'onboarding_status')
    @Default('pending')
    String onboardingStatus,
    @JsonKey(name: 'semester_type') @Default('tri') String semesterType,
    @JsonKey(name: 'department_name') String? departmentName,
    @JsonKey(name: 'scholarship_status') String? scholarshipStatus,
    @JsonKey(name: 'program_name') String? programName,
    String? track,
    @JsonKey(name: 'enrolled_sections')
    @Default([])
    List<String> enrolledSections,
    @JsonKey(name: 'enrolled_sections_next')
    @Default([])
    List<String> enrolledSectionsNext,
    @JsonKey(name: 'enrolled_credits') @Default(0.0) double enrolledCredits,
    @JsonKey(name: 'enrolled_credits_next') @Default(0.0) double enrolledCreditsNext,
    @JsonKey(name: 'past_history')
    @Default([])
    List<dynamic> pastHistory,
    @JsonKey(name: 'total_courses_completed') @Default(0) int totalCoursesCompleted,
    @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
    @JsonKey(name: 'app_open_count') @Default(0) int appOpenCount,
    @JsonKey(name: 'app_version') String? appVersion,
    @JsonKey(name: 'reminder_settings')
    @Default({})
    Map<String, dynamic> reminderSettings,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
