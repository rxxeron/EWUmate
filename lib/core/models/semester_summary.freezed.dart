// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semester_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SemesterSummary _$SemesterSummaryFromJson(Map<String, dynamic> json) {
  return _SemesterSummary.fromJson(json);
}

/// @nodoc
mixin _$SemesterSummary {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'semester_code')
  String get semesterCode => throw _privateConstructorUsedError;
  double? get tgpa => throw _privateConstructorUsedError;
  double? get cgpa => throw _privateConstructorUsedError;
  @JsonKey(name: 'credits_earned')
  double? get creditsEarned => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_credits_earned')
  double? get totalCreditsEarned => throw _privateConstructorUsedError;
  List<dynamic> get courses => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SemesterSummaryCopyWith<SemesterSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SemesterSummaryCopyWith<$Res> {
  factory $SemesterSummaryCopyWith(
          SemesterSummary value, $Res Function(SemesterSummary) then) =
      _$SemesterSummaryCopyWithImpl<$Res, SemesterSummary>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      double? tgpa,
      double? cgpa,
      @JsonKey(name: 'credits_earned') double? creditsEarned,
      @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
      List<dynamic> courses,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$SemesterSummaryCopyWithImpl<$Res, $Val extends SemesterSummary>
    implements $SemesterSummaryCopyWith<$Res> {
  _$SemesterSummaryCopyWithImpl(this._value, this._then);

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
    Object? tgpa = freezed,
    Object? cgpa = freezed,
    Object? creditsEarned = freezed,
    Object? totalCreditsEarned = freezed,
    Object? courses = null,
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
      tgpa: freezed == tgpa
          ? _value.tgpa
          : tgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      cgpa: freezed == cgpa
          ? _value.cgpa
          : cgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      creditsEarned: freezed == creditsEarned
          ? _value.creditsEarned
          : creditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCreditsEarned: freezed == totalCreditsEarned
          ? _value.totalCreditsEarned
          : totalCreditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      courses: null == courses
          ? _value.courses
          : courses // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SemesterSummaryImplCopyWith<$Res>
    implements $SemesterSummaryCopyWith<$Res> {
  factory _$$SemesterSummaryImplCopyWith(_$SemesterSummaryImpl value,
          $Res Function(_$SemesterSummaryImpl) then) =
      __$$SemesterSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      double? tgpa,
      double? cgpa,
      @JsonKey(name: 'credits_earned') double? creditsEarned,
      @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
      List<dynamic> courses,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$SemesterSummaryImplCopyWithImpl<$Res>
    extends _$SemesterSummaryCopyWithImpl<$Res, _$SemesterSummaryImpl>
    implements _$$SemesterSummaryImplCopyWith<$Res> {
  __$$SemesterSummaryImplCopyWithImpl(
      _$SemesterSummaryImpl _value, $Res Function(_$SemesterSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? semesterCode = null,
    Object? tgpa = freezed,
    Object? cgpa = freezed,
    Object? creditsEarned = freezed,
    Object? totalCreditsEarned = freezed,
    Object? courses = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$SemesterSummaryImpl(
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
      tgpa: freezed == tgpa
          ? _value.tgpa
          : tgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      cgpa: freezed == cgpa
          ? _value.cgpa
          : cgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      creditsEarned: freezed == creditsEarned
          ? _value.creditsEarned
          : creditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCreditsEarned: freezed == totalCreditsEarned
          ? _value.totalCreditsEarned
          : totalCreditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      courses: null == courses
          ? _value._courses
          : courses // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SemesterSummaryImpl implements _SemesterSummary {
  const _$SemesterSummaryImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'semester_code') required this.semesterCode,
      this.tgpa,
      this.cgpa,
      @JsonKey(name: 'credits_earned') this.creditsEarned,
      @JsonKey(name: 'total_credits_earned') this.totalCreditsEarned,
      final List<dynamic> courses = const [],
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _courses = courses;

  factory _$SemesterSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$SemesterSummaryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'semester_code')
  final String semesterCode;
  @override
  final double? tgpa;
  @override
  final double? cgpa;
  @override
  @JsonKey(name: 'credits_earned')
  final double? creditsEarned;
  @override
  @JsonKey(name: 'total_credits_earned')
  final double? totalCreditsEarned;
  final List<dynamic> _courses;
  @override
  @JsonKey()
  List<dynamic> get courses {
    if (_courses is EqualUnmodifiableListView) return _courses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_courses);
  }

  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SemesterSummary(id: $id, userId: $userId, semesterCode: $semesterCode, tgpa: $tgpa, cgpa: $cgpa, creditsEarned: $creditsEarned, totalCreditsEarned: $totalCreditsEarned, courses: $courses, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SemesterSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.semesterCode, semesterCode) ||
                other.semesterCode == semesterCode) &&
            (identical(other.tgpa, tgpa) || other.tgpa == tgpa) &&
            (identical(other.cgpa, cgpa) || other.cgpa == cgpa) &&
            (identical(other.creditsEarned, creditsEarned) ||
                other.creditsEarned == creditsEarned) &&
            (identical(other.totalCreditsEarned, totalCreditsEarned) ||
                other.totalCreditsEarned == totalCreditsEarned) &&
            const DeepCollectionEquality().equals(other._courses, _courses) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      semesterCode,
      tgpa,
      cgpa,
      creditsEarned,
      totalCreditsEarned,
      const DeepCollectionEquality().hash(_courses),
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SemesterSummaryImplCopyWith<_$SemesterSummaryImpl> get copyWith =>
      __$$SemesterSummaryImplCopyWithImpl<_$SemesterSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SemesterSummaryImplToJson(
      this,
    );
  }
}

abstract class _SemesterSummary implements SemesterSummary {
  const factory _SemesterSummary(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'semester_code') required final String semesterCode,
      final double? tgpa,
      final double? cgpa,
      @JsonKey(name: 'credits_earned') final double? creditsEarned,
      @JsonKey(name: 'total_credits_earned') final double? totalCreditsEarned,
      final List<dynamic> courses,
      @JsonKey(name: 'updated_at')
      final DateTime? updatedAt}) = _$SemesterSummaryImpl;

  factory _SemesterSummary.fromJson(Map<String, dynamic> json) =
      _$SemesterSummaryImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  @override
  double? get tgpa;
  @override
  double? get cgpa;
  @override
  @JsonKey(name: 'credits_earned')
  double? get creditsEarned;
  @override
  @JsonKey(name: 'total_credits_earned')
  double? get totalCreditsEarned;
  @override
  List<dynamic> get courses;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SemesterSummaryImplCopyWith<_$SemesterSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
