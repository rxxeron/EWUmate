// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academic_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AcademicStateImpl _$$AcademicStateImplFromJson(Map<String, dynamic> json) =>
    _$AcademicStateImpl(
      track: json['track'] as String,
      currentSemesterCode: json['current_semester_code'] as String,
      nextSemesterCode: json['next_semester_code'] as String,
      advisingStartDate: json['advising_start_date'] == null
          ? null
          : DateTime.parse(json['advising_start_date'] as String),
      advisingEndDate: json['advising_end_date'] == null
          ? null
          : DateTime.parse(json['advising_end_date'] as String),
      classesStartDate: json['classes_start_date'] == null
          ? null
          : DateTime.parse(json['classes_start_date'] as String),
      semesterSwitchDate: json['semester_switch_date'] == null
          ? null
          : DateTime.parse(json['semester_switch_date'] as String),
      upcomingClassesStartDate: json['upcoming_classes_start_date'] == null
          ? null
          : DateTime.parse(json['upcoming_classes_start_date'] as String),
    );

Map<String, dynamic> _$$AcademicStateImplToJson(_$AcademicStateImpl instance) =>
    <String, dynamic>{
      'track': instance.track,
      'current_semester_code': instance.currentSemesterCode,
      'next_semester_code': instance.nextSemesterCode,
      'advising_start_date': instance.advisingStartDate?.toIso8601String(),
      'advising_end_date': instance.advisingEndDate?.toIso8601String(),
      'classes_start_date': instance.classesStartDate?.toIso8601String(),
      'semester_switch_date': instance.semesterSwitchDate?.toIso8601String(),
      'upcoming_classes_start_date':
          instance.upcomingClassesStartDate?.toIso8601String(),
    };
