// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      courseCode: json['course_code'] as String?,
      courseName: json['course_name'] as String?,
      assignDate: json['assign_date'] == null
          ? null
          : DateTime.parse(json['assign_date'] as String),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      submissionType: json['submission_type'] as String?,
      type: json['type'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      isMissed: json['is_missed'] as bool? ?? false,
      semesterCode: json['semester_code'] as String?,
      track: json['track'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'course_code': instance.courseCode,
      'course_name': instance.courseName,
      'assign_date': instance.assignDate?.toIso8601String(),
      'due_date': instance.dueDate?.toIso8601String(),
      'submission_type': instance.submissionType,
      'type': instance.type,
      'is_completed': instance.isCompleted,
      'is_missed': instance.isMissed,
      'semester_code': instance.semesterCode,
      'track': instance.track,
      'created_at': instance.createdAt?.toIso8601String(),
    };
