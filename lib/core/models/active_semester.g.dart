// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_semester.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActiveSemesterImpl _$$ActiveSemesterImplFromJson(Map<String, dynamic> json) =>
    _$ActiveSemesterImpl(
      track: json['track'] as String,
      currentSemesterCode: json['current_semester_code'] as String?,
      nextSemesterCode: json['next_semester_code'] as String?,
      classesStartDate: json['classes_start_date'] == null
          ? null
          : DateTime.parse(json['classes_start_date'] as String),
      classesEndDate: json['classes_end_date'] == null
          ? null
          : DateTime.parse(json['classes_end_date'] as String),
      advisingStartDate: json['advising_start_date'] == null
          ? null
          : DateTime.parse(json['advising_start_date'] as String),
      advisingEndDate: json['advising_end_date'] == null
          ? null
          : DateTime.parse(json['advising_end_date'] as String),
      finalExamStart: json['final_exam_start'] == null
          ? null
          : DateTime.parse(json['final_exam_start'] as String),
      finalExamEnd: json['final_exam_end'] == null
          ? null
          : DateTime.parse(json['final_exam_end'] as String),
      gradeSubmissionStart: json['grade_submission_start'] == null
          ? null
          : DateTime.parse(json['grade_submission_start'] as String),
      gradeSubmissionDeadline: json['grade_submission_deadline'] == null
          ? null
          : DateTime.parse(json['grade_submission_deadline'] as String),
      semesterSwitchDate: json['semester_switch_date'] == null
          ? null
          : DateTime.parse(json['semester_switch_date'] as String),
      upcomingClassesStartDate: json['upcoming_classes_start_date'] == null
          ? null
          : DateTime.parse(json['upcoming_classes_start_date'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ActiveSemesterImplToJson(
        _$ActiveSemesterImpl instance) =>
    <String, dynamic>{
      'track': instance.track,
      'current_semester_code': instance.currentSemesterCode,
      'next_semester_code': instance.nextSemesterCode,
      'classes_start_date': instance.classesStartDate?.toIso8601String(),
      'classes_end_date': instance.classesEndDate?.toIso8601String(),
      'advising_start_date': instance.advisingStartDate?.toIso8601String(),
      'advising_end_date': instance.advisingEndDate?.toIso8601String(),
      'final_exam_start': instance.finalExamStart?.toIso8601String(),
      'final_exam_end': instance.finalExamEnd?.toIso8601String(),
      'grade_submission_start':
          instance.gradeSubmissionStart?.toIso8601String(),
      'grade_submission_deadline':
          instance.gradeSubmissionDeadline?.toIso8601String(),
      'semester_switch_date': instance.semesterSwitchDate?.toIso8601String(),
      'upcoming_classes_start_date':
          instance.upcomingClassesStartDate?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
