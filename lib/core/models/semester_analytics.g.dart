// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SemesterAnalyticsImpl _$$SemesterAnalyticsImplFromJson(
        Map<String, dynamic> json) =>
    _$SemesterAnalyticsImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      semesterCode: json['semester_code'] as String,
      liveSgpa: (json['live_sgpa'] as num?)?.toDouble(),
      liveCgpa: (json['live_cgpa'] as num?)?.toDouble(),
      target: (json['target'] as num?)?.toDouble(),
      requiredCredit: (json['required_credit'] as num?)?.toDouble(),
      completedCredit: (json['completed_credit'] as num?)?.toDouble(),
      takenInThisSem: (json['taken_in_this_sem'] as num?)?.toDouble(),
      creditsLeft: (json['credits_left'] as num?)?.toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$SemesterAnalyticsImplToJson(
        _$SemesterAnalyticsImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'semester_code': instance.semesterCode,
      'live_sgpa': instance.liveSgpa,
      'live_cgpa': instance.liveCgpa,
      'target': instance.target,
      'required_credit': instance.requiredCredit,
      'completed_credit': instance.completedCredit,
      'taken_in_this_sem': instance.takenInThisSem,
      'credits_left': instance.creditsLeft,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
