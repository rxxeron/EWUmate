// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enrollment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Enrollment {
  String get id;
  @JsonKey(name: 'user_id')
  String get userId;
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  @JsonKey(name: 'course_code')
  String get courseCode;
  @JsonKey(name: 'section_id')
  String? get sectionId;
  String? get section;
  String get status;
  String? get grade;
  @JsonKey(name: 'grade_points')
  double? get gradePoints;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EnrollmentCopyWith<Enrollment> get copyWith =>
      _$EnrollmentCopyWithImpl<Enrollment>(this as Enrollment, _$identity);

  /// Serializes this Enrollment to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Enrollment;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Enrollment &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.semesterCode, _this.semesterCode) ||
                other.semesterCode == _this.semesterCode) &&
            (identical(other.courseCode, _this.courseCode) ||
                other.courseCode == _this.courseCode) &&
            (identical(other.sectionId, _this.sectionId) ||
                other.sectionId == _this.sectionId) &&
            (identical(other.section, _this.section) ||
                other.section == _this.section) &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.grade, _this.grade) ||
                other.grade == _this.grade) &&
            (identical(other.gradePoints, _this.gradePoints) ||
                other.gradePoints == _this.gradePoints) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Enrollment;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.userId,
        _this.semesterCode,
        _this.courseCode,
        _this.sectionId,
        _this.section,
        _this.status,
        _this.grade,
        _this.gradePoints,
        _this.updatedAt);
  }

  @override
  String toString() {
    final _this = this as Enrollment;
    return 'Enrollment(id: ${_this.id}, userId: ${_this.userId}, semesterCode: ${_this.semesterCode}, courseCode: ${_this.courseCode}, sectionId: ${_this.sectionId}, section: ${_this.section}, status: ${_this.status}, grade: ${_this.grade}, gradePoints: ${_this.gradePoints}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $EnrollmentCopyWith<$Res> {
  factory $EnrollmentCopyWith(
          Enrollment value, $Res Function(Enrollment) _then) =
      _$EnrollmentCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'course_code') String courseCode,
      @JsonKey(name: 'section_id') String? sectionId,
      String? section,
      String status,
      String? grade,
      @JsonKey(name: 'grade_points') double? gradePoints,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$EnrollmentCopyWithImpl<$Res> implements $EnrollmentCopyWith<$Res> {
  _$EnrollmentCopyWithImpl(this._self, this._then);

  final Enrollment _self;
  final $Res Function(Enrollment) _then;

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? semesterCode = null,
    Object? courseCode = null,
    Object? sectionId = freezed,
    Object? section = freezed,
    Object? status = null,
    Object? grade = freezed,
    Object? gradePoints = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(Enrollment(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _self.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: freezed == sectionId
          ? _self.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      section: freezed == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      grade: freezed == grade
          ? _self.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String?,
      gradePoints: freezed == gradePoints
          ? _self.gradePoints
          : gradePoints // ignore: cast_nullable_to_non_nullable
              as double?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Enrollment].
extension EnrollmentPatterns on Enrollment {
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
    TResult Function(_Enrollment value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Enrollment() when $default != null:
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
    TResult Function(_Enrollment value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Enrollment():
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
    TResult? Function(_Enrollment value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Enrollment() when $default != null:
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
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'section_id') String? sectionId,
            String? section,
            String status,
            String? grade,
            @JsonKey(name: 'grade_points') double? gradePoints,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Enrollment() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.courseCode,
            _that.sectionId,
            _that.section,
            _that.status,
            _that.grade,
            _that.gradePoints,
            _that.updatedAt);
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
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'section_id') String? sectionId,
            String? section,
            String status,
            String? grade,
            @JsonKey(name: 'grade_points') double? gradePoints,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Enrollment():
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.courseCode,
            _that.sectionId,
            _that.section,
            _that.status,
            _that.grade,
            _that.gradePoints,
            _that.updatedAt);
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
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'section_id') String? sectionId,
            String? section,
            String status,
            String? grade,
            @JsonKey(name: 'grade_points') double? gradePoints,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Enrollment() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.courseCode,
            _that.sectionId,
            _that.section,
            _that.status,
            _that.grade,
            _that.gradePoints,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Enrollment implements Enrollment {
  const _Enrollment(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'semester_code') required this.semesterCode,
      @JsonKey(name: 'course_code') required this.courseCode,
      @JsonKey(name: 'section_id') this.sectionId,
      this.section,
      this.status = 'enrolled',
      this.grade,
      @JsonKey(name: 'grade_points') this.gradePoints,
      @JsonKey(name: 'updated_at') this.updatedAt});
  factory _Enrollment.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'semester_code')
  final String semesterCode;
  @override
  @JsonKey(name: 'course_code')
  final String courseCode;
  @override
  @JsonKey(name: 'section_id')
  final String? sectionId;
  @override
  final String? section;
  @override
  @JsonKey()
  final String status;
  @override
  final String? grade;
  @override
  @JsonKey(name: 'grade_points')
  final double? gradePoints;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EnrollmentCopyWith<_Enrollment> get copyWith =>
      __$EnrollmentCopyWithImpl<_Enrollment>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EnrollmentToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Enrollment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.semesterCode, semesterCode) ||
                other.semesterCode == semesterCode) &&
            (identical(other.courseCode, courseCode) ||
                other.courseCode == courseCode) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.grade, grade) || other.grade == grade) &&
            (identical(other.gradePoints, gradePoints) ||
                other.gradePoints == gradePoints) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, userId, semesterCode, courseCode,
        sectionId, section, status, grade, gradePoints, updatedAt);
  }

  @override
  String toString() {
    return 'Enrollment(id: $id, userId: $userId, semesterCode: $semesterCode, courseCode: $courseCode, sectionId: $sectionId, section: $section, status: $status, grade: $grade, gradePoints: $gradePoints, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$EnrollmentCopyWith<$Res>
    implements $EnrollmentCopyWith<$Res> {
  factory _$EnrollmentCopyWith(
          _Enrollment value, $Res Function(_Enrollment) _then) =
      __$EnrollmentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'course_code') String courseCode,
      @JsonKey(name: 'section_id') String? sectionId,
      String? section,
      String status,
      String? grade,
      @JsonKey(name: 'grade_points') double? gradePoints,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$EnrollmentCopyWithImpl<$Res> implements _$EnrollmentCopyWith<$Res> {
  __$EnrollmentCopyWithImpl(this._self, this._then);

  final _Enrollment _self;
  final $Res Function(_Enrollment) _then;

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? semesterCode = null,
    Object? courseCode = null,
    Object? sectionId = freezed,
    Object? section = freezed,
    Object? status = null,
    Object? grade = freezed,
    Object? gradePoints = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_Enrollment(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _self.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: freezed == sectionId
          ? _self.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      section: freezed == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      grade: freezed == grade
          ? _self.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String?,
      gradePoints: freezed == gradePoints
          ? _self.gradePoints
          : gradePoints // ignore: cast_nullable_to_non_nullable
              as double?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
