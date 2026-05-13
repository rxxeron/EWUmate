// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enrollment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Enrollment _$EnrollmentFromJson(Map<String, dynamic> json) {
  return _Enrollment.fromJson(json);
}

/// @nodoc
mixin _$Enrollment {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'semester_code')
  String get semesterCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'course_code')
  String get courseCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'section_id')
  String? get sectionId => throw _privateConstructorUsedError;
  String? get section => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get grade => throw _privateConstructorUsedError;
  @JsonKey(name: 'grade_points')
  double? get gradePoints => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EnrollmentCopyWith<Enrollment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnrollmentCopyWith<$Res> {
  factory $EnrollmentCopyWith(
          Enrollment value, $Res Function(Enrollment) then) =
      _$EnrollmentCopyWithImpl<$Res, Enrollment>;
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
class _$EnrollmentCopyWithImpl<$Res, $Val extends Enrollment>
    implements $EnrollmentCopyWith<$Res> {
  _$EnrollmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _value.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _value.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: freezed == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      section: freezed == section
          ? _value.section
          : section // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      grade: freezed == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String?,
      gradePoints: freezed == gradePoints
          ? _value.gradePoints
          : gradePoints // ignore: cast_nullable_to_non_nullable
              as double?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EnrollmentImplCopyWith<$Res>
    implements $EnrollmentCopyWith<$Res> {
  factory _$$EnrollmentImplCopyWith(
          _$EnrollmentImpl value, $Res Function(_$EnrollmentImpl) then) =
      __$$EnrollmentImplCopyWithImpl<$Res>;
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
class __$$EnrollmentImplCopyWithImpl<$Res>
    extends _$EnrollmentCopyWithImpl<$Res, _$EnrollmentImpl>
    implements _$$EnrollmentImplCopyWith<$Res> {
  __$$EnrollmentImplCopyWithImpl(
      _$EnrollmentImpl _value, $Res Function(_$EnrollmentImpl) _then)
      : super(_value, _then);

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
    return _then(_$EnrollmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _value.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _value.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: freezed == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      section: freezed == section
          ? _value.section
          : section // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      grade: freezed == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String?,
      gradePoints: freezed == gradePoints
          ? _value.gradePoints
          : gradePoints // ignore: cast_nullable_to_non_nullable
              as double?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnrollmentImpl implements _Enrollment {
  const _$EnrollmentImpl(
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

  factory _$EnrollmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnrollmentImplFromJson(json);

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

  @override
  String toString() {
    return 'Enrollment(id: $id, userId: $userId, semesterCode: $semesterCode, courseCode: $courseCode, sectionId: $sectionId, section: $section, status: $status, grade: $grade, gradePoints: $gradePoints, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnrollmentImpl &&
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

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, semesterCode,
      courseCode, sectionId, section, status, grade, gradePoints, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EnrollmentImplCopyWith<_$EnrollmentImpl> get copyWith =>
      __$$EnrollmentImplCopyWithImpl<_$EnrollmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnrollmentImplToJson(
      this,
    );
  }
}

abstract class _Enrollment implements Enrollment {
  const factory _Enrollment(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'semester_code') required final String semesterCode,
          @JsonKey(name: 'course_code') required final String courseCode,
          @JsonKey(name: 'section_id') final String? sectionId,
          final String? section,
          final String status,
          final String? grade,
          @JsonKey(name: 'grade_points') final double? gradePoints,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt}) =
      _$EnrollmentImpl;

  factory _Enrollment.fromJson(Map<String, dynamic> json) =
      _$EnrollmentImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  @override
  @JsonKey(name: 'course_code')
  String get courseCode;
  @override
  @JsonKey(name: 'section_id')
  String? get sectionId;
  @override
  String? get section;
  @override
  String get status;
  @override
  String? get grade;
  @override
  @JsonKey(name: 'grade_points')
  double? get gradePoints;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$EnrollmentImplCopyWith<_$EnrollmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
