// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_semester_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSemesterStateImpl _$$UserSemesterStateImplFromJson(
        Map<String, dynamic> json) =>
    _$UserSemesterStateImpl(
      userId: json['user_id'] as String,
      semesterCode: json['semester_code'] as String,
      weeklyGridCache: json['weekly_grid_cache'] as Map<String, dynamic>?,
      progressSummary: json['progress_summary'] as Map<String, dynamic>?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$UserSemesterStateImplToJson(
        _$UserSemesterStateImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'semester_code': instance.semesterCode,
      'weekly_grid_cache': instance.weeklyGridCache,
      'progress_summary': instance.progressSummary,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
