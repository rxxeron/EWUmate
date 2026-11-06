// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semester.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Semester {
  String get code;
  String get title;
  @JsonKey(name: 'is_active')
  bool get isActive;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Semester
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SemesterCopyWith<Semester> get copyWith =>
      _$SemesterCopyWithImpl<Semester>(this as Semester, _$identity);

  /// Serializes this Semester to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Semester;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Semester &&
            (identical(other.code, _this.code) || other.code == _this.code) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.isActive, _this.isActive) ||
                other.isActive == _this.isActive) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Semester;
    return Object.hash(
        runtimeType, _this.code, _this.title, _this.isActive, _this.createdAt);
  }

  @override
  String toString() {
    final _this = this as Semester;
    return 'Semester(code: ${_this.code}, title: ${_this.title}, isActive: ${_this.isActive}, createdAt: ${_this.createdAt})';
  }
}

/// @nodoc
abstract mixin class $SemesterCopyWith<$Res> {
  factory $SemesterCopyWith(Semester value, $Res Function(Semester) _then) =
      _$SemesterCopyWithImpl;
  @useResult
  $Res call(
      {String code,
      String title,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$SemesterCopyWithImpl<$Res> implements $SemesterCopyWith<$Res> {
  _$SemesterCopyWithImpl(this._self, this._then);

  final Semester _self;
  final $Res Function(Semester) _then;

  /// Create a copy of Semester
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? title = null,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(Semester(
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Semester].
extension SemesterPatterns on Semester {
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
    TResult Function(_Semester value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Semester() when $default != null:
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
    TResult Function(_Semester value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Semester():
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
    TResult? Function(_Semester value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Semester() when $default != null:
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
            String code,
            String title,
            @JsonKey(name: 'is_active') bool isActive,
            @JsonKey(name: 'created_at') DateTime? createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Semester() when $default != null:
        return $default(
            _that.code, _that.title, _that.isActive, _that.createdAt);
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
            String code,
            String title,
            @JsonKey(name: 'is_active') bool isActive,
            @JsonKey(name: 'created_at') DateTime? createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Semester():
        return $default(
            _that.code, _that.title, _that.isActive, _that.createdAt);
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
            String code,
            String title,
            @JsonKey(name: 'is_active') bool isActive,
            @JsonKey(name: 'created_at') DateTime? createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Semester() when $default != null:
        return $default(
            _that.code, _that.title, _that.isActive, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Semester implements Semester {
  const _Semester(
      {required this.code,
      required this.title,
      @JsonKey(name: 'is_active') this.isActive = false,
      @JsonKey(name: 'created_at') this.createdAt});
  factory _Semester.fromJson(Map<String, dynamic> json) =>
      _$SemesterFromJson(json);

  @override
  final String code;
  @override
  final String title;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Create a copy of Semester
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SemesterCopyWith<_Semester> get copyWith =>
      __$SemesterCopyWithImpl<_Semester>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SemesterToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Semester &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, code, title, isActive, createdAt);
  }

  @override
  String toString() {
    return 'Semester(code: $code, title: $title, isActive: $isActive, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$SemesterCopyWith<$Res>
    implements $SemesterCopyWith<$Res> {
  factory _$SemesterCopyWith(_Semester value, $Res Function(_Semester) _then) =
      __$SemesterCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String code,
      String title,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$SemesterCopyWithImpl<$Res> implements _$SemesterCopyWith<$Res> {
  __$SemesterCopyWithImpl(this._self, this._then);

  final _Semester _self;
  final $Res Function(_Semester) _then;

  /// Create a copy of Semester
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? code = null,
    Object? title = null,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(_Semester(
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
