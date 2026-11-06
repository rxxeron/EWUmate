// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourseMetadata _$CourseMetadataFromJson(Map<String, dynamic> json) =>
    _CourseMetadata(
      code: json['code'] as String,
      name: json['name'] as String,
      creditVal: (json['credit_val'] as num).toDouble(),
    );

Map<String, dynamic> _$CourseMetadataToJson(_CourseMetadata instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'credit_val': instance.creditVal,
    };
