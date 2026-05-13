// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      studentId: json['student_id'] as String?,
      fullName: json['full_name'] as String?,
      nickname: json['nickname'] as String?,
      programCode: json['program_code'] as String?,
      admittedSemester: json['admitted_semester'] as String?,
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      totalCreditsEarned: (json['total_credits_earned'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      onboardingStatus: json['onboarding_status'] as String? ?? 'pending',
      semesterType: json['semester_type'] as String? ?? 'tri',
      departmentName: json['department_name'] as String?,
      scholarshipStatus: json['scholarship_status'] as String?,
      programName: json['program_name'] as String?,
      track: json['track'] as String?,
      enrolledSections: (json['enrolled_sections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      enrolledSectionsNext: (json['enrolled_sections_next'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      enrolledCredits: (json['enrolled_credits'] as num?)?.toDouble() ?? 0.0,
      enrolledCreditsNext:
          (json['enrolled_credits_next'] as num?)?.toDouble() ?? 0.0,
      pastHistory: json['past_history'] as List<dynamic>? ?? const [],
      totalCoursesCompleted:
          (json['total_courses_completed'] as num?)?.toInt() ?? 0,
      lastActiveAt: json['last_active_at'] == null
          ? null
          : DateTime.parse(json['last_active_at'] as String),
      appOpenCount: (json['app_open_count'] as num?)?.toInt() ?? 0,
      appVersion: json['app_version'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'full_name': instance.fullName,
      'nickname': instance.nickname,
      'program_code': instance.programCode,
      'admitted_semester': instance.admittedSemester,
      'cgpa': instance.cgpa,
      'total_credits_earned': instance.totalCreditsEarned,
      'photo_url': instance.photoUrl,
      'onboarding_status': instance.onboardingStatus,
      'semester_type': instance.semesterType,
      'department_name': instance.departmentName,
      'scholarship_status': instance.scholarshipStatus,
      'program_name': instance.programName,
      'track': instance.track,
      'enrolled_sections': instance.enrolledSections,
      'enrolled_sections_next': instance.enrolledSectionsNext,
      'enrolled_credits': instance.enrolledCredits,
      'enrolled_credits_next': instance.enrolledCreditsNext,
      'past_history': instance.pastHistory,
      'total_courses_completed': instance.totalCoursesCompleted,
      'last_active_at': instance.lastActiveAt?.toIso8601String(),
      'app_open_count': instance.appOpenCount,
      'app_version': instance.appVersion,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };
