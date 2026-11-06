// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_material.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StudyMaterial {
  String get id;
  @JsonKey(name: 'uploader_id')
  String get uploaderId;
  @JsonKey(name: 'faculty_initial')
  String? get facultyInitial;
  @JsonKey(name: 'course_code')
  String? get courseCode;
  String? get semester;
  @JsonKey(name: 'file_type')
  String? get fileType;
  @JsonKey(name: 'drive_file_id')
  String get driveFileId;
  @JsonKey(name: 'file_name')
  String get fileName;
  @JsonKey(name: 'file_size_bytes')
  int get fileSizeBytes;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  String get status;
  @JsonKey(name: 'uploader_name')
  String? get uploaderName;

  /// Create a copy of StudyMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StudyMaterialCopyWith<StudyMaterial> get copyWith =>
      _$StudyMaterialCopyWithImpl<StudyMaterial>(
          this as StudyMaterial, _$identity);

  /// Serializes this StudyMaterial to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as StudyMaterial;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StudyMaterial &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.uploaderId, _this.uploaderId) ||
                other.uploaderId == _this.uploaderId) &&
            (identical(other.facultyInitial, _this.facultyInitial) ||
                other.facultyInitial == _this.facultyInitial) &&
            (identical(other.courseCode, _this.courseCode) ||
                other.courseCode == _this.courseCode) &&
            (identical(other.semester, _this.semester) ||
                other.semester == _this.semester) &&
            (identical(other.fileType, _this.fileType) ||
                other.fileType == _this.fileType) &&
            (identical(other.driveFileId, _this.driveFileId) ||
                other.driveFileId == _this.driveFileId) &&
            (identical(other.fileName, _this.fileName) ||
                other.fileName == _this.fileName) &&
            (identical(other.fileSizeBytes, _this.fileSizeBytes) ||
                other.fileSizeBytes == _this.fileSizeBytes) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.uploaderName, _this.uploaderName) ||
                other.uploaderName == _this.uploaderName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as StudyMaterial;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.uploaderId,
        _this.facultyInitial,
        _this.courseCode,
        _this.semester,
        _this.fileType,
        _this.driveFileId,
        _this.fileName,
        _this.fileSizeBytes,
        _this.createdAt,
        _this.updatedAt,
        _this.status,
        _this.uploaderName);
  }

  @override
  String toString() {
    final _this = this as StudyMaterial;
    return 'StudyMaterial(id: ${_this.id}, uploaderId: ${_this.uploaderId}, facultyInitial: ${_this.facultyInitial}, courseCode: ${_this.courseCode}, semester: ${_this.semester}, fileType: ${_this.fileType}, driveFileId: ${_this.driveFileId}, fileName: ${_this.fileName}, fileSizeBytes: ${_this.fileSizeBytes}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, status: ${_this.status}, uploaderName: ${_this.uploaderName})';
  }
}

