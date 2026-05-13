// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleExceptionImpl _$$ScheduleExceptionImplFromJson(
        Map<String, dynamic> json) =>
    _$ScheduleExceptionImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      courseCode: json['course_code'] as String?,
      courseName: json['course_name'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      room: json['room'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ScheduleExceptionImplToJson(
        _$ScheduleExceptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': instance.type,
      'date': instance.date.toIso8601String(),
      'course_code': instance.courseCode,
      'course_name': instance.courseName,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'room': instance.room,
      'metadata': instance.metadata,
    };
