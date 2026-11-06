// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_semester.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActiveSemester {
  String get track;
  @JsonKey(name: 'current_semester_code')
  String? get currentSemesterCode;
  @JsonKey(name: 'next_semester_code')
  String? get nextSemesterCode;
  @JsonKey(name: 'classes_start_date')
  DateTime? get classesStartDate;
  @JsonKey(name: 'classes_end_date')
  DateTime? get classesEndDate;
  @JsonKey(name: 'advising_start_date')
  DateTime? get advisingStartDate;
  @JsonKey(name: 'advising_end_date')
  DateTime? get advisingEndDate;
  @JsonKey(name: 'final_exam_start')
  DateTime? get finalExamStart;
  @JsonKey(name: 'final_exam_end')
  DateTime? get finalExamEnd;
  @JsonKey(name: 'grade_submission_start')
  DateTime? get gradeSubmissionStart;
  @JsonKey(name: 'grade_submission_deadline')
  DateTime? get gradeSubmissionDeadline;
  @JsonKey(name: 'semester_switch_date')
  DateTime? get semesterSwitchDate;
  @JsonKey(name: 'upcoming_classes_start_date')
  DateTime? get upcomingClassesStartDate;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of ActiveSemester
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ActiveSemesterCopyWith<ActiveSemester> get copyWith =>
      _$ActiveSemesterCopyWithImpl<ActiveSemester>(
          this as ActiveSemester, _$identity);

  /// Serializes this ActiveSemester to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as ActiveSemester;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ActiveSemester &&
            (identical(other.track, _this.track) ||
                other.track == _this.track) &&
            (identical(other.currentSemesterCode, _this.currentSemesterCode) ||
                other.currentSemesterCode == _this.currentSemesterCode) &&
            (identical(other.nextSemesterCode, _this.nextSemesterCode) ||
                other.nextSemesterCode == _this.nextSemesterCode) &&
            (identical(other.classesStartDate, _this.classesStartDate) ||
                other.classesStartDate == _this.classesStartDate) &&
            (identical(other.classesEndDate, _this.classesEndDate) ||
                other.classesEndDate == _this.classesEndDate) &&
            (identical(other.advisingStartDate, _this.advisingStartDate) ||
                other.advisingStartDate == _this.advisingStartDate) &&
            (identical(other.advisingEndDate, _this.advisingEndDate) ||
                other.advisingEndDate == _this.advisingEndDate) &&
            (identical(other.finalExamStart, _this.finalExamStart) ||
                other.finalExamStart == _this.finalExamStart) &&
            (identical(other.finalExamEnd, _this.finalExamEnd) ||
                other.finalExamEnd == _this.finalExamEnd) &&
            (identical(
                    other.gradeSubmissionStart, _this.gradeSubmissionStart) ||
                other.gradeSubmissionStart == _this.gradeSubmissionStart) &&
            (identical(other.gradeSubmissionDeadline,
                    _this.gradeSubmissionDeadline) ||
                other.gradeSubmissionDeadline ==
                    _this.gradeSubmissionDeadline) &&
            (identical(other.semesterSwitchDate, _this.semesterSwitchDate) ||
                other.semesterSwitchDate == _this.semesterSwitchDate) &&
            (identical(other.upcomingClassesStartDate,
                    _this.upcomingClassesStartDate) ||
                other.upcomingClassesStartDate ==
                    _this.upcomingClassesStartDate) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as ActiveSemester;
    return Object.hash(
        runtimeType,
        _this.track,
        _this.currentSemesterCode,
        _this.nextSemesterCode,
        _this.classesStartDate,
        _this.classesEndDate,
        _this.advisingStartDate,
        _this.advisingEndDate,
        _this.finalExamStart,
        _this.finalExamEnd,
        _this.gradeSubmissionStart,
        _this.gradeSubmissionDeadline,
        _this.semesterSwitchDate,
        _this.upcomingClassesStartDate,
        _this.updatedAt);
  }

  @override
  String toString() {
    final _this = this as ActiveSemester;
    return 'ActiveSemester(track: ${_this.track}, currentSemesterCode: ${_this.currentSemesterCode}, nextSemesterCode: ${_this.nextSemesterCode}, classesStartDate: ${_this.classesStartDate}, classesEndDate: ${_this.classesEndDate}, advisingStartDate: ${_this.advisingStartDate}, advisingEndDate: ${_this.advisingEndDate}, finalExamStart: ${_this.finalExamStart}, finalExamEnd: ${_this.finalExamEnd}, gradeSubmissionStart: ${_this.gradeSubmissionStart}, gradeSubmissionDeadline: ${_this.gradeSubmissionDeadline}, semesterSwitchDate: ${_this.semesterSwitchDate}, upcomingClassesStartDate: ${_this.upcomingClassesStartDate}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $ActiveSemesterCopyWith<$Res> {
  factory $ActiveSemesterCopyWith(
          ActiveSemester value, $Res Function(ActiveSemester) _then) =
      _$ActiveSemesterCopyWithImpl;
  @useResult
  $Res call(
      {String track,
      @JsonKey(name: 'current_semester_code') String? currentSemesterCode,
      @JsonKey(name: 'next_semester_code') String? nextSemesterCode,
      @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
      @JsonKey(name: 'classes_end_date') DateTime? classesEndDate,
      @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
      @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
      @JsonKey(name: 'final_exam_start') DateTime? finalExamStart,
      @JsonKey(name: 'final_exam_end') DateTime? finalExamEnd,
      @JsonKey(name: 'grade_submission_start') DateTime? gradeSubmissionStart,
      @JsonKey(name: 'grade_submission_deadline')
      DateTime? gradeSubmissionDeadline,
      @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
      @JsonKey(name: 'upcoming_classes_start_date')
      DateTime? upcomingClassesStartDate,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$ActiveSemesterCopyWithImpl<$Res>
    implements $ActiveSemesterCopyWith<$Res> {
  _$ActiveSemesterCopyWithImpl(this._self, this._then);

  final ActiveSemester _self;
  final $Res Function(ActiveSemester) _then;

  /// Create a copy of ActiveSemester
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? track = null,
    Object? currentSemesterCode = freezed,
    Object? nextSemesterCode = freezed,
    Object? classesStartDate = freezed,
    Object? classesEndDate = freezed,
    Object? advisingStartDate = freezed,
    Object? advisingEndDate = freezed,
    Object? finalExamStart = freezed,
    Object? finalExamEnd = freezed,
    Object? gradeSubmissionStart = freezed,
    Object? gradeSubmissionDeadline = freezed,
    Object? semesterSwitchDate = freezed,
    Object? upcomingClassesStartDate = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(ActiveSemester(
      track: null == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      currentSemesterCode: freezed == currentSemesterCode
          ? _self.currentSemesterCode
          : currentSemesterCode // ignore: cast_nullable_to_non_nullable
              as String?,
      nextSemesterCode: freezed == nextSemesterCode
          ? _self.nextSemesterCode
          : nextSemesterCode // ignore: cast_nullable_to_non_nullable
              as String?,
      classesStartDate: freezed == classesStartDate
          ? _self.classesStartDate
          : classesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      classesEndDate: freezed == classesEndDate
          ? _self.classesEndDate
          : classesEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      advisingStartDate: freezed == advisingStartDate
          ? _self.advisingStartDate
          : advisingStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      advisingEndDate: freezed == advisingEndDate
          ? _self.advisingEndDate
          : advisingEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      finalExamStart: freezed == finalExamStart
          ? _self.finalExamStart
          : finalExamStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      finalExamEnd: freezed == finalExamEnd
          ? _self.finalExamEnd
          : finalExamEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gradeSubmissionStart: freezed == gradeSubmissionStart
          ? _self.gradeSubmissionStart
          : gradeSubmissionStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gradeSubmissionDeadline: freezed == gradeSubmissionDeadline
          ? _self.gradeSubmissionDeadline
          : gradeSubmissionDeadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      semesterSwitchDate: freezed == semesterSwitchDate
          ? _self.semesterSwitchDate
          : semesterSwitchDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      upcomingClassesStartDate: freezed == upcomingClassesStartDate
          ? _self.upcomingClassesStartDate
          : upcomingClassesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ActiveSemester].
extension ActiveSemesterPatterns on ActiveSemester {
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
    TResult Function(_ActiveSemester value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ActiveSemester() when $default != null:
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
    TResult Function(_ActiveSemester value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActiveSemester():
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
    TResult? Function(_ActiveSemester value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActiveSemester() when $default != null:
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
            @JsonKey(name: 'current_semester_code') String? currentSemesterCode,
            @JsonKey(name: 'next_semester_code') String? nextSemesterCode,
            @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
            @JsonKey(name: 'classes_end_date') DateTime? classesEndDate,
            @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
            @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
            @JsonKey(name: 'final_exam_start') DateTime? finalExamStart,
            @JsonKey(name: 'final_exam_end') DateTime? finalExamEnd,
            @JsonKey(name: 'grade_submission_start')
            DateTime? gradeSubmissionStart,
            @JsonKey(name: 'grade_submission_deadline')
            DateTime? gradeSubmissionDeadline,
            @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
            @JsonKey(name: 'upcoming_classes_start_date')
            DateTime? upcomingClassesStartDate,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ActiveSemester() when $default != null:
        return $default(
            _that.track,
            _that.currentSemesterCode,
            _that.nextSemesterCode,
            _that.classesStartDate,
            _that.classesEndDate,
            _that.advisingStartDate,
            _that.advisingEndDate,
            _that.finalExamStart,
            _that.finalExamEnd,
            _that.gradeSubmissionStart,
            _that.gradeSubmissionDeadline,
            _that.semesterSwitchDate,
            _that.upcomingClassesStartDate,
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
            String track,
            @JsonKey(name: 'current_semester_code') String? currentSemesterCode,
            @JsonKey(name: 'next_semester_code') String? nextSemesterCode,
            @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
            @JsonKey(name: 'classes_end_date') DateTime? classesEndDate,
            @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
            @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
            @JsonKey(name: 'final_exam_start') DateTime? finalExamStart,
            @JsonKey(name: 'final_exam_end') DateTime? finalExamEnd,
            @JsonKey(name: 'grade_submission_start')
            DateTime? gradeSubmissionStart,
            @JsonKey(name: 'grade_submission_deadline')
            DateTime? gradeSubmissionDeadline,
            @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
            @JsonKey(name: 'upcoming_classes_start_date')
            DateTime? upcomingClassesStartDate,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActiveSemester():
        return $default(
            _that.track,
            _that.currentSemesterCode,
            _that.nextSemesterCode,
            _that.classesStartDate,
            _that.classesEndDate,
            _that.advisingStartDate,
            _that.advisingEndDate,
            _that.finalExamStart,
            _that.finalExamEnd,
            _that.gradeSubmissionStart,
            _that.gradeSubmissionDeadline,
            _that.semesterSwitchDate,
            _that.upcomingClassesStartDate,
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
            String track,
            @JsonKey(name: 'current_semester_code') String? currentSemesterCode,
            @JsonKey(name: 'next_semester_code') String? nextSemesterCode,
            @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
            @JsonKey(name: 'classes_end_date') DateTime? classesEndDate,
            @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
            @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
            @JsonKey(name: 'final_exam_start') DateTime? finalExamStart,
            @JsonKey(name: 'final_exam_end') DateTime? finalExamEnd,
            @JsonKey(name: 'grade_submission_start')
            DateTime? gradeSubmissionStart,
            @JsonKey(name: 'grade_submission_deadline')
            DateTime? gradeSubmissionDeadline,
            @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
            @JsonKey(name: 'upcoming_classes_start_date')
            DateTime? upcomingClassesStartDate,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActiveSemester() when $default != null:
        return $default(
            _that.track,
            _that.currentSemesterCode,
            _that.nextSemesterCode,
            _that.classesStartDate,
            _that.classesEndDate,
            _that.advisingStartDate,
            _that.advisingEndDate,
            _that.finalExamStart,
            _that.finalExamEnd,
            _that.gradeSubmissionStart,
            _that.gradeSubmissionDeadline,
            _that.semesterSwitchDate,
            _that.upcomingClassesStartDate,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ActiveSemester implements ActiveSemester {
  const _ActiveSemester(
      {required this.track,
      @JsonKey(name: 'current_semester_code') this.currentSemesterCode,
      @JsonKey(name: 'next_semester_code') this.nextSemesterCode,
      @JsonKey(name: 'classes_start_date') this.classesStartDate,
      @JsonKey(name: 'classes_end_date') this.classesEndDate,
      @JsonKey(name: 'advising_start_date') this.advisingStartDate,
      @JsonKey(name: 'advising_end_date') this.advisingEndDate,
      @JsonKey(name: 'final_exam_start') this.finalExamStart,
      @JsonKey(name: 'final_exam_end') this.finalExamEnd,
      @JsonKey(name: 'grade_submission_start') this.gradeSubmissionStart,
      @JsonKey(name: 'grade_submission_deadline') this.gradeSubmissionDeadline,
      @JsonKey(name: 'semester_switch_date') this.semesterSwitchDate,
      @JsonKey(name: 'upcoming_classes_start_date')
      this.upcomingClassesStartDate,
      @JsonKey(name: 'updated_at') this.updatedAt});
  factory _ActiveSemester.fromJson(Map<String, dynamic> json) =>
      _$ActiveSemesterFromJson(json);

  @override
  final String track;
  @override
  @JsonKey(name: 'current_semester_code')
  final String? currentSemesterCode;
  @override
  @JsonKey(name: 'next_semester_code')
  final String? nextSemesterCode;
  @override
  @JsonKey(name: 'classes_start_date')
  final DateTime? classesStartDate;
  @override
  @JsonKey(name: 'classes_end_date')
  final DateTime? classesEndDate;
  @override
  @JsonKey(name: 'advising_start_date')
  final DateTime? advisingStartDate;
  @override
  @JsonKey(name: 'advising_end_date')
  final DateTime? advisingEndDate;
  @override
  @JsonKey(name: 'final_exam_start')
  final DateTime? finalExamStart;
  @override
  @JsonKey(name: 'final_exam_end')
  final DateTime? finalExamEnd;
  @override
  @JsonKey(name: 'grade_submission_start')
  final DateTime? gradeSubmissionStart;
  @override
  @JsonKey(name: 'grade_submission_deadline')
  final DateTime? gradeSubmissionDeadline;
  @override
  @JsonKey(name: 'semester_switch_date')
  final DateTime? semesterSwitchDate;
  @override
  @JsonKey(name: 'upcoming_classes_start_date')
  final DateTime? upcomingClassesStartDate;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of ActiveSemester
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ActiveSemesterCopyWith<_ActiveSemester> get copyWith =>
      __$ActiveSemesterCopyWithImpl<_ActiveSemester>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ActiveSemesterToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ActiveSemester &&
            (identical(other.track, track) || other.track == track) &&
            (identical(other.currentSemesterCode, currentSemesterCode) ||
                other.currentSemesterCode == currentSemesterCode) &&
            (identical(other.nextSemesterCode, nextSemesterCode) ||
                other.nextSemesterCode == nextSemesterCode) &&
            (identical(other.classesStartDate, classesStartDate) ||
                other.classesStartDate == classesStartDate) &&
            (identical(other.classesEndDate, classesEndDate) ||
                other.classesEndDate == classesEndDate) &&
            (identical(other.advisingStartDate, advisingStartDate) ||
                other.advisingStartDate == advisingStartDate) &&
            (identical(other.advisingEndDate, advisingEndDate) ||
                other.advisingEndDate == advisingEndDate) &&
            (identical(other.finalExamStart, finalExamStart) ||
                other.finalExamStart == finalExamStart) &&
            (identical(other.finalExamEnd, finalExamEnd) ||
                other.finalExamEnd == finalExamEnd) &&
            (identical(other.gradeSubmissionStart, gradeSubmissionStart) ||
                other.gradeSubmissionStart == gradeSubmissionStart) &&
            (identical(
                    other.gradeSubmissionDeadline, gradeSubmissionDeadline) ||
                other.gradeSubmissionDeadline == gradeSubmissionDeadline) &&
            (identical(other.semesterSwitchDate, semesterSwitchDate) ||
                other.semesterSwitchDate == semesterSwitchDate) &&
            (identical(
                    other.upcomingClassesStartDate, upcomingClassesStartDate) ||
                other.upcomingClassesStartDate == upcomingClassesStartDate) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        track,
        currentSemesterCode,
        nextSemesterCode,
        classesStartDate,
        classesEndDate,
        advisingStartDate,
        advisingEndDate,
        finalExamStart,
        finalExamEnd,
        gradeSubmissionStart,
        gradeSubmissionDeadline,
        semesterSwitchDate,
        upcomingClassesStartDate,
        updatedAt);
  }

  @override
  String toString() {
    return 'ActiveSemester(track: $track, currentSemesterCode: $currentSemesterCode, nextSemesterCode: $nextSemesterCode, classesStartDate: $classesStartDate, classesEndDate: $classesEndDate, advisingStartDate: $advisingStartDate, advisingEndDate: $advisingEndDate, finalExamStart: $finalExamStart, finalExamEnd: $finalExamEnd, gradeSubmissionStart: $gradeSubmissionStart, gradeSubmissionDeadline: $gradeSubmissionDeadline, semesterSwitchDate: $semesterSwitchDate, upcomingClassesStartDate: $upcomingClassesStartDate, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ActiveSemesterCopyWith<$Res>
    implements $ActiveSemesterCopyWith<$Res> {
  factory _$ActiveSemesterCopyWith(
          _ActiveSemester value, $Res Function(_ActiveSemester) _then) =
      __$ActiveSemesterCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String track,
      @JsonKey(name: 'current_semester_code') String? currentSemesterCode,
      @JsonKey(name: 'next_semester_code') String? nextSemesterCode,
      @JsonKey(name: 'classes_start_date') DateTime? classesStartDate,
      @JsonKey(name: 'classes_end_date') DateTime? classesEndDate,
      @JsonKey(name: 'advising_start_date') DateTime? advisingStartDate,
      @JsonKey(name: 'advising_end_date') DateTime? advisingEndDate,
      @JsonKey(name: 'final_exam_start') DateTime? finalExamStart,
      @JsonKey(name: 'final_exam_end') DateTime? finalExamEnd,
      @JsonKey(name: 'grade_submission_start') DateTime? gradeSubmissionStart,
      @JsonKey(name: 'grade_submission_deadline')
      DateTime? gradeSubmissionDeadline,
      @JsonKey(name: 'semester_switch_date') DateTime? semesterSwitchDate,
      @JsonKey(name: 'upcoming_classes_start_date')
      DateTime? upcomingClassesStartDate,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$ActiveSemesterCopyWithImpl<$Res>
    implements _$ActiveSemesterCopyWith<$Res> {
  __$ActiveSemesterCopyWithImpl(this._self, this._then);

  final _ActiveSemester _self;
  final $Res Function(_ActiveSemester) _then;

  /// Create a copy of ActiveSemester
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? track = null,
    Object? currentSemesterCode = freezed,
    Object? nextSemesterCode = freezed,
    Object? classesStartDate = freezed,
    Object? classesEndDate = freezed,
    Object? advisingStartDate = freezed,
    Object? advisingEndDate = freezed,
    Object? finalExamStart = freezed,
    Object? finalExamEnd = freezed,
    Object? gradeSubmissionStart = freezed,
    Object? gradeSubmissionDeadline = freezed,
    Object? semesterSwitchDate = freezed,
    Object? upcomingClassesStartDate = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_ActiveSemester(
      track: null == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      currentSemesterCode: freezed == currentSemesterCode
          ? _self.currentSemesterCode
          : currentSemesterCode // ignore: cast_nullable_to_non_nullable
              as String?,
      nextSemesterCode: freezed == nextSemesterCode
          ? _self.nextSemesterCode
          : nextSemesterCode // ignore: cast_nullable_to_non_nullable
              as String?,
      classesStartDate: freezed == classesStartDate
          ? _self.classesStartDate
          : classesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      classesEndDate: freezed == classesEndDate
          ? _self.classesEndDate
          : classesEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      advisingStartDate: freezed == advisingStartDate
          ? _self.advisingStartDate
          : advisingStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      advisingEndDate: freezed == advisingEndDate
          ? _self.advisingEndDate
          : advisingEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      finalExamStart: freezed == finalExamStart
          ? _self.finalExamStart
          : finalExamStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      finalExamEnd: freezed == finalExamEnd
          ? _self.finalExamEnd
          : finalExamEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gradeSubmissionStart: freezed == gradeSubmissionStart
          ? _self.gradeSubmissionStart
          : gradeSubmissionStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gradeSubmissionDeadline: freezed == gradeSubmissionDeadline
          ? _self.gradeSubmissionDeadline
          : gradeSubmissionDeadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      semesterSwitchDate: freezed == semesterSwitchDate
          ? _self.semesterSwitchDate
          : semesterSwitchDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      upcomingClassesStartDate: freezed == upcomingClassesStartDate
          ? _self.upcomingClassesStartDate
          : upcomingClassesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
