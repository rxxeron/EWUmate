// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semester_course_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SemesterCourseStats {
  String get id;
  @JsonKey(name: 'user_id')
  String get userId;
  String get semester;
  @JsonKey(name: 'course_code')
  String get courseCode;
  @JsonKey(name: 'marks_obtained')
  double? get marksObtained;
  @JsonKey(name: 'total_possible')
  double get totalPossible;
  @JsonKey(name: 'grade_goal')
  String? get gradeGoal;
  @JsonKey(name: 'last_updated')
  DateTime? get lastUpdated;

  /// Create a copy of SemesterCourseStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SemesterCourseStatsCopyWith<SemesterCourseStats> get copyWith =>
      _$SemesterCourseStatsCopyWithImpl<SemesterCourseStats>(
          this as SemesterCourseStats, _$identity);

  /// Serializes this SemesterCourseStats to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SemesterCourseStats;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SemesterCourseStats &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.semester, _this.semester) ||
                other.semester == _this.semester) &&
            (identical(other.courseCode, _this.courseCode) ||
                other.courseCode == _this.courseCode) &&
            (identical(other.marksObtained, _this.marksObtained) ||
                other.marksObtained == _this.marksObtained) &&
            (identical(other.totalPossible, _this.totalPossible) ||
                other.totalPossible == _this.totalPossible) &&
            (identical(other.gradeGoal, _this.gradeGoal) ||
                other.gradeGoal == _this.gradeGoal) &&
            (identical(other.lastUpdated, _this.lastUpdated) ||
                other.lastUpdated == _this.lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SemesterCourseStats;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.userId,
        _this.semester,
        _this.courseCode,
        _this.marksObtained,
        _this.totalPossible,
        _this.gradeGoal,
        _this.lastUpdated);
  }

  @override
  String toString() {
    final _this = this as SemesterCourseStats;
    return 'SemesterCourseStats(id: ${_this.id}, userId: ${_this.userId}, semester: ${_this.semester}, courseCode: ${_this.courseCode}, marksObtained: ${_this.marksObtained}, totalPossible: ${_this.totalPossible}, gradeGoal: ${_this.gradeGoal}, lastUpdated: ${_this.lastUpdated})';
  }
}

/// @nodoc
abstract mixin class $SemesterCourseStatsCopyWith<$Res> {
  factory $SemesterCourseStatsCopyWith(
          SemesterCourseStats value, $Res Function(SemesterCourseStats) _then) =
      _$SemesterCourseStatsCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String semester,
      @JsonKey(name: 'course_code') String courseCode,
      @JsonKey(name: 'marks_obtained') double? marksObtained,
      @JsonKey(name: 'total_possible') double totalPossible,
      @JsonKey(name: 'grade_goal') String? gradeGoal,
      @JsonKey(name: 'last_updated') DateTime? lastUpdated});
}

