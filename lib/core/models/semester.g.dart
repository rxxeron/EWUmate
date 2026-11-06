// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Semester _$SemesterFromJson(Map<String, dynamic> json) => _Semester(
      code: json['code'] as String,
      title: json['title'] as String,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SemesterToJson(_Semester instance) => <String, dynamic>{
      'code': instance.code,
      'title': instance.title,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };
