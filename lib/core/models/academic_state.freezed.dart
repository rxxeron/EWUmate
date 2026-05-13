// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'academic_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AcademicState _$AcademicStateFromJson(Map<String, dynamic> json) {
  return _AcademicState.fromJson(json);
}

/// @nodoc
mixin _$AcademicState {
  String get track => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_semester_code')
  String get currentSemesterCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'next_semester_code')
  String get nextSemesterCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'advising_start_date')
  DateTime? get advisingStartDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'advising_end_date')
  DateTime? get advisingEndDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'classes_start_date')
  DateTime? get classesStartDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'semester_switch_date')
  DateTime? get semesterSwitchDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'upcoming_classes_start_date')
  DateTime? get upcomingClassesStartDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AcademicStateCopyWith<AcademicState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AcademicStateCopyWith<$Res> {
  factory $AcademicStateCopyWith(
          AcademicState value, $Res Function(AcademicState) then) =
      _$AcademicStateCopyWithImpl<$Res, AcademicState>;
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
class _$AcademicStateCopyWithImpl<$Res, $Val extends AcademicState>
    implements $AcademicStateCopyWith<$Res> {
  _$AcademicStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      track: null == track
          ? _value.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      currentSemesterCode: null == currentSemesterCode
          ? _value.currentSemesterCode
          : currentSemesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      nextSemesterCode: null == nextSemesterCode
          ? _value.nextSemesterCode
          : nextSemesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      advisingStartDate: freezed == advisingStartDate
          ? _value.advisingStartDate
          : advisingStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      advisingEndDate: freezed == advisingEndDate
          ? _value.advisingEndDate
          : advisingEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      classesStartDate: freezed == classesStartDate
          ? _value.classesStartDate
          : classesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      semesterSwitchDate: freezed == semesterSwitchDate
          ? _value.semesterSwitchDate
          : semesterSwitchDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      upcomingClassesStartDate: freezed == upcomingClassesStartDate
          ? _value.upcomingClassesStartDate
          : upcomingClassesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AcademicStateImplCopyWith<$Res>
    implements $AcademicStateCopyWith<$Res> {
  factory _$$AcademicStateImplCopyWith(
          _$AcademicStateImpl value, $Res Function(_$AcademicStateImpl) then) =
      __$$AcademicStateImplCopyWithImpl<$Res>;
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
class __$$AcademicStateImplCopyWithImpl<$Res>
    extends _$AcademicStateCopyWithImpl<$Res, _$AcademicStateImpl>
    implements _$$AcademicStateImplCopyWith<$Res> {
  __$$AcademicStateImplCopyWithImpl(
      _$AcademicStateImpl _value, $Res Function(_$AcademicStateImpl) _then)
      : super(_value, _then);

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
    return _then(_$AcademicStateImpl(
      track: null == track
          ? _value.track
          : track // ignore: cast_nullable_to_non_nullable
              as String,
      currentSemesterCode: null == currentSemesterCode
          ? _value.currentSemesterCode
          : currentSemesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      nextSemesterCode: null == nextSemesterCode
          ? _value.nextSemesterCode
          : nextSemesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      advisingStartDate: freezed == advisingStartDate
          ? _value.advisingStartDate
          : advisingStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      advisingEndDate: freezed == advisingEndDate
          ? _value.advisingEndDate
          : advisingEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      classesStartDate: freezed == classesStartDate
          ? _value.classesStartDate
          : classesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      semesterSwitchDate: freezed == semesterSwitchDate
          ? _value.semesterSwitchDate
          : semesterSwitchDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      upcomingClassesStartDate: freezed == upcomingClassesStartDate
          ? _value.upcomingClassesStartDate
          : upcomingClassesStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AcademicStateImpl implements _AcademicState {
  const _$AcademicStateImpl(
      {required this.track,
      @JsonKey(name: 'current_semester_code') required this.currentSemesterCode,
      @JsonKey(name: 'next_semester_code') required this.nextSemesterCode,
      @JsonKey(name: 'advising_start_date') this.advisingStartDate,
      @JsonKey(name: 'advising_end_date') this.advisingEndDate,
      @JsonKey(name: 'classes_start_date') this.classesStartDate,
      @JsonKey(name: 'semester_switch_date') this.semesterSwitchDate,
      @JsonKey(name: 'upcoming_classes_start_date')
      this.upcomingClassesStartDate});

  factory _$AcademicStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$AcademicStateImplFromJson(json);

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

  @override
  String toString() {
    return 'AcademicState(track: $track, currentSemesterCode: $currentSemesterCode, nextSemesterCode: $nextSemesterCode, advisingStartDate: $advisingStartDate, advisingEndDate: $advisingEndDate, classesStartDate: $classesStartDate, semesterSwitchDate: $semesterSwitchDate, upcomingClassesStartDate: $upcomingClassesStartDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AcademicStateImpl &&
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

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      track,
      currentSemesterCode,
      nextSemesterCode,
      advisingStartDate,
      advisingEndDate,
      classesStartDate,
      semesterSwitchDate,
      upcomingClassesStartDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AcademicStateImplCopyWith<_$AcademicStateImpl> get copyWith =>
      __$$AcademicStateImplCopyWithImpl<_$AcademicStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AcademicStateImplToJson(
      this,
    );
  }
}

abstract class _AcademicState implements AcademicState {
  const factory _AcademicState(
      {required final String track,
      @JsonKey(name: 'current_semester_code')
      required final String currentSemesterCode,
      @JsonKey(name: 'next_semester_code')
      required final String nextSemesterCode,
      @JsonKey(name: 'advising_start_date') final DateTime? advisingStartDate,
      @JsonKey(name: 'advising_end_date') final DateTime? advisingEndDate,
      @JsonKey(name: 'classes_start_date') final DateTime? classesStartDate,
      @JsonKey(name: 'semester_switch_date') final DateTime? semesterSwitchDate,
      @JsonKey(name: 'upcoming_classes_start_date')
      final DateTime? upcomingClassesStartDate}) = _$AcademicStateImpl;

  factory _AcademicState.fromJson(Map<String, dynamic> json) =
      _$AcademicStateImpl.fromJson;

  @override
  String get track;
  @override
  @JsonKey(name: 'current_semester_code')
  String get currentSemesterCode;
  @override
  @JsonKey(name: 'next_semester_code')
  String get nextSemesterCode;
  @override
  @JsonKey(name: 'advising_start_date')
  DateTime? get advisingStartDate;
  @override
  @JsonKey(name: 'advising_end_date')
  DateTime? get advisingEndDate;
  @override
  @JsonKey(name: 'classes_start_date')
  DateTime? get classesStartDate;
  @override
  @JsonKey(name: 'semester_switch_date')
  DateTime? get semesterSwitchDate;
  @override
  @JsonKey(name: 'upcoming_classes_start_date')
  DateTime? get upcomingClassesStartDate;
  @override
  @JsonKey(ignore: true)
  _$$AcademicStateImplCopyWith<_$AcademicStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
