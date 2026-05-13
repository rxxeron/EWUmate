// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_semester_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserSemesterState _$UserSemesterStateFromJson(Map<String, dynamic> json) {
  return _UserSemesterState.fromJson(json);
}

/// @nodoc
mixin _$UserSemesterState {
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'semester_code')
  String get semesterCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'weekly_grid_cache')
  Map<String, dynamic>? get weeklyGridCache =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'progress_summary')
  Map<String, dynamic>? get progressSummary =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSemesterStateCopyWith<UserSemesterState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSemesterStateCopyWith<$Res> {
  factory $UserSemesterStateCopyWith(
          UserSemesterState value, $Res Function(UserSemesterState) then) =
      _$UserSemesterStateCopyWithImpl<$Res, UserSemesterState>;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'weekly_grid_cache') Map<String, dynamic>? weeklyGridCache,
      @JsonKey(name: 'progress_summary') Map<String, dynamic>? progressSummary,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$UserSemesterStateCopyWithImpl<$Res, $Val extends UserSemesterState>
    implements $UserSemesterStateCopyWith<$Res> {
  _$UserSemesterStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? semesterCode = null,
    Object? weeklyGridCache = freezed,
    Object? progressSummary = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _value.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      weeklyGridCache: freezed == weeklyGridCache
          ? _value.weeklyGridCache
          : weeklyGridCache // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      progressSummary: freezed == progressSummary
          ? _value.progressSummary
          : progressSummary // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSemesterStateImplCopyWith<$Res>
    implements $UserSemesterStateCopyWith<$Res> {
  factory _$$UserSemesterStateImplCopyWith(_$UserSemesterStateImpl value,
          $Res Function(_$UserSemesterStateImpl) then) =
      __$$UserSemesterStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'weekly_grid_cache') Map<String, dynamic>? weeklyGridCache,
      @JsonKey(name: 'progress_summary') Map<String, dynamic>? progressSummary,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$UserSemesterStateImplCopyWithImpl<$Res>
    extends _$UserSemesterStateCopyWithImpl<$Res, _$UserSemesterStateImpl>
    implements _$$UserSemesterStateImplCopyWith<$Res> {
  __$$UserSemesterStateImplCopyWithImpl(_$UserSemesterStateImpl _value,
      $Res Function(_$UserSemesterStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? semesterCode = null,
    Object? weeklyGridCache = freezed,
    Object? progressSummary = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$UserSemesterStateImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _value.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      weeklyGridCache: freezed == weeklyGridCache
          ? _value._weeklyGridCache
          : weeklyGridCache // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      progressSummary: freezed == progressSummary
          ? _value._progressSummary
          : progressSummary // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSemesterStateImpl implements _UserSemesterState {
  const _$UserSemesterStateImpl(
      {@JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'semester_code') required this.semesterCode,
      @JsonKey(name: 'weekly_grid_cache')
      final Map<String, dynamic>? weeklyGridCache,
      @JsonKey(name: 'progress_summary')
      final Map<String, dynamic>? progressSummary,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _weeklyGridCache = weeklyGridCache,
        _progressSummary = progressSummary;

  factory _$UserSemesterStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSemesterStateImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'semester_code')
  final String semesterCode;
  final Map<String, dynamic>? _weeklyGridCache;
  @override
  @JsonKey(name: 'weekly_grid_cache')
  Map<String, dynamic>? get weeklyGridCache {
    final value = _weeklyGridCache;
    if (value == null) return null;
    if (_weeklyGridCache is EqualUnmodifiableMapView) return _weeklyGridCache;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _progressSummary;
  @override
  @JsonKey(name: 'progress_summary')
  Map<String, dynamic>? get progressSummary {
    final value = _progressSummary;
    if (value == null) return null;
    if (_progressSummary is EqualUnmodifiableMapView) return _progressSummary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserSemesterState(userId: $userId, semesterCode: $semesterCode, weeklyGridCache: $weeklyGridCache, progressSummary: $progressSummary, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSemesterStateImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.semesterCode, semesterCode) ||
                other.semesterCode == semesterCode) &&
            const DeepCollectionEquality()
                .equals(other._weeklyGridCache, _weeklyGridCache) &&
            const DeepCollectionEquality()
                .equals(other._progressSummary, _progressSummary) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      semesterCode,
      const DeepCollectionEquality().hash(_weeklyGridCache),
      const DeepCollectionEquality().hash(_progressSummary),
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSemesterStateImplCopyWith<_$UserSemesterStateImpl> get copyWith =>
      __$$UserSemesterStateImplCopyWithImpl<_$UserSemesterStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSemesterStateImplToJson(
      this,
    );
  }
}

abstract class _UserSemesterState implements UserSemesterState {
  const factory _UserSemesterState(
          {@JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'semester_code') required final String semesterCode,
          @JsonKey(name: 'weekly_grid_cache')
          final Map<String, dynamic>? weeklyGridCache,
          @JsonKey(name: 'progress_summary')
          final Map<String, dynamic>? progressSummary,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt}) =
      _$UserSemesterStateImpl;

  factory _UserSemesterState.fromJson(Map<String, dynamic> json) =
      _$UserSemesterStateImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  @override
  @JsonKey(name: 'weekly_grid_cache')
  Map<String, dynamic>? get weeklyGridCache;
  @override
  @JsonKey(name: 'progress_summary')
  Map<String, dynamic>? get progressSummary;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserSemesterStateImplCopyWith<_$UserSemesterStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
