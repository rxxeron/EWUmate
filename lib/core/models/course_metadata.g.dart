// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CourseMetadataImpl _$$CourseMetadataImplFromJson(Map<String, dynamic> json) =>
    _$CourseMetadataImpl(
      code: json['code'] as String,
      name: json['name'] as String,
      creditVal: (json['credit_val'] as num).toDouble(),
    );

Map<String, dynamic> _$$CourseMetadataImplToJson(
        _$CourseMetadataImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'credit_val': instance.creditVal,
    };