/// @nodoc
class _$SemesterCourseStatsCopyWithImpl<$Res>
    implements $SemesterCourseStatsCopyWith<$Res> {
  _$SemesterCourseStatsCopyWithImpl(this._self, this._then);

  final SemesterCourseStats _self;
  final $Res Function(SemesterCourseStats) _then;

  /// Create a copy of SemesterCourseStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? semester = null,
    Object? courseCode = null,
    Object? marksObtained = freezed,
    Object? totalPossible = null,
    Object? gradeGoal = freezed,
    Object? lastUpdated = freezed,
  }) {
    return _then(SemesterCourseStats(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semester: null == semester
          ? _self.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: freezed == marksObtained
          ? _self.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double?,
      totalPossible: null == totalPossible
          ? _self.totalPossible
          : totalPossible // ignore: cast_nullable_to_non_nullable
              as double,
      gradeGoal: freezed == gradeGoal
          ? _self.gradeGoal
          : gradeGoal // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUpdated: freezed == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SemesterCourseStats].
extension SemesterCourseStatsPatterns on SemesterCourseStats {
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
    TResult Function(_SemesterCourseStats value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseStats() when $default != null:
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
    TResult Function(_SemesterCourseStats value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseStats():
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
    TResult? Function(_SemesterCourseStats value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseStats() when $default != null:
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
            String semester,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'marks_obtained') double? marksObtained,
            @JsonKey(name: 'total_possible') double totalPossible,
            @JsonKey(name: 'grade_goal') String? gradeGoal,
            @JsonKey(name: 'last_updated') DateTime? lastUpdated)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseStats() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semester,
            _that.courseCode,
            _that.marksObtained,
            _that.totalPossible,
            _that.gradeGoal,
            _that.lastUpdated);
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
            String semester,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'marks_obtained') double? marksObtained,
            @JsonKey(name: 'total_possible') double totalPossible,
            @JsonKey(name: 'grade_goal') String? gradeGoal,
            @JsonKey(name: 'last_updated') DateTime? lastUpdated)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseStats():
        return $default(
            _that.id,
            _that.userId,
            _that.semester,
            _that.courseCode,
            _that.marksObtained,
            _that.totalPossible,
            _that.gradeGoal,
            _that.lastUpdated);
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
            String semester,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'marks_obtained') double? marksObtained,
            @JsonKey(name: 'total_possible') double totalPossible,
            @JsonKey(name: 'grade_goal') String? gradeGoal,
            @JsonKey(name: 'last_updated') DateTime? lastUpdated)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseStats() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semester,
            _that.courseCode,
            _that.marksObtained,
            _that.totalPossible,
            _that.gradeGoal,
            _that.lastUpdated);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SemesterCourseStats implements SemesterCourseStats {
  const _SemesterCourseStats(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      required this.semester,
      @JsonKey(name: 'course_code') required this.courseCode,
      @JsonKey(name: 'marks_obtained') this.marksObtained,
      @JsonKey(name: 'total_possible') this.totalPossible = 100.0,
      @JsonKey(name: 'grade_goal') this.gradeGoal,
      @JsonKey(name: 'last_updated') this.lastUpdated});
  factory _SemesterCourseStats.fromJson(Map<String, dynamic> json) =>
      _$SemesterCourseStatsFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final String semester;
  @override
  @JsonKey(name: 'course_code')
  final String courseCode;
  @override
  @JsonKey(name: 'marks_obtained')
  final double? marksObtained;
  @override
  @JsonKey(name: 'total_possible')
  final double totalPossible;
  @override
  @JsonKey(name: 'grade_goal')
  final String? gradeGoal;
  @override
  @JsonKey(name: 'last_updated')
  final DateTime? lastUpdated;

  /// Create a copy of SemesterCourseStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SemesterCourseStatsCopyWith<_SemesterCourseStats> get copyWith =>
      __$SemesterCourseStatsCopyWithImpl<_SemesterCourseStats>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SemesterCourseStatsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SemesterCourseStats &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.semester, semester) ||
                other.semester == semester) &&
            (identical(other.courseCode, courseCode) ||
                other.courseCode == courseCode) &&
            (identical(other.marksObtained, marksObtained) ||
                other.marksObtained == marksObtained) &&
            (identical(other.totalPossible, totalPossible) ||
                other.totalPossible == totalPossible) &&
            (identical(other.gradeGoal, gradeGoal) ||
                other.gradeGoal == gradeGoal) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, userId, semester, courseCode,
        marksObtained, totalPossible, gradeGoal, lastUpdated);
  }

  @override
  String toString() {
    return 'SemesterCourseStats(id: $id, userId: $userId, semester: $semester, courseCode: $courseCode, marksObtained: $marksObtained, totalPossible: $totalPossible, gradeGoal: $gradeGoal, lastUpdated: $lastUpdated)';
  }
}

/// @nodoc
abstract mixin class _$SemesterCourseStatsCopyWith<$Res>
    implements $SemesterCourseStatsCopyWith<$Res> {
  factory _$SemesterCourseStatsCopyWith(_SemesterCourseStats value,
          $Res Function(_SemesterCourseStats) _then) =
      __$SemesterCourseStatsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String semester,
      @JsonKey(name: 'course_code') String courseCode,
      @JsonKey(name: 'marks_obtained') double? marksObtained,
      @JsonKey(name: 'total_possible') double totalPossible,
      @JsonKey(name: 'grade_goal') String? gradeGoal,
      @JsonKey(name: 'last_updated') DateTime? lastUpdated});
}

/// @nodoc
class __$SemesterCourseStatsCopyWithImpl<$Res>
    implements _$SemesterCourseStatsCopyWith<$Res> {
  __$SemesterCourseStatsCopyWithImpl(this._self, this._then);

  final _SemesterCourseStats _self;
  final $Res Function(_SemesterCourseStats) _then;

  /// Create a copy of SemesterCourseStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? semester = null,
    Object? courseCode = null,
    Object? marksObtained = freezed,
    Object? totalPossible = null,
    Object? gradeGoal = freezed,
    Object? lastUpdated = freezed,
  }) {
    return _then(_SemesterCourseStats(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semester: null == semester
          ? _self.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: freezed == marksObtained
          ? _self.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double?,
      totalPossible: null == totalPossible
          ? _self.totalPossible
          : totalPossible // ignore: cast_nullable_to_non_nullable
              as double,
      gradeGoal: freezed == gradeGoal
          ? _self.gradeGoal
          : gradeGoal // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUpdated: freezed == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
