// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semester_analytics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SemesterAnalytics _$SemesterAnalyticsFromJson(Map<String, dynamic> json) {
  return _SemesterAnalytics.fromJson(json);
}

/// @nodoc
mixin _$SemesterAnalytics {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'semester_code')
  String get semesterCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'live_sgpa')
  double? get liveSgpa => throw _privateConstructorUsedError;
  @JsonKey(name: 'live_cgpa')
  double? get liveCgpa => throw _privateConstructorUsedError;
  double? get target => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_credit')
  double? get requiredCredit => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_credit')
  double? get completedCredit => throw _privateConstructorUsedError;
  @JsonKey(name: 'taken_in_this_sem')
  double? get takenInThisSem => throw _privateConstructorUsedError;
  @JsonKey(name: 'credits_left')
  double? get creditsLeft => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SemesterAnalyticsCopyWith<SemesterAnalytics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SemesterAnalyticsCopyWith<$Res> {
  factory $SemesterAnalyticsCopyWith(
          SemesterAnalytics value, $Res Function(SemesterAnalytics) then) =
      _$SemesterAnalyticsCopyWithImpl<$Res, SemesterAnalytics>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'live_sgpa') double? liveSgpa,
      @JsonKey(name: 'live_cgpa') double? liveCgpa,
      double? target,
      @JsonKey(name: 'required_credit') double? requiredCredit,
      @JsonKey(name: 'completed_credit') double? completedCredit,
      @JsonKey(name: 'taken_in_this_sem') double? takenInThisSem,
      @JsonKey(name: 'credits_left') double? creditsLeft,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$SemesterAnalyticsCopyWithImpl<$Res, $Val extends SemesterAnalytics>
    implements $SemesterAnalyticsCopyWith<$Res> {
  _$SemesterAnalyticsCopyWithImpl(this._value, this._then);

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
    Object? liveSgpa = freezed,
    Object? liveCgpa = freezed,
    Object? target = freezed,
    Object? requiredCredit = freezed,
    Object? completedCredit = freezed,
    Object? takenInThisSem = freezed,
    Object? creditsLeft = freezed,
    Object? createdAt = freezed,
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
      liveSgpa: freezed == liveSgpa
          ? _value.liveSgpa
          : liveSgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      liveCgpa: freezed == liveCgpa
          ? _value.liveCgpa
          : liveCgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      target: freezed == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as double?,
      requiredCredit: freezed == requiredCredit
          ? _value.requiredCredit
          : requiredCredit // ignore: cast_nullable_to_non_nullable
              as double?,
      completedCredit: freezed == completedCredit
          ? _value.completedCredit
          : completedCredit // ignore: cast_nullable_to_non_nullable
              as double?,
      takenInThisSem: freezed == takenInThisSem
          ? _value.takenInThisSem
          : takenInThisSem // ignore: cast_nullable_to_non_nullable
              as double?,
      creditsLeft: freezed == creditsLeft
          ? _value.creditsLeft
          : creditsLeft // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SemesterAnalyticsImplCopyWith<$Res>
    implements $SemesterAnalyticsCopyWith<$Res> {
  factory _$$SemesterAnalyticsImplCopyWith(_$SemesterAnalyticsImpl value,
          $Res Function(_$SemesterAnalyticsImpl) then) =
      __$$SemesterAnalyticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'live_sgpa') double? liveSgpa,
      @JsonKey(name: 'live_cgpa') double? liveCgpa,
      double? target,
      @JsonKey(name: 'required_credit') double? requiredCredit,
      @JsonKey(name: 'completed_credit') double? completedCredit,
      @JsonKey(name: 'taken_in_this_sem') double? takenInThisSem,
      @JsonKey(name: 'credits_left') double? creditsLeft,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$SemesterAnalyticsImplCopyWithImpl<$Res>
    extends _$SemesterAnalyticsCopyWithImpl<$Res, _$SemesterAnalyticsImpl>
    implements _$$SemesterAnalyticsImplCopyWith<$Res> {
  __$$SemesterAnalyticsImplCopyWithImpl(_$SemesterAnalyticsImpl _value,
      $Res Function(_$SemesterAnalyticsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? semesterCode = null,
    Object? liveSgpa = freezed,
    Object? liveCgpa = freezed,
    Object? target = freezed,
    Object? requiredCredit = freezed,
    Object? completedCredit = freezed,
    Object? takenInThisSem = freezed,
    Object? creditsLeft = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$SemesterAnalyticsImpl(
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
      liveSgpa: freezed == liveSgpa
          ? _value.liveSgpa
          : liveSgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      liveCgpa: freezed == liveCgpa
          ? _value.liveCgpa
          : liveCgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      target: freezed == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as double?,
      requiredCredit: freezed == requiredCredit
          ? _value.requiredCredit
          : requiredCredit // ignore: cast_nullable_to_non_nullable
              as double?,
      completedCredit: freezed == completedCredit
          ? _value.completedCredit
          : completedCredit // ignore: cast_nullable_to_non_nullable
              as double?,
      takenInThisSem: freezed == takenInThisSem
          ? _value.takenInThisSem
          : takenInThisSem // ignore: cast_nullable_to_non_nullable
              as double?,
      creditsLeft: freezed == creditsLeft
          ? _value.creditsLeft
          : creditsLeft // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SemesterAnalyticsImpl implements _SemesterAnalytics {
  const _$SemesterAnalyticsImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'semester_code') required this.semesterCode,
      @JsonKey(name: 'live_sgpa') this.liveSgpa,
      @JsonKey(name: 'live_cgpa') this.liveCgpa,
      this.target,
      @JsonKey(name: 'required_credit') this.requiredCredit,
      @JsonKey(name: 'completed_credit') this.completedCredit,
      @JsonKey(name: 'taken_in_this_sem') this.takenInThisSem,
      @JsonKey(name: 'credits_left') this.creditsLeft,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$SemesterAnalyticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SemesterAnalyticsImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'semester_code')
  final String semesterCode;
  @override
  @JsonKey(name: 'live_sgpa')
  final double? liveSgpa;
  @override
  @JsonKey(name: 'live_cgpa')
  final double? liveCgpa;
  @override
  final double? target;
  @override
  @JsonKey(name: 'required_credit')
  final double? requiredCredit;
  @override
  @JsonKey(name: 'completed_credit')
  final double? completedCredit;
  @override
  @JsonKey(name: 'taken_in_this_sem')
  final double? takenInThisSem;
  @override
  @JsonKey(name: 'credits_left')
  final double? creditsLeft;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SemesterAnalytics(id: $id, userId: $userId, semesterCode: $semesterCode, liveSgpa: $liveSgpa, liveCgpa: $liveCgpa, target: $target, requiredCredit: $requiredCredit, completedCredit: $completedCredit, takenInThisSem: $takenInThisSem, creditsLeft: $creditsLeft, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SemesterAnalyticsImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.semesterCode, semesterCode) ||
                other.semesterCode == semesterCode) &&
            (identical(other.liveSgpa, liveSgpa) ||
                other.liveSgpa == liveSgpa) &&
            (identical(other.liveCgpa, liveCgpa) ||
                other.liveCgpa == liveCgpa) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.requiredCredit, requiredCredit) ||
                other.requiredCredit == requiredCredit) &&
            (identical(other.completedCredit, completedCredit) ||
                other.completedCredit == completedCredit) &&
            (identical(other.takenInThisSem, takenInThisSem) ||
                other.takenInThisSem == takenInThisSem) &&
            (identical(other.creditsLeft, creditsLeft) ||
                other.creditsLeft == creditsLeft) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
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
      liveSgpa,
      liveCgpa,
      target,
      requiredCredit,
      completedCredit,
      takenInThisSem,
      creditsLeft,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SemesterAnalyticsImplCopyWith<_$SemesterAnalyticsImpl> get copyWith =>
      __$$SemesterAnalyticsImplCopyWithImpl<_$SemesterAnalyticsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SemesterAnalyticsImplToJson(
      this,
    );
  }
}

