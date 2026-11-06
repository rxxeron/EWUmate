// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semester_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SemesterSummary {
  String get id;
  @JsonKey(name: 'user_id')
  String get userId;
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  double? get tgpa;
  double? get cgpa;
  @JsonKey(name: 'credits_earned')
  double? get creditsEarned;
  @JsonKey(name: 'total_credits_earned')
  double? get totalCreditsEarned;
  List<dynamic> get courses;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of SemesterSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SemesterSummaryCopyWith<SemesterSummary> get copyWith =>
      _$SemesterSummaryCopyWithImpl<SemesterSummary>(
          this as SemesterSummary, _$identity);

  /// Serializes this SemesterSummary to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SemesterSummary;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SemesterSummary &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.semesterCode, _this.semesterCode) ||
                other.semesterCode == _this.semesterCode) &&
            (identical(other.tgpa, _this.tgpa) || other.tgpa == _this.tgpa) &&
            (identical(other.cgpa, _this.cgpa) || other.cgpa == _this.cgpa) &&
            (identical(other.creditsEarned, _this.creditsEarned) ||
                other.creditsEarned == _this.creditsEarned) &&
            (identical(other.totalCreditsEarned, _this.totalCreditsEarned) ||
                other.totalCreditsEarned == _this.totalCreditsEarned) &&
            const DeepCollectionEquality()
                .equals(other.courses, _this.courses) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SemesterSummary;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.userId,
        _this.semesterCode,
        _this.tgpa,
        _this.cgpa,
        _this.creditsEarned,
        _this.totalCreditsEarned,
        const DeepCollectionEquality().hash(_this.courses),
        _this.updatedAt);
  }

  @override
  String toString() {
    final _this = this as SemesterSummary;
    return 'SemesterSummary(id: ${_this.id}, userId: ${_this.userId}, semesterCode: ${_this.semesterCode}, tgpa: ${_this.tgpa}, cgpa: ${_this.cgpa}, creditsEarned: ${_this.creditsEarned}, totalCreditsEarned: ${_this.totalCreditsEarned}, courses: ${_this.courses}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $SemesterSummaryCopyWith<$Res> {
  factory $SemesterSummaryCopyWith(
          SemesterSummary value, $Res Function(SemesterSummary) _then) =
      _$SemesterSummaryCopyWithImpl;
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
class _$SemesterSummaryCopyWithImpl<$Res>
    implements $SemesterSummaryCopyWith<$Res> {
  _$SemesterSummaryCopyWithImpl(this._self, this._then);

  final SemesterSummary _self;
  final $Res Function(SemesterSummary) _then;

  /// Create a copy of SemesterSummary
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(SemesterSummary(
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
      tgpa: freezed == tgpa
          ? _self.tgpa
          : tgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      cgpa: freezed == cgpa
          ? _self.cgpa
          : cgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      creditsEarned: freezed == creditsEarned
          ? _self.creditsEarned
          : creditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCreditsEarned: freezed == totalCreditsEarned
          ? _self.totalCreditsEarned
          : totalCreditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      courses: null == courses
          ? _self.courses
          : courses // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SemesterSummary].
extension SemesterSummaryPatterns on SemesterSummary {
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
    TResult Function(_SemesterSummary value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SemesterSummary() when $default != null:
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
    TResult Function(_SemesterSummary value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterSummary():
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
    TResult? Function(_SemesterSummary value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterSummary() when $default != null:
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
            double? tgpa,
            double? cgpa,
            @JsonKey(name: 'credits_earned') double? creditsEarned,
            @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
            List<dynamic> courses,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SemesterSummary() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.tgpa,
            _that.cgpa,
            _that.creditsEarned,
            _that.totalCreditsEarned,
            _that.courses,
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
            double? tgpa,
            double? cgpa,
            @JsonKey(name: 'credits_earned') double? creditsEarned,
            @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
            List<dynamic> courses,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterSummary():
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.tgpa,
            _that.cgpa,
            _that.creditsEarned,
            _that.totalCreditsEarned,
            _that.courses,
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
            double? tgpa,
            double? cgpa,
            @JsonKey(name: 'credits_earned') double? creditsEarned,
            @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
            List<dynamic> courses,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterSummary() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.tgpa,
            _that.cgpa,
            _that.creditsEarned,
            _that.totalCreditsEarned,
            _that.courses,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SemesterSummary implements SemesterSummary {
  const _SemesterSummary(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'semester_code') required this.semesterCode,
      this.tgpa,
      this.cgpa,
      @JsonKey(name: 'credits_earned') this.creditsEarned,
      @JsonKey(name: 'total_credits_earned') this.totalCreditsEarned,
      List<dynamic> courses = const [],
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _courses = courses;
  factory _SemesterSummary.fromJson(Map<String, dynamic> json) =>
      _$SemesterSummaryFromJson(json);

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

  /// Create a copy of SemesterSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SemesterSummaryCopyWith<_SemesterSummary> get copyWith =>
      __$SemesterSummaryCopyWithImpl<_SemesterSummary>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SemesterSummaryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SemesterSummary &&
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
            const DeepCollectionEquality().equals(other.courses, _courses) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
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
  }

  @override
  String toString() {
    return 'SemesterSummary(id: $id, userId: $userId, semesterCode: $semesterCode, tgpa: $tgpa, cgpa: $cgpa, creditsEarned: $creditsEarned, totalCreditsEarned: $totalCreditsEarned, courses: $courses, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$SemesterSummaryCopyWith<$Res>
    implements $SemesterSummaryCopyWith<$Res> {
  factory _$SemesterSummaryCopyWith(
          _SemesterSummary value, $Res Function(_SemesterSummary) _then) =
      __$SemesterSummaryCopyWithImpl;
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
class __$SemesterSummaryCopyWithImpl<$Res>
    implements _$SemesterSummaryCopyWith<$Res> {
  __$SemesterSummaryCopyWithImpl(this._self, this._then);

  final _SemesterSummary _self;
  final $Res Function(_SemesterSummary) _then;

  /// Create a copy of SemesterSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_SemesterSummary(
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
      tgpa: freezed == tgpa
          ? _self.tgpa
          : tgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      cgpa: freezed == cgpa
          ? _self.cgpa
          : cgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      creditsEarned: freezed == creditsEarned
          ? _self.creditsEarned
          : creditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCreditsEarned: freezed == totalCreditsEarned
          ? _self.totalCreditsEarned
          : totalCreditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      courses: null == courses
          ? _self._courses
          : courses // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
