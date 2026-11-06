// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semester_analytics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SemesterAnalytics {
  String get id;
  @JsonKey(name: 'user_id')
  String get userId;
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  @JsonKey(name: 'live_sgpa')
  double? get liveSgpa;
  @JsonKey(name: 'live_cgpa')
  double? get liveCgpa;
  double? get target;
  @JsonKey(name: 'required_credit')
  double? get requiredCredit;
  @JsonKey(name: 'completed_credit')
  double? get completedCredit;
  @JsonKey(name: 'taken_in_this_sem')
  double? get takenInThisSem;
  @JsonKey(name: 'credits_left')
  double? get creditsLeft;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of SemesterAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SemesterAnalyticsCopyWith<SemesterAnalytics> get copyWith =>
      _$SemesterAnalyticsCopyWithImpl<SemesterAnalytics>(
          this as SemesterAnalytics, _$identity);

  /// Serializes this SemesterAnalytics to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SemesterAnalytics;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SemesterAnalytics &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.semesterCode, _this.semesterCode) ||
                other.semesterCode == _this.semesterCode) &&
            (identical(other.liveSgpa, _this.liveSgpa) ||
                other.liveSgpa == _this.liveSgpa) &&
            (identical(other.liveCgpa, _this.liveCgpa) ||
                other.liveCgpa == _this.liveCgpa) &&
            (identical(other.target, _this.target) ||
                other.target == _this.target) &&
            (identical(other.requiredCredit, _this.requiredCredit) ||
                other.requiredCredit == _this.requiredCredit) &&
            (identical(other.completedCredit, _this.completedCredit) ||
                other.completedCredit == _this.completedCredit) &&
            (identical(other.takenInThisSem, _this.takenInThisSem) ||
                other.takenInThisSem == _this.takenInThisSem) &&
            (identical(other.creditsLeft, _this.creditsLeft) ||
                other.creditsLeft == _this.creditsLeft) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SemesterAnalytics;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.userId,
        _this.semesterCode,
        _this.liveSgpa,
        _this.liveCgpa,
        _this.target,
        _this.requiredCredit,
        _this.completedCredit,
        _this.takenInThisSem,
        _this.creditsLeft,
        _this.createdAt,
        _this.updatedAt);
  }

  @override
  String toString() {
    final _this = this as SemesterAnalytics;
    return 'SemesterAnalytics(id: ${_this.id}, userId: ${_this.userId}, semesterCode: ${_this.semesterCode}, liveSgpa: ${_this.liveSgpa}, liveCgpa: ${_this.liveCgpa}, target: ${_this.target}, requiredCredit: ${_this.requiredCredit}, completedCredit: ${_this.completedCredit}, takenInThisSem: ${_this.takenInThisSem}, creditsLeft: ${_this.creditsLeft}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $SemesterAnalyticsCopyWith<$Res> {
  factory $SemesterAnalyticsCopyWith(
          SemesterAnalytics value, $Res Function(SemesterAnalytics) _then) =
      _$SemesterAnalyticsCopyWithImpl;
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
class _$SemesterAnalyticsCopyWithImpl<$Res>
    implements $SemesterAnalyticsCopyWith<$Res> {
  _$SemesterAnalyticsCopyWithImpl(this._self, this._then);

  final SemesterAnalytics _self;
  final $Res Function(SemesterAnalytics) _then;

  /// Create a copy of SemesterAnalytics
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(SemesterAnalytics(
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
      liveSgpa: freezed == liveSgpa
          ? _self.liveSgpa
          : liveSgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      liveCgpa: freezed == liveCgpa
          ? _self.liveCgpa
          : liveCgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      target: freezed == target
          ? _self.target
          : target // ignore: cast_nullable_to_non_nullable
              as double?,
      requiredCredit: freezed == requiredCredit
          ? _self.requiredCredit
          : requiredCredit // ignore: cast_nullable_to_non_nullable
              as double?,
      completedCredit: freezed == completedCredit
          ? _self.completedCredit
          : completedCredit // ignore: cast_nullable_to_non_nullable
              as double?,
      takenInThisSem: freezed == takenInThisSem
          ? _self.takenInThisSem
          : takenInThisSem // ignore: cast_nullable_to_non_nullable
              as double?,
      creditsLeft: freezed == creditsLeft
          ? _self.creditsLeft
          : creditsLeft // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SemesterAnalytics].
extension SemesterAnalyticsPatterns on SemesterAnalytics {
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
    TResult Function(_SemesterAnalytics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SemesterAnalytics() when $default != null:
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
    TResult Function(_SemesterAnalytics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterAnalytics():
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
    TResult? Function(_SemesterAnalytics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterAnalytics() when $default != null:
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
            @JsonKey(name: 'live_sgpa') double? liveSgpa,
            @JsonKey(name: 'live_cgpa') double? liveCgpa,
            double? target,
            @JsonKey(name: 'required_credit') double? requiredCredit,
            @JsonKey(name: 'completed_credit') double? completedCredit,
            @JsonKey(name: 'taken_in_this_sem') double? takenInThisSem,
            @JsonKey(name: 'credits_left') double? creditsLeft,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SemesterAnalytics() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.liveSgpa,
            _that.liveCgpa,
            _that.target,
            _that.requiredCredit,
            _that.completedCredit,
            _that.takenInThisSem,
            _that.creditsLeft,
            _that.createdAt,
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
            @JsonKey(name: 'live_sgpa') double? liveSgpa,
            @JsonKey(name: 'live_cgpa') double? liveCgpa,
            double? target,
            @JsonKey(name: 'required_credit') double? requiredCredit,
            @JsonKey(name: 'completed_credit') double? completedCredit,
            @JsonKey(name: 'taken_in_this_sem') double? takenInThisSem,
            @JsonKey(name: 'credits_left') double? creditsLeft,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterAnalytics():
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.liveSgpa,
            _that.liveCgpa,
            _that.target,
            _that.requiredCredit,
            _that.completedCredit,
            _that.takenInThisSem,
            _that.creditsLeft,
            _that.createdAt,
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
            @JsonKey(name: 'live_sgpa') double? liveSgpa,
            @JsonKey(name: 'live_cgpa') double? liveCgpa,
            double? target,
            @JsonKey(name: 'required_credit') double? requiredCredit,
            @JsonKey(name: 'completed_credit') double? completedCredit,
            @JsonKey(name: 'taken_in_this_sem') double? takenInThisSem,
            @JsonKey(name: 'credits_left') double? creditsLeft,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterAnalytics() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.liveSgpa,
            _that.liveCgpa,
            _that.target,
            _that.requiredCredit,
            _that.completedCredit,
            _that.takenInThisSem,
            _that.creditsLeft,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SemesterAnalytics implements SemesterAnalytics {
  const _SemesterAnalytics(
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
  factory _SemesterAnalytics.fromJson(Map<String, dynamic> json) =>
      _$SemesterAnalyticsFromJson(json);

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

  /// Create a copy of SemesterAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SemesterAnalyticsCopyWith<_SemesterAnalytics> get copyWith =>
      __$SemesterAnalyticsCopyWithImpl<_SemesterAnalytics>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SemesterAnalyticsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SemesterAnalytics &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
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
  }

  @override
  String toString() {
    return 'SemesterAnalytics(id: $id, userId: $userId, semesterCode: $semesterCode, liveSgpa: $liveSgpa, liveCgpa: $liveCgpa, target: $target, requiredCredit: $requiredCredit, completedCredit: $completedCredit, takenInThisSem: $takenInThisSem, creditsLeft: $creditsLeft, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$SemesterAnalyticsCopyWith<$Res>
    implements $SemesterAnalyticsCopyWith<$Res> {
  factory _$SemesterAnalyticsCopyWith(
          _SemesterAnalytics value, $Res Function(_SemesterAnalytics) _then) =
      __$SemesterAnalyticsCopyWithImpl;
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
class __$SemesterAnalyticsCopyWithImpl<$Res>
    implements _$SemesterAnalyticsCopyWith<$Res> {
  __$SemesterAnalyticsCopyWithImpl(this._self, this._then);

  final _SemesterAnalytics _self;
  final $Res Function(_SemesterAnalytics) _then;

  /// Create a copy of SemesterAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_SemesterAnalytics(
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
      liveSgpa: freezed == liveSgpa
          ? _self.liveSgpa
          : liveSgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      liveCgpa: freezed == liveCgpa
          ? _self.liveCgpa
          : liveCgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      target: freezed == target
          ? _self.target
          : target // ignore: cast_nullable_to_non_nullable
              as double?,
      requiredCredit: freezed == requiredCredit
          ? _self.requiredCredit
          : requiredCredit // ignore: cast_nullable_to_non_nullable
              as double?,
      completedCredit: freezed == completedCredit
          ? _self.completedCredit
          : completedCredit // ignore: cast_nullable_to_non_nullable
              as double?,
      takenInThisSem: freezed == takenInThisSem
          ? _self.takenInThisSem
          : takenInThisSem // ignore: cast_nullable_to_non_nullable
              as double?,
      creditsLeft: freezed == creditsLeft
          ? _self.creditsLeft
          : creditsLeft // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
