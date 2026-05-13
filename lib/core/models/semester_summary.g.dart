// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SemesterSummaryImpl _$$SemesterSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$SemesterSummaryImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      semesterCode: json['semester_code'] as String,
      tgpa: (json['tgpa'] as num?)?.toDouble(),
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      creditsEarned: (json['credits_earned'] as num?)?.toDouble(),
      totalCreditsEarned: (json['total_credits_earned'] as num?)?.toDouble(),
      courses: json['courses'] as List<dynamic>? ?? const [],
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$SemesterSummaryImplToJson(
        _$SemesterSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'semester_code': instance.semesterCode,
      'tgpa': instance.tgpa,
      'cgpa': instance.cgpa,
      'credits_earned': instance.creditsEarned,
      'total_credits_earned': instance.totalCreditsEarned,
      'courses': instance.courses,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
