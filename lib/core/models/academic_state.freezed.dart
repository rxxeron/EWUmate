// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'academic_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AcademicState {
  String get track;
  @JsonKey(name: 'current_semester_code')
  String get currentSemesterCode;
  @JsonKey(name: 'next_semester_code')
  String get nextSemesterCode;
  @JsonKey(name: 'advising_start_date')
  DateTime? get advisingStartDate;
  @JsonKey(name: 'advising_end_date')
  DateTime? get advisingEndDate;
  @JsonKey(name: 'classes_start_date')
  DateTime? get classesStartDate;
  @JsonKey(name: 'semester_switch_date')
  DateTime? get semesterSwitchDate;
  @JsonKey(name: 'upcoming_classes_start_date')
  DateTime? get upcomingClassesStartDate;

  /// Create a copy of AcademicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AcademicStateCopyWith<AcademicState> get copyWith =>
      _$AcademicStateCopyWithImpl<AcademicState>(
          this as AcademicState, _$identity);

  /// Serializes this AcademicState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AcademicState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AcademicState &&
            (identical(other.track, _this.track) ||
                other.track == _this.track) &&
            (identical(other.currentSemesterCode, _this.currentSemesterCode) ||
                other.currentSemesterCode == _this.currentSemesterCode) &&
            (identical(other.nextSemesterCode, _this.nextSemesterCode) ||
                other.nextSemesterCode == _this.nextSemesterCode) &&
            (identical(other.advisingStartDate, _this.advisingStartDate) ||
                other.advisingStartDate == _this.advisingStartDate) &&
            (identical(other.advisingEndDate, _this.advisingEndDate) ||
                other.advisingEndDate == _this.advisingEndDate) &&
            (identical(other.classesStartDate, _this.classesStartDate) ||
                other.classesStartDate == _this.classesStartDate) &&
            (identical(other.semesterSwitchDate, _this.semesterSwitchDate) ||
                other.semesterSwitchDate == _this.semesterSwitchDate) &&
            (identical(other.upcomingClassesStartDate,
                    _this.upcomingClassesStartDate) ||
                other.upcomingClassesStartDate ==
                    _this.upcomingClassesStartDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AcademicState;
    return Object.hash(
        runtimeType,
        _this.track,
        _this.currentSemesterCode,
        _this.nextSemesterCode,
        _this.advisingStartDate,
        _this.advisingEndDate,
        _this.classesStartDate,
        _this.semesterSwitchDate,
        _this.upcomingClassesStartDate);
  }

  @override
  String toString() {
    final _this = this as AcademicState;
    return 'AcademicState(track: ${_this.track}, currentSemesterCode: ${_this.currentSemesterCode}, nextSemesterCode: ${_this.nextSemesterCode}, advisingStartDate: ${_this.advisingStartDate}, advisingEndDate: ${_this.advisingEndDate}, classesStartDate: ${_this.classesStartDate}, semesterSwitchDate: ${_this.semesterSwitchDate}, upcomingClassesStartDate: ${_this.upcomingClassesStartDate})';
  }
}

/// @nodoc
abstract mixin class $AcademicStateCopyWith<$Res> {
  factory $AcademicStateCopyWith(
          AcademicState value, $Res Function(AcademicState) _then) =
      _$AcademicStateCopyWithImpl;
  @useResult
  $Res call(
      {String track,
      @JsonKey(name: 'current_semester_code') String currentSemesterCode,
      @JsonKey(name: 'next_semester_code') String nextSemesterCode,
      @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
      @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
      @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
      @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
      @JsonKey(name: 'upcoming_classes_start_date')
      DateTime? upcomingClassesStartDate});
}

