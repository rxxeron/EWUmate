// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_material.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StudyMaterial _$StudyMaterialFromJson(Map<String, dynamic> json) {
  return _StudyMaterial.fromJson(json);
}

/// @nodoc
mixin _$StudyMaterial {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'uploader_id')
  String get uploaderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'faculty_initial')
  String? get facultyInitial => throw _privateConstructorUsedError;
  @JsonKey(name: 'course_code')
  String? get courseCode => throw _privateConstructorUsedError;
  String? get semester => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_type')
  String? get fileType => throw _privateConstructorUsedError;
  @JsonKey(name: 'drive_file_id')
  String get driveFileId => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_name')
  String get fileName => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_size_bytes')
  int get fileSizeBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'uploader_name')
  String? get uploaderName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudyMaterialCopyWith<StudyMaterial> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudyMaterialCopyWith<$Res> {
  factory $StudyMaterialCopyWith(
          StudyMaterial value, $Res Function(StudyMaterial) then) =
      _$StudyMaterialCopyWithImpl<$Res, StudyMaterial>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'uploader_id') String uploaderId,
      @JsonKey(name: 'faculty_initial') String? facultyInitial,
      @JsonKey(name: 'course_code') String? courseCode,
      String? semester,
      @JsonKey(name: 'file_type') String? fileType,
      @JsonKey(name: 'drive_file_id') String driveFileId,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_size_bytes') int fileSizeBytes,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      String status,
      @JsonKey(name: 'uploader_name') String? uploaderName});
}

/// @nodoc
class _$StudyMaterialCopyWithImpl<$Res, $Val extends StudyMaterial>
    implements $StudyMaterialCopyWith<$Res> {
  _$StudyMaterialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? uploaderId = null,
    Object? facultyInitial = freezed,
    Object? courseCode = freezed,
    Object? semester = freezed,
    Object? fileType = freezed,
    Object? driveFileId = null,
    Object? fileName = null,
    Object? fileSizeBytes = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? status = null,
    Object? uploaderName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      uploaderId: null == uploaderId
          ? _value.uploaderId
          : uploaderId // ignore: cast_nullable_to_non_nullable
              as String,
      facultyInitial: freezed == facultyInitial
          ? _value.facultyInitial
          : facultyInitial // ignore: cast_nullable_to_non_nullable
              as String?,
      courseCode: freezed == courseCode
          ? _value.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      semester: freezed == semester
          ? _value.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String?,
      fileType: freezed == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      driveFileId: null == driveFileId
          ? _value.driveFileId
          : driveFileId // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileSizeBytes: null == fileSizeBytes
          ? _value.fileSizeBytes
          : fileSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      uploaderName: freezed == uploaderName
          ? _value.uploaderName
          : uploaderName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudyMaterialImplCopyWith<$Res>
    implements $StudyMaterialCopyWith<$Res> {
  factory _$$StudyMaterialImplCopyWith(
          _$StudyMaterialImpl value, $Res Function(_$StudyMaterialImpl) then) =
      __$$StudyMaterialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'uploader_id') String uploaderId,
      @JsonKey(name: 'faculty_initial') String? facultyInitial,
      @JsonKey(name: 'course_code') String? courseCode,
      String? semester,
      @JsonKey(name: 'file_type') String? fileType,
      @JsonKey(name: 'drive_file_id') String driveFileId,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_size_bytes') int fileSizeBytes,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      String status,
      @JsonKey(name: 'uploader_name') String? uploaderName});
}

