// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourseMetadata {
  String get code;
  String get name;
  @JsonKey(name: 'credit_val')
  double get creditVal;

  /// Create a copy of CourseMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CourseMetadataCopyWith<CourseMetadata> get copyWith =>
      _$CourseMetadataCopyWithImpl<CourseMetadata>(
          this as CourseMetadata, _$identity);

  /// Serializes this CourseMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as CourseMetadata;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CourseMetadata &&
            (identical(other.code, _this.code) || other.code == _this.code) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.creditVal, _this.creditVal) ||
                other.creditVal == _this.creditVal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as CourseMetadata;
    return Object.hash(runtimeType, _this.code, _this.name, _this.creditVal);
  }

  @override
  String toString() {
    final _this = this as CourseMetadata;
    return 'CourseMetadata(code: ${_this.code}, name: ${_this.name}, creditVal: ${_this.creditVal})';
  }
}

/// @nodoc
abstract mixin class $CourseMetadataCopyWith<$Res> {
  factory $CourseMetadataCopyWith(
          CourseMetadata value, $Res Function(CourseMetadata) _then) =
      _$CourseMetadataCopyWithImpl;
  @useResult
  $Res call(
      {String code,
      String name,
      @JsonKey(name: 'credit_val') double creditVal});
}

/// @nodoc
class _$CourseMetadataCopyWithImpl<$Res>
    implements $CourseMetadataCopyWith<$Res> {
  _$CourseMetadataCopyWithImpl(this._self, this._then);

  final CourseMetadata _self;
  final $Res Function(CourseMetadata) _then;

  /// Create a copy of CourseMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? creditVal = null,
  }) {
    return _then(CourseMetadata(
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      creditVal: null == creditVal
          ? _self.creditVal
          : creditVal // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [CourseMetadata].
extension CourseMetadataPatterns on CourseMetadata {
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
    TResult Function(_CourseMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CourseMetadata() when $default != null:
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
    TResult Function(_CourseMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseMetadata():
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
    TResult? Function(_CourseMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseMetadata() when $default != null:
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
    TResult Function(String code, String name,
            @JsonKey(name: 'credit_val') double creditVal)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CourseMetadata() when $default != null:
        return $default(_that.code, _that.name, _that.creditVal);
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
    TResult Function(String code, String name,
            @JsonKey(name: 'credit_val') double creditVal)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseMetadata():
        return $default(_that.code, _that.name, _that.creditVal);
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
    TResult? Function(String code, String name,
            @JsonKey(name: 'credit_val') double creditVal)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseMetadata() when $default != null:
        return $default(_that.code, _that.name, _that.creditVal);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CourseMetadata implements CourseMetadata {
  const _CourseMetadata(
      {required this.code,
      required this.name,
      @JsonKey(name: 'credit_val') required this.creditVal});
  factory _CourseMetadata.fromJson(Map<String, dynamic> json) =>
      _$CourseMetadataFromJson(json);

  @override
  final String code;
  @override
  final String name;
  @override
  @JsonKey(name: 'credit_val')
  final double creditVal;

  /// Create a copy of CourseMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CourseMetadataCopyWith<_CourseMetadata> get copyWith =>
      __$CourseMetadataCopyWithImpl<_CourseMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CourseMetadataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CourseMetadata &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.creditVal, creditVal) ||
                other.creditVal == creditVal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, code, name, creditVal);
  }

  @override
  String toString() {
    return 'CourseMetadata(code: $code, name: $name, creditVal: $creditVal)';
  }
}

/// @nodoc
abstract mixin class _$CourseMetadataCopyWith<$Res>
    implements $CourseMetadataCopyWith<$Res> {
  factory _$CourseMetadataCopyWith(
          _CourseMetadata value, $Res Function(_CourseMetadata) _then) =
      __$CourseMetadataCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String code,
      String name,
      @JsonKey(name: 'credit_val') double creditVal});
}

/// @nodoc
class __$CourseMetadataCopyWithImpl<$Res>
    implements _$CourseMetadataCopyWith<$Res> {
  __$CourseMetadataCopyWithImpl(this._self, this._then);

  final _CourseMetadata _self;
  final $Res Function(_CourseMetadata) _then;

  /// Create a copy of CourseMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? creditVal = null,
  }) {
    return _then(_CourseMetadata(
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      creditVal: null == creditVal
          ? _self.creditVal
          : creditVal // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on
