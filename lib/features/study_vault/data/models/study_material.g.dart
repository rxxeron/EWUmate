// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudyMaterialImpl _$$StudyMaterialImplFromJson(Map<String, dynamic> json) =>
    _$StudyMaterialImpl(
      id: json['id'] as String,
      uploaderId: json['uploader_id'] as String,
      facultyInitial: json['faculty_initial'] as String?,
      courseCode: json['course_code'] as String?,
      semester: json['semester'] as String?,
      fileType: json['file_type'] as String?,
      driveFileId: json['drive_file_id'] as String,
      fileName: json['file_name'] as String,
      fileSizeBytes: (json['file_size_bytes'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      status: json['status'] as String? ?? 'pending',
      uploaderName: json['uploader_name'] as String?,
    );

Map<String, dynamic> _$$StudyMaterialImplToJson(_$StudyMaterialImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uploader_id': instance.uploaderId,
      'faculty_initial': instance.facultyInitial,
      'course_code': instance.courseCode,
      'semester': instance.semester,
      'file_type': instance.fileType,
      'drive_file_id': instance.driveFileId,
      'file_name': instance.fileName,
      'file_size_bytes': instance.fileSizeBytes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'status': instance.status,
      'uploader_name': instance.uploaderName,
    };
