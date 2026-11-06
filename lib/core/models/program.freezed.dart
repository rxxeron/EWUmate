// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'program.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Program {
  @JsonKey(name: 'program_code')
  String get programCode;
  String get name;
  String get track;
  @JsonKey(name: 'total_degree_credits')
  double get totalDegreeCredits;
  @JsonKey(name: 'department_name')
  String? get departmentName;

  /// Create a copy of Program
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProgramCopyWith<Program> get copyWith =>
      _$ProgramCopyWithImpl<Program>(this as Program, _$identity);

  /// Serializes this Program to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Program;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Program &&
            (identical(other.programCode, _this.programCode) ||
                other.programCode == _this.programCode) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.track, _this.track) ||
                other.track == _this.track) &&
            (identical(other.totalDegreeCredits, _this.totalDegreeCredits) ||
                other.totalDegreeCredits == _this.totalDegreeCredits) &&
            (identical(other.departmentName, _this.departmentName) ||
                other.departmentName == _this.departmentName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Program;
    return Object.hash(runtimeType, _this.programCode, _this.name, _this.track,
        _this.totalDegreeCredits, _this.departmentName);
  }

  @override
  String toString() {
    final _this = this as Program;
    return 'Program(programCode: ${_this.programCode}, name: ${_this.name}, track: ${_this.track}, totalDegreeCredits: ${_this.totalDegreeCredits}, departmentName: ${_this.departmentName})';
  }
}

/// @nodoc
abstract mixin class $ProgramCopyWith<$Res> {
  factory $ProgramCopyWith(Program value, $Res Function(Program) _then) =
      _$ProgramCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'program_code') String programCode,
      String name,
      String track,
      @JsonKey(name: 'total_degree_credits') double totalDegreeCredits,
      @JsonKey(name: 'department_name') String? departmentName});
}

/// @nodoc
class _$ProgramCopyWithImpl<$Res> implements $ProgramCopyWith<$Res> {
  _$ProgramCopyWithImpl(this._self, this._then);

  final Program _self;
  final $Res Function(Program) _then;

  /// Create a copy of Program
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? programCode = null,
    Object? name = null,
    Object? track = null,
    Object? totalDegreeCredits = null,
    Object? departmentName = freezed,
  }) {
    return _then(Program(
      programCode: null == programCode
          ? _self.programCode
          : programCode // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      track: null == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      totalDegreeCredits: null == totalDegreeCredits
          ? _self.totalDegreeCredits
          : totalDegreeCredits // ignore: cast_nullable_to_non_nullable
              as double,
      departmentName: freezed == departmentName
          ? _self.departmentName
          : departmentName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Program].
extension ProgramPatterns on Program {
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
    TResult Function(_Program value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Program() when $default != null:
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
    TResult Function(_Program value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Program():
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
    TResult? Function(_Program value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Program() when $default != null:
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
            @JsonKey(name: 'program_code') String programCode,
            String name,
            String track,
            @JsonKey(name: 'total_degree_credits') double totalDegreeCredits,
            @JsonKey(name: 'department_name') String? departmentName)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Program() when $default != null:
        return $default(_that.programCode, _that.name, _that.track,
            _that.totalDegreeCredits, _that.departmentName);
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
            @JsonKey(name: 'program_code') String programCode,
            String name,
            String track,
            @JsonKey(name: 'total_degree_credits') double totalDegreeCredits,
            @JsonKey(name: 'department_name') String? departmentName)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Program():
        return $default(_that.programCode, _that.name, _that.track,
            _that.totalDegreeCredits, _that.departmentName);
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
            @JsonKey(name: 'program_code') String programCode,
            String name,
            String track,
            @JsonKey(name: 'total_degree_credits') double totalDegreeCredits,
            @JsonKey(name: 'department_name') String? departmentName)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Program() when $default != null:
        return $default(_that.programCode, _that.name, _that.track,
            _that.totalDegreeCredits, _that.departmentName);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Program implements Program {
  const _Program(
      {@JsonKey(name: 'program_code') required this.programCode,
      required this.name,
      required this.track,
      @JsonKey(name: 'total_degree_credits') this.totalDegreeCredits = 130.0,
      @JsonKey(name: 'department_name') this.departmentName});
  factory _Program.fromJson(Map<String, dynamic> json) =>
      _$ProgramFromJson(json);

  @override
  @JsonKey(name: 'program_code')
  final String programCode;
  @override
  final String name;
  @override
  final String track;
  @override
  @JsonKey(name: 'total_degree_credits')
  final double totalDegreeCredits;
  @override
  @JsonKey(name: 'department_name')
  final String? departmentName;

  /// Create a copy of Program
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProgramCopyWith<_Program> get copyWith =>
      __$ProgramCopyWithImpl<_Program>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProgramToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Program &&
            (identical(other.programCode, programCode) ||
                other.programCode == programCode) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.track, track) || other.track == track) &&
            (identical(other.totalDegreeCredits, totalDegreeCredits) ||
                other.totalDegreeCredits == totalDegreeCredits) &&
            (identical(other.departmentName, departmentName) ||
                other.departmentName == departmentName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, programCode, name, track,
        totalDegreeCredits, departmentName);
  }

  @override
  String toString() {
    return 'Program(programCode: $programCode, name: $name, track: $track, totalDegreeCredits: $totalDegreeCredits, departmentName: $departmentName)';
  }
}

/// @nodoc
abstract mixin class _$ProgramCopyWith<$Res> implements $ProgramCopyWith<$Res> {
  factory _$ProgramCopyWith(_Program value, $Res Function(_Program) _then) =
      __$ProgramCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'program_code') String programCode,
      String name,
      String track,
      @JsonKey(name: 'total_degree_credits') double totalDegreeCredits,
      @JsonKey(name: 'department_name') String? departmentName});
}

/// @nodoc
class __$ProgramCopyWithImpl<$Res> implements _$ProgramCopyWith<$Res> {
  __$ProgramCopyWithImpl(this._self, this._then);

  final _Program _self;
  final $Res Function(_Program) _then;

  /// Create a copy of Program
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? programCode = null,
    Object? name = null,
    Object? track = null,
    Object? totalDegreeCredits = null,
    Object? departmentName = freezed,
  }) {
    return _then(_Program(
      programCode: null == programCode
          ? _self.programCode
          : programCode // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      track: null == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      totalDegreeCredits: null == totalDegreeCredits
          ? _self.totalDegreeCredits
          : totalDegreeCredits // ignore: cast_nullable_to_non_nullable
              as double,
      departmentName: freezed == departmentName
          ? _self.departmentName
          : departmentName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