abstract class _SemesterAnalytics implements SemesterAnalytics {
  const factory _SemesterAnalytics(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'semester_code') required final String semesterCode,
          @JsonKey(name: 'live_sgpa') final double? liveSgpa,
          @JsonKey(name: 'live_cgpa') final double? liveCgpa,
          final double? target,
          @JsonKey(name: 'required_credit') final double? requiredCredit,
          @JsonKey(name: 'completed_credit') final double? completedCredit,
          @JsonKey(name: 'taken_in_this_sem') final double? takenInThisSem,
          @JsonKey(name: 'credits_left') final double? creditsLeft,
          @JsonKey(name: 'created_at') final DateTime? createdAt,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt}) =
      _$SemesterAnalyticsImpl;

  factory _SemesterAnalytics.fromJson(Map<String, dynamic> json) =
      _$SemesterAnalyticsImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  @override
  @JsonKey(name: 'live_sgpa')
  double? get liveSgpa;
  @override
  @JsonKey(name: 'live_cgpa')
  double? get liveCgpa;
  @override
  double? get target;
  @override
  @JsonKey(name: 'required_credit')
  double? get requiredCredit;
  @override
  @JsonKey(name: 'completed_credit')
  double? get completedCredit;
  @override
  @JsonKey(name: 'taken_in_this_sem')
  double? get takenInThisSem;
  @override
  @JsonKey(name: 'credits_left')
  double? get creditsLeft;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SemesterAnalyticsImplCopyWith<_$SemesterAnalyticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
