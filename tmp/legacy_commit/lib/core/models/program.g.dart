// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProgramImpl _$$ProgramImplFromJson(Map<String, dynamic> json) =>
    _$ProgramImpl(
      programCode: json['program_code'] as String,
      name: json['name'] as String,
      track: json['track'] as String,
      totalDegreeCredits:
          (json['total_degree_credits'] as num?)?.toDouble() ?? 130.0,
      departmentName: json['department_name'] as String?,
    );

Map<String, dynamic> _$$ProgramImplToJson(_$ProgramImpl instance) =>
    <String, dynamic>{
      'program_code': instance.programCode,
      'name': instance.name,
      'track': instance.track,
      'total_degree_credits': instance.totalDegreeCredits,
      'department_name': instance.departmentName,
    };