/// @nodoc
class _$AcademicStateCopyWithImpl<$Res>
    implements $AcademicStateCopyWith<$Res> {
  _$AcademicStateCopyWithImpl(this._self, this._then);

  final AcademicState _self;
  final $Res Function(AcademicState) _then;

  /// Create a copy of AcademicState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? track = null,
    Object? currentSemesterCode = null,
    Object? nextSemesterCode = null,
    Object? advisingStartDate = freezed,
    Object? advisingEndDate = freezed,
    Object? classesStartDate = freezed,
    Object? semesterSwitchDate = freezed,
    Object? upcomingClassesStartDate = freezed,
  }) {
    return _then(AcademicState(
      track: null == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      currentSemesterCode: null == currentSemesterCode
          ? _self.currentSemesterCode
          : currentSemesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      nextSemesterCode: null == nextSemesterCode
          ? _self.nextSemesterCode
          : nextSemesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      advisingStartDate: freezed == advisingStartDate
          ? _self.advisingStartDate
          : advisingStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      advisingEndDate: freezed == advisingEndDate
          ? _self.advisingEndDate
          : advisingEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      classesStartDate: freezed == classesStartDate
          ? _self.classesStartDate
          : classesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      semesterSwitchDate: freezed == semesterSwitchDate
          ? _self.semesterSwitchDate
          : semesterSwitchDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      upcomingClassesStartDate: freezed == upcomingClassesStartDate
          ? _self.upcomingClassesStartDate
          : upcomingClassesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [AcademicState].
extension AcademicStatePatterns on AcademicState {
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
    TResult Function(_AcademicState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AcademicState() when $default != null:
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
    TResult Function(_AcademicState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AcademicState():
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
    TResult? Function(_AcademicState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AcademicState() when $default != null:
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
            String track,
            @JsonKey(name: 'current_semester_code') String currentSemesterCode,
            @JsonKey(name: 'next_semester_code') String nextSemesterCode,
            @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
            @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
            @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
            @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
            @JsonKey(name: 'upcoming_classes_start_date')
            DateTime? upcomingClassesStartDate)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AcademicState() when $default != null:
        return $default(
            _that.track,
            _that.currentSemesterCode,
            _that.nextSemesterCode,
            _that.advisingStartDate,
            _that.advisingEndDate,
            _that.classesStartDate,
            _that.semesterSwitchDate,
            _that.upcomingClassesStartDate);
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
            String track,
            @JsonKey(name: 'current_semester_code') String currentSemesterCode,
            @JsonKey(name: 'next_semester_code') String nextSemesterCode,
            @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
            @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
            @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
            @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
            @JsonKey(name: 'upcoming_classes_start_date')
            DateTime? upcomingClassesStartDate)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AcademicState():
        return $default(
            _that.track,
            _that.currentSemesterCode,
            _that.nextSemesterCode,
            _that.advisingStartDate,
            _that.advisingEndDate,
            _that.classesStartDate,
            _that.semesterSwitchDate,
            _that.upcomingClassesStartDate);
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
            String track,
            @JsonKey(name: 'current_semester_code') String currentSemesterCode,
            @JsonKey(name: 'next_semester_code') String nextSemesterCode,
            @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
            @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
            @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
            @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
            @JsonKey(name: 'upcoming_classes_start_date')
            DateTime? upcomingClassesStartDate)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AcademicState() when $default != null:
        return $default(
            _that.track,
            _that.currentSemesterCode,
            _that.nextSemesterCode,
            _that.advisingStartDate,
            _that.advisingEndDate,
            _that.classesStartDate,
            _that.semesterSwitchDate,
            _that.upcomingClassesStartDate);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AcademicState implements AcademicState {
  const _AcademicState(
      {required this.track,
      @JsonKey(name: 'current_semester_code') required this.currentSemesterCode,
      @JsonKey(name: 'next_semester_code') required this.nextSemesterCode,
      @JsonKey(name: 'advising_start_date') this.advisingStartDate,
      @JsonKey(name: 'advising_end_date') this.advisingEndDate,
      @JsonKey(name: 'classes_start_date') this.classesStartDate,
      @JsonKey(name: 'semester_switch_date') this.semesterSwitchDate,
      @JsonKey(name: 'upcoming_classes_start_date')
      this.upcomingClassesStartDate});
  factory _AcademicState.fromJson(Map<String, dynamic> json) =>
      _$AcademicStateFromJson(json);

  @override
  final String track;
  @override
  @JsonKey(name: 'current_semester_code')
  final String currentSemesterCode;
  @override
  @JsonKey(name: 'next_semester_code')
  final String nextSemesterCode;
  @override
  @JsonKey(name: 'advising_start_date')
  final DateTime? advisingStartDate;
  @override
  @JsonKey(name: 'advising_end_date')
  final DateTime? advisingEndDate;
  @override
  @JsonKey(name: 'classes_start_date')
  final DateTime? classesStartDate;
  @override
  @JsonKey(name: 'semester_switch_date')
  final DateTime? semesterSwitchDate;
  @override
  @JsonKey(name: 'upcoming_classes_start_date')
  final DateTime? upcomingClassesStartDate;

  /// Create a copy of AcademicState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AcademicStateCopyWith<_AcademicState> get copyWith =>
      __$AcademicStateCopyWithImpl<_AcademicState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AcademicStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AcademicState &&
            (identical(other.track, track) || other.track == track) &&
            (identical(other.currentSemesterCode, currentSemesterCode) ||
                other.currentSemesterCode == currentSemesterCode) &&
            (identical(other.nextSemesterCode, nextSemesterCode) ||
                other.nextSemesterCode == nextSemesterCode) &&
            (identical(other.advisingStartDate, advisingStartDate) ||
                other.advisingStartDate == advisingStartDate) &&
            (identical(other.advisingEndDate, advisingEndDate) ||
                other.advisingEndDate == advisingEndDate) &&
            (identical(other.classesStartDate, classesStartDate) ||
                other.classesStartDate == classesStartDate) &&
            (identical(other.semesterSwitchDate, semesterSwitchDate) ||
                other.semesterSwitchDate == semesterSwitchDate) &&
            (identical(
                    other.upcomingClassesStartDate, upcomingClassesStartDate) ||
                other.upcomingClassesStartDate == upcomingClassesStartDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        track,
        currentSemesterCode,
        nextSemesterCode,
        advisingStartDate,
        advisingEndDate,
        classesStartDate,
        semesterSwitchDate,
        upcomingClassesStartDate);
  }

  @override
  String toString() {
    return 'AcademicState(track: $track, currentSemesterCode: $currentSemesterCode, nextSemesterCode: $nextSemesterCode, advisingStartDate: $advisingStartDate, advisingEndDate: $advisingEndDate, classesStartDate: $classesStartDate, semesterSwitchDate: $semesterSwitchDate, upcomingClassesStartDate: $upcomingClassesStartDate)';
  }
}

/// @nodoc
abstract mixin class _$AcademicStateCopyWith<$Res>
    implements $AcademicStateCopyWith<$Res> {
  factory _$AcademicStateCopyWith(
          _AcademicState value, $Res Function(_AcademicState) _then) =
      __$AcademicStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String track,
      @JsonKey(name: 'current_semester_code') String currentSemesterCode,
      @JsonKey(name: 'next_semester_code') String nextSemesterCode,
      @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
      @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
      @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
      @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
      @JsonKey(name: 'upcoming_classes_start_date')
      DateTime? upcomingClassesStartDate});
}

/// @nodoc
class __$AcademicStateCopyWithImpl<$Res>
    implements _$AcademicStateCopyWith<$Res> {
  __$AcademicStateCopyWithImpl(this._self, this._then);

  final _AcademicState _self;
  final $Res Function(_AcademicState) _then;

  /// Create a copy of AcademicState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? track = null,
    Object? currentSemesterCode = null,
    Object? nextSemesterCode = null,
    Object? advisingStartDate = freezed,
    Object? advisingEndDate = freezed,
    Object? classesStartDate = freezed,
    Object? semesterSwitchDate = freezed,
    Object? upcomingClassesStartDate = freezed,
  }) {
    return _then(_AcademicState(
      track: null == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      currentSemesterCode: null == currentSemesterCode
          ? _self.currentSemesterCode
          : currentSemesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      nextSemesterCode: null == nextSemesterCode
          ? _self.nextSemesterCode
          : nextSemesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      advisingStartDate: freezed == advisingStartDate
          ? _self.advisingStartDate
          : advisingStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      advisingEndDate: freezed == advisingEndDate
          ? _self.advisingEndDate
          : advisingEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      classesStartDate: freezed == classesStartDate
          ? _self.classesStartDate
          : classesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      semesterSwitchDate: freezed == semesterSwitchDate
          ? _self.semesterSwitchDate
          : semesterSwitchDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      upcomingClassesStartDate: freezed == upcomingClassesStartDate
          ? _self.upcomingClassesStartDate
          : upcomingClassesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
