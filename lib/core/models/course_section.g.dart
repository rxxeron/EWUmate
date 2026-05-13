// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CourseSessionImpl _$$CourseSessionImplFromJson(Map<String, dynamic> json) =>
    _$CourseSessionImpl(
      type: json['type'] as String? ?? 'Theory',
      day: json['day'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      room: json['room'] as String? ?? '',
      faculty: json['faculty'] as String? ?? '',
    );

Map<String, dynamic> _$$CourseSessionImplToJson(_$CourseSessionImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'day': instance.day,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'room': instance.room,
      'faculty': instance.faculty,
    };

_$CourseSectionImpl _$$CourseSectionImplFromJson(Map<String, dynamic> json) =>
    _$CourseSectionImpl(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      facultyInitials: json['faculty_initials'] as String? ?? '',
      section: json['section'] as String? ?? '',
      capacity: json['capacity'] as String? ?? '',
      credits: json['credits'] as String? ?? '3.0',
      semester: json['semester'] as String? ?? '',
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) => CourseSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      docId: json['doc_id'] as String? ?? '',
    );

Map<String, dynamic> _$$CourseSectionImplToJson(_$CourseSectionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'course_name': instance.courseName,
      'faculty_initials': instance.facultyInitials,
      'section': instance.section,
      'capacity': instance.capacity,
      'credits': instance.credits,
      'semester': instance.semester,
      'sessions': instance.sessions,
      'doc_id': instance.docId,
    };