/// @nodoc
abstract mixin class $StudyMaterialCopyWith<$Res> {
  factory $StudyMaterialCopyWith(
          StudyMaterial value, $Res Function(StudyMaterial) _then) =
      _$StudyMaterialCopyWithImpl;
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
class _$StudyMaterialCopyWithImpl<$Res>
    implements $StudyMaterialCopyWith<$Res> {
  _$StudyMaterialCopyWithImpl(this._self, this._then);

  final StudyMaterial _self;
  final $Res Function(StudyMaterial) _then;

  /// Create a copy of StudyMaterial
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(StudyMaterial(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      uploaderId: null == uploaderId
          ? _self.uploaderId
          : uploaderId // ignore: cast_nullable_to_non_nullable
              as String,
      facultyInitial: freezed == facultyInitial
          ? _self.facultyInitial
          : facultyInitial // ignore: cast_nullable_to_non_nullable
              as String?,
      courseCode: freezed == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      semester: freezed == semester
          ? _self.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String?,
      fileType: freezed == fileType
          ? _self.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      driveFileId: null == driveFileId
          ? _self.driveFileId
          : driveFileId // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileSizeBytes: null == fileSizeBytes
          ? _self.fileSizeBytes
          : fileSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      uploaderName: freezed == uploaderName
          ? _self.uploaderName
          : uploaderName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [StudyMaterial].
extension StudyMaterialPatterns on StudyMaterial {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_StudyMaterial value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StudyMaterial() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_StudyMaterial value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StudyMaterial():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_StudyMaterial value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StudyMaterial() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
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
            @JsonKey(name: 'uploader_name') String? uploaderName)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StudyMaterial() when $default != null:
        return $default(
            _that.id,
            _that.uploaderId,
            _that.facultyInitial,
            _that.courseCode,
            _that.semester,
            _that.fileType,
            _that.driveFileId,
            _that.fileName,
            _that.fileSizeBytes,
            _that.createdAt,
            _that.updatedAt,
            _that.status,
            _that.uploaderName);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
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
            @JsonKey(name: 'uploader_name') String? uploaderName)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StudyMaterial():
        return $default(
            _that.id,
            _that.uploaderId,
            _that.facultyInitial,
            _that.courseCode,
            _that.semester,
            _that.fileType,
            _that.driveFileId,
            _that.fileName,
            _that.fileSizeBytes,
            _that.createdAt,
            _that.updatedAt,
            _that.status,
            _that.uploaderName);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
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
            @JsonKey(name: 'uploader_name') String? uploaderName)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StudyMaterial() when $default != null:
        return $default(
            _that.id,
            _that.uploaderId,
            _that.facultyInitial,
            _that.courseCode,
            _that.semester,
            _that.fileType,
            _that.driveFileId,
            _that.fileName,
            _that.fileSizeBytes,
            _that.createdAt,
            _that.updatedAt,
            _that.status,
            _that.uploaderName);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _StudyMaterial implements StudyMaterial {
  const _StudyMaterial(
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
  factory _StudyMaterial.fromJson(Map<String, dynamic> json) =>
      _$StudyMaterialFromJson(json);

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

  /// Create a copy of StudyMaterial
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StudyMaterialCopyWith<_StudyMaterial> get copyWith =>
      __$StudyMaterialCopyWithImpl<_StudyMaterial>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StudyMaterialToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StudyMaterial &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
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
  }

  @override
  String toString() {
    return 'StudyMaterial(id: $id, uploaderId: $uploaderId, facultyInitial: $facultyInitial, courseCode: $courseCode, semester: $semester, fileType: $fileType, driveFileId: $driveFileId, fileName: $fileName, fileSizeBytes: $fileSizeBytes, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, uploaderName: $uploaderName)';
  }
}

/// @nodoc
abstract mixin class _$StudyMaterialCopyWith<$Res>
    implements $StudyMaterialCopyWith<$Res> {
  factory _$StudyMaterialCopyWith(
          _StudyMaterial value, $Res Function(_StudyMaterial) _then) =
      __$StudyMaterialCopyWithImpl;
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
class __$StudyMaterialCopyWithImpl<$Res>
    implements _$StudyMaterialCopyWith<$Res> {
  __$StudyMaterialCopyWithImpl(this._self, this._then);

  final _StudyMaterial _self;
  final $Res Function(_StudyMaterial) _then;

  /// Create a copy of StudyMaterial
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_StudyMaterial(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      uploaderId: null == uploaderId
          ? _self.uploaderId
          : uploaderId // ignore: cast_nullable_to_non_nullable
              as String,
      facultyInitial: freezed == facultyInitial
          ? _self.facultyInitial
          : facultyInitial // ignore: cast_nullable_to_non_nullable
              as String?,
      courseCode: freezed == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      semester: freezed == semester
          ? _self.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String?,
      fileType: freezed == fileType
          ? _self.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      driveFileId: null == driveFileId
          ? _self.driveFileId
          : driveFileId // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileSizeBytes: null == fileSizeBytes
          ? _self.fileSizeBytes
          : fileSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      uploaderName: freezed == uploaderName
          ? _self.uploaderName
          : uploaderName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
