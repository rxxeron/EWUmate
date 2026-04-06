// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnrollmentImpl _$$EnrollmentImplFromJson(Map<String, dynamic> json) =>
    _$EnrollmentImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      semesterCode: json['semester_code'] as String,
      courseCode: json['course_code'] as String,
      sectionId: json['section_id'] as String?,
      section: json['section'] as String?,
      status: json['status'] as String? ?? 'enrolled',
      grade: json['grade'] as String?,
      gradePoints: (json['grade_points'] as num?)?.toDouble(),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$EnrollmentImplToJson(_$EnrollmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'semester_code': instance.semesterCode,
      'course_code': instance.courseCode,
      'section_id': instance.sectionId,
      'section': instance.section,
      'status': instance.status,
      'grade': instance.grade,
      'grade_points': instance.gradePoints,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
