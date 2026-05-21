import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_material.freezed.dart';
part 'study_material.g.dart';

@freezed
class StudyMaterial with _$StudyMaterial {
  const factory StudyMaterial({
    required String id,
    @JsonKey(name: 'uploader_id') required String uploaderId,
    @JsonKey(name: 'faculty_initial') String? facultyInitial,
    @JsonKey(name: 'course_code') String? courseCode,
    String? semester,
    @JsonKey(name: 'file_type') String? fileType,
    @JsonKey(name: 'drive_file_id') required String driveFileId,
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'file_size_bytes') required int fileSizeBytes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @Default('pending') String status,
    @JsonKey(name: 'uploader_name') String? uploaderName,
  }) = _StudyMaterial;

  factory StudyMaterial.fromJson(Map<String, dynamic> json) =>
      _$StudyMaterialFromJson(StudyMaterial._preprocessJson(json));

  static Map<String, dynamic> _preprocessJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    final uploaderName = profiles?['full_name'] as String?;
    return {
      ...json,
      if (uploaderName != null) 'uploader_name': uploaderName,
    };
  }
}

