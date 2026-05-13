// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'program.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Program _$ProgramFromJson(Map<String, dynamic> json) {
  return _Program.fromJson(json);
}

/// @nodoc
mixin _$Program {
  @JsonKey(name: 'program_code')
  String get programCode => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get track => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_degree_credits')
  double get totalDegreeCredits => throw _privateConstructorUsedError;
  @JsonKey(name: 'department_name')
  String? get departmentName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProgramCopyWith<Program> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgramCopyWith<$Res> {
  factory $ProgramCopyWith(Program value, $Res Function(Program) then) =
      _$ProgramCopyWithImpl<$Res, Program>;
  @useResult
  $Res call(
      {@JsonKey(name: 'program_code') String programCode,
      String name,
      String track,
      @JsonKey(name: 'total_degree_credits') double totalDegreeCredits,
      @JsonKey(name: 'department_name') String? departmentName});
}

/// @nodoc
class _$ProgramCopyWithImpl<$Res, $Val extends Program>
    implements $ProgramCopyWith<$Res> {
  _$ProgramCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? programCode = null,
    Object? name = null,
    Object? track = null,
    Object? totalDegreeCredits = null,
    Object? departmentName = freezed,
  }) {
    return _then(_value.copyWith(
      programCode: null == programCode
          ? _value.programCode
          : programCode // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      track: null == track
          ? _value.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      totalDegreeCredits: null == totalDegreeCredits
          ? _value.totalDegreeCredits
          : totalDegreeCredits // ignore: cast_nullable_to_non_nullable
              as double,
      departmentName: freezed == departmentName
          ? _value.departmentName
          : departmentName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProgramImplCopyWith<$Res> implements $ProgramCopyWith<$Res> {
  factory _$$ProgramImplCopyWith(
          _$ProgramImpl value, $Res Function(_$ProgramImpl) then) =
      __$$ProgramImplCopyWithImpl<$Res>;
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
class __$$ProgramImplCopyWithImpl<$Res>
    extends _$ProgramCopyWithImpl<$Res, _$ProgramImpl>
    implements _$$ProgramImplCopyWith<$Res> {
  __$$ProgramImplCopyWithImpl(
      _$ProgramImpl _value, $Res Function(_$ProgramImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? programCode = null,
    Object? name = null,
    Object? track = null,
    Object? totalDegreeCredits = null,
    Object? departmentName = freezed,
  }) {
    return _then(_$ProgramImpl(
      programCode: null == programCode
          ? _value.programCode
          : programCode // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      track: null == track
          ? _value.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      totalDegreeCredits: null == totalDegreeCredits
          ? _value.totalDegreeCredits
          : totalDegreeCredits // ignore: cast_nullable_to_non_nullable
              as double,
      departmentName: freezed == departmentName
          ? _value.departmentName
          : departmentName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProgramImpl implements _Program {
  const _$ProgramImpl(
      {@JsonKey(name: 'program_code') required this.programCode,
      required this.name,
      required this.track,
      @JsonKey(name: 'total_degree_credits') this.totalDegreeCredits = 130.0,
      @JsonKey(name: 'department_name') this.departmentName});

  factory _$ProgramImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgramImplFromJson(json);

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

  @override
  String toString() {
    return 'Program(programCode: $programCode, name: $name, track: $track, totalDegreeCredits: $totalDegreeCredits, departmentName: $departmentName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgramImpl &&
            (identical(other.programCode, programCode) ||
                other.programCode == programCode) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.track, track) || other.track == track) &&
            (identical(other.totalDegreeCredits, totalDegreeCredits) ||
                other.totalDegreeCredits == totalDegreeCredits) &&
            (identical(other.departmentName, departmentName) ||
                other.departmentName == departmentName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, programCode, name, track,
      totalDegreeCredits, departmentName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgramImplCopyWith<_$ProgramImpl> get copyWith =>
      __$$ProgramImplCopyWithImpl<_$ProgramImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgramImplToJson(
      this,
    );
  }
}

abstract class _Program implements Program {
  const factory _Program(
      {@JsonKey(name: 'program_code') required final String programCode,
      required final String name,
      required final String track,
      @JsonKey(name: 'total_degree_credits') final double totalDegreeCredits,
      @JsonKey(name: 'department_name')
      final String? departmentName}) = _$ProgramImpl;

  factory _Program.fromJson(Map<String, dynamic> json) = _$ProgramImpl.fromJson;

  @override
  @JsonKey(name: 'program_code')
  String get programCode;
  @override
  String get name;
  @override
  String get track;
  @override
  @JsonKey(name: 'total_degree_credits')
  double get totalDegreeCredits;
  @override
  @JsonKey(name: 'department_name')
  String? get departmentName;
  @override
  @JsonKey(ignore: true)
  _$$ProgramImplCopyWith<_$ProgramImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