/// @nodoc
class __$$StudyMaterialImplCopyWithImpl<$Res>
    extends _$StudyMaterialCopyWithImpl<$Res, _$StudyMaterialImpl>
    implements _$$StudyMaterialImplCopyWith<$Res> {
  __$$StudyMaterialImplCopyWithImpl(
      _$StudyMaterialImpl _value, $Res Function(_$StudyMaterialImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? uploaderId = null,
    Object? facultyInitial = freezed,
    Object? courseCode = freezed,
    Object? semester = freezed,
    Object? fileType = freezed,
    Object? driveFileId = null,
    Object? fileName = null,
    Object? fileSizeBytes = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? status = null,
    Object? uploaderName = freezed,
  }) {
    return _then(_$StudyMaterialImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      uploaderId: null == uploaderId
          ? _value.uploaderId
          : uploaderId // ignore: cast_nullable_to_non_nullable
              as String,
      facultyInitial: freezed == facultyInitial
          ? _value.facultyInitial
          : facultyInitial // ignore: cast_nullable_to_non_nullable
              as String?,
      courseCode: freezed == courseCode
          ? _value.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      semester: freezed == semester
          ? _value.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String?,
      fileType: freezed == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      driveFileId: null == driveFileId
          ? _value.driveFileId
          : driveFileId // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileSizeBytes: null == fileSizeBytes
          ? _value.fileSizeBytes
          : fileSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      uploaderName: freezed == uploaderName
          ? _value.uploaderName
          : uploaderName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudyMaterialImpl implements _StudyMaterial {
  const _$StudyMaterialImpl(
      {required this.id,
      @JsonKey(name: 'uploader_id') required this.uploaderId,
      @JsonKey(name: 'faculty_initial') this.facultyInitial,
      @JsonKey(name: 'course_code') this.courseCode,
      this.semester,
      @JsonKey(name: 'file_type') this.fileType,
      @JsonKey(name: 'drive_file_id') required this.driveFileId,
      @JsonKey(name: 'file_name') required this.fileName,
      @JsonKey(name: 'file_size_bytes') required this.fileSizeBytes,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      this.status = 'pending',
      @JsonKey(name: 'uploader_name') this.uploaderName});

  factory _$StudyMaterialImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudyMaterialImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'uploader_id')
  final String uploaderId;
  @override
  @JsonKey(name: 'faculty_initial')
  final String? facultyInitial;
  @override
  @JsonKey(name: 'course_code')
  final String? courseCode;
  @override
  final String? semester;
  @override
  @JsonKey(name: 'file_type')
  final String? fileType;
  @override
  @JsonKey(name: 'drive_file_id')
  final String driveFileId;
  @override
  @JsonKey(name: 'file_name')
  final String fileName;
  @override
  @JsonKey(name: 'file_size_bytes')
  final int fileSizeBytes;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'uploader_name')
  final String? uploaderName;

  @override
  String toString() {
    return 'StudyMaterial(id: $id, uploaderId: $uploaderId, facultyInitial: $facultyInitial, courseCode: $courseCode, semester: $semester, fileType: $fileType, driveFileId: $driveFileId, fileName: $fileName, fileSizeBytes: $fileSizeBytes, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, uploaderName: $uploaderName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudyMaterialImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.uploaderId, uploaderId) ||
                other.uploaderId == uploaderId) &&
            (identical(other.facultyInitial, facultyInitial) ||
                other.facultyInitial == facultyInitial) &&
            (identical(other.courseCode, courseCode) ||
                other.courseCode == courseCode) &&
            (identical(other.semester, semester) ||
                other.semester == semester) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.driveFileId, driveFileId) ||
                other.driveFileId == driveFileId) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSizeBytes, fileSizeBytes) ||
                other.fileSizeBytes == fileSizeBytes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.uploaderName, uploaderName) ||
                other.uploaderName == uploaderName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      uploaderId,
      facultyInitial,
      courseCode,
      semester,
      fileType,
      driveFileId,
      fileName,
      fileSizeBytes,
      createdAt,
      updatedAt,
      status,
      uploaderName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudyMaterialImplCopyWith<_$StudyMaterialImpl> get copyWith =>
      __$$StudyMaterialImplCopyWithImpl<_$StudyMaterialImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudyMaterialImplToJson(
      this,
    );
  }
}

abstract class _StudyMaterial implements StudyMaterial {
  const factory _StudyMaterial(
          {required final String id,
          @JsonKey(name: 'uploader_id') required final String uploaderId,
          @JsonKey(name: 'faculty_initial') final String? facultyInitial,
          @JsonKey(name: 'course_code') final String? courseCode,
          final String? semester,
          @JsonKey(name: 'file_type') final String? fileType,
          @JsonKey(name: 'drive_file_id') required final String driveFileId,
          @JsonKey(name: 'file_name') required final String fileName,
          @JsonKey(name: 'file_size_bytes') required final int fileSizeBytes,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt,
          final String status,
          @JsonKey(name: 'uploader_name') final String? uploaderName}) =
      _$StudyMaterialImpl;

  factory _StudyMaterial.fromJson(Map<String, dynamic> json) =
      _$StudyMaterialImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'uploader_id')
  String get uploaderId;
  @override
  @JsonKey(name: 'faculty_initial')
  String? get facultyInitial;
  @override
  @JsonKey(name: 'course_code')
  String? get courseCode;
  @override
  String? get semester;
  @override
  @JsonKey(name: 'file_type')
  String? get fileType;
  @override
  @JsonKey(name: 'drive_file_id')
  String get driveFileId;
  @override
  @JsonKey(name: 'file_name')
  String get fileName;
  @override
  @JsonKey(name: 'file_size_bytes')
  int get fileSizeBytes;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  String get status;
  @override
  @JsonKey(name: 'uploader_name')
  String? get uploaderName;
  @override
  @JsonKey(ignore: true)
  _$$StudyMaterialImplCopyWith<_$StudyMaterialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
