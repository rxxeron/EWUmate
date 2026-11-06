// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_semester_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSemesterState {
  @JsonKey(name: 'user_id')
  String get userId;
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  @JsonKey(name: 'weekly_grid_cache')
  Map<String, dynamic>? get weeklyGridCache;
  @JsonKey(name: 'progress_summary')
  Map<String, dynamic>? get progressSummary;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of UserSemesterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UserSemesterStateCopyWith<UserSemesterState> get copyWith =>
      _$UserSemesterStateCopyWithImpl<UserSemesterState>(
          this as UserSemesterState, _$identity);

  /// Serializes this UserSemesterState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as UserSemesterState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UserSemesterState &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.semesterCode, _this.semesterCode) ||
                other.semesterCode == _this.semesterCode) &&
            const DeepCollectionEquality()
                .equals(other.weeklyGridCache, _this.weeklyGridCache) &&
            const DeepCollectionEquality()
                .equals(other.progressSummary, _this.progressSummary) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as UserSemesterState;
    return Object.hash(
        runtimeType,
        _this.userId,
        _this.semesterCode,
        const DeepCollectionEquality().hash(_this.weeklyGridCache),
        const DeepCollectionEquality().hash(_this.progressSummary),
        _this.updatedAt);
  }

  @override
  String toString() {
    final _this = this as UserSemesterState;
    return 'UserSemesterState(userId: ${_this.userId}, semesterCode: ${_this.semesterCode}, weeklyGridCache: ${_this.weeklyGridCache}, progressSummary: ${_this.progressSummary}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $UserSemesterStateCopyWith<$Res> {
  factory $UserSemesterStateCopyWith(
          UserSemesterState value, $Res Function(UserSemesterState) _then) =
      _$UserSemesterStateCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'weekly_grid_cache') Map<String, dynamic>? weeklyGridCache,
      @JsonKey(name: 'progress_summary') Map<String, dynamic>? progressSummary,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$UserSemesterStateCopyWithImpl<$Res>
    implements $UserSemesterStateCopyWith<$Res> {
  _$UserSemesterStateCopyWithImpl(this._self, this._then);

  final UserSemesterState _self;
  final $Res Function(UserSemesterState) _then;

  /// Create a copy of UserSemesterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? semesterCode = null,
    Object? weeklyGridCache = freezed,
    Object? progressSummary = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(UserSemesterState(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _self.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      weeklyGridCache: freezed == weeklyGridCache
          ? _self.weeklyGridCache
          : weeklyGridCache // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      progressSummary: freezed == progressSummary
          ? _self.progressSummary
          : progressSummary // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [UserSemesterState].
extension UserSemesterStatePatterns on UserSemesterState {
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
    TResult Function(_UserSemesterState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UserSemesterState() when $default != null:
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
    TResult Function(_UserSemesterState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserSemesterState():
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
    TResult? Function(_UserSemesterState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserSemesterState() when $default != null:
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
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'weekly_grid_cache')
            Map<String, dynamic>? weeklyGridCache,
            @JsonKey(name: 'progress_summary')
            Map<String, dynamic>? progressSummary,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UserSemesterState() when $default != null:
        return $default(_that.userId, _that.semesterCode, _that.weeklyGridCache,
            _that.progressSummary, _that.updatedAt);
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
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'weekly_grid_cache')
            Map<String, dynamic>? weeklyGridCache,
            @JsonKey(name: 'progress_summary')
            Map<String, dynamic>? progressSummary,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserSemesterState():
        return $default(_that.userId, _that.semesterCode, _that.weeklyGridCache,
            _that.progressSummary, _that.updatedAt);
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
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'weekly_grid_cache')
            Map<String, dynamic>? weeklyGridCache,
            @JsonKey(name: 'progress_summary')
            Map<String, dynamic>? progressSummary,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserSemesterState() when $default != null:
        return $default(_that.userId, _that.semesterCode, _that.weeklyGridCache,
            _that.progressSummary, _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UserSemesterState implements UserSemesterState {
  const _UserSemesterState(
      {@JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'semester_code') required this.semesterCode,
      @JsonKey(name: 'weekly_grid_cache') Map<String, dynamic>? weeklyGridCache,
      @JsonKey(name: 'progress_summary') Map<String, dynamic>? progressSummary,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _weeklyGridCache = weeklyGridCache,
        _progressSummary = progressSummary;
  factory _UserSemesterState.fromJson(Map<String, dynamic> json) =>
      _$UserSemesterStateFromJson(json);

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

  /// Create a copy of UserSemesterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UserSemesterStateCopyWith<_UserSemesterState> get copyWith =>
      __$UserSemesterStateCopyWithImpl<_UserSemesterState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UserSemesterStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UserSemesterState &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.semesterCode, semesterCode) ||
                other.semesterCode == semesterCode) &&
            const DeepCollectionEquality()
                .equals(other.weeklyGridCache, _weeklyGridCache) &&
            const DeepCollectionEquality()
                .equals(other.progressSummary, _progressSummary) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        userId,
        semesterCode,
        const DeepCollectionEquality().hash(_weeklyGridCache),
        const DeepCollectionEquality().hash(_progressSummary),
        updatedAt);
  }

  @override
  String toString() {
    return 'UserSemesterState(userId: $userId, semesterCode: $semesterCode, weeklyGridCache: $weeklyGridCache, progressSummary: $progressSummary, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$UserSemesterStateCopyWith<$Res>
    implements $UserSemesterStateCopyWith<$Res> {
  factory _$UserSemesterStateCopyWith(
          _UserSemesterState value, $Res Function(_UserSemesterState) _then) =
      __$UserSemesterStateCopyWithImpl;
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
class __$UserSemesterStateCopyWithImpl<$Res>
    implements _$UserSemesterStateCopyWith<$Res> {
  __$UserSemesterStateCopyWithImpl(this._self, this._then);

  final _UserSemesterState _self;
  final $Res Function(_UserSemesterState) _then;

  /// Create a copy of UserSemesterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? userId = null,
    Object? semesterCode = null,
    Object? weeklyGridCache = freezed,
    Object? progressSummary = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_UserSemesterState(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _self.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      weeklyGridCache: freezed == weeklyGridCache
          ? _self._weeklyGridCache
          : weeklyGridCache // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      progressSummary: freezed == progressSummary
          ? _self._progressSummary
          : progressSummary // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
