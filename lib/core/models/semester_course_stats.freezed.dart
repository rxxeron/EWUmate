// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semester_course_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SemesterCourseStats _$SemesterCourseStatsFromJson(Map<String, dynamic> json) {
  return _SemesterCourseStats.fromJson(json);
}

/// @nodoc
mixin _$SemesterCourseStats {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  String get semester => throw _privateConstructorUsedError;
  @JsonKey(name: 'course_code')
  String get courseCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'marks_obtained')
  double? get marksObtained => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_possible')
  double get totalPossible => throw _privateConstructorUsedError;
  @JsonKey(name: 'grade_goal')
  String? get gradeGoal => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_updated')
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SemesterCourseStatsCopyWith<SemesterCourseStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SemesterCourseStatsCopyWith<$Res> {
  factory $SemesterCourseStatsCopyWith(
          SemesterCourseStats value, $Res Function(SemesterCourseStats) then) =
      _$SemesterCourseStatsCopyWithImpl<$Res, SemesterCourseStats>;
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
class _$SemesterCourseStatsCopyWithImpl<$Res, $Val extends SemesterCourseStats>
    implements $SemesterCourseStatsCopyWith<$Res> {
  _$SemesterCourseStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semester: null == semester
          ? _value.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _value.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: freezed == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double?,
      totalPossible: null == totalPossible
          ? _value.totalPossible
          : totalPossible // ignore: cast_nullable_to_non_nullable
              as double,
      gradeGoal: freezed == gradeGoal
          ? _value.gradeGoal
          : gradeGoal // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SemesterCourseStatsImplCopyWith<$Res>
    implements $SemesterCourseStatsCopyWith<$Res> {
  factory _$$SemesterCourseStatsImplCopyWith(_$SemesterCourseStatsImpl value,
          $Res Function(_$SemesterCourseStatsImpl) then) =
      __$$SemesterCourseStatsImplCopyWithImpl<$Res>;
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
class __$$SemesterCourseStatsImplCopyWithImpl<$Res>
    extends _$SemesterCourseStatsCopyWithImpl<$Res, _$SemesterCourseStatsImpl>
    implements _$$SemesterCourseStatsImplCopyWith<$Res> {
  __$$SemesterCourseStatsImplCopyWithImpl(_$SemesterCourseStatsImpl _value,
      $Res Function(_$SemesterCourseStatsImpl) _then)
      : super(_value, _then);

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
    return _then(_$SemesterCourseStatsImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semester: null == semester
          ? _value.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _value.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: freezed == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double?,
      totalPossible: null == totalPossible
          ? _value.totalPossible
          : totalPossible // ignore: cast_nullable_to_non_nullable
              as double,
      gradeGoal: freezed == gradeGoal
          ? _value.gradeGoal
          : gradeGoal // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SemesterCourseStatsImpl implements _SemesterCourseStats {
  const _$SemesterCourseStatsImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      required this.semester,
      @JsonKey(name: 'course_code') required this.courseCode,
      @JsonKey(name: 'marks_obtained') this.marksObtained,
      @JsonKey(name: 'total_possible') this.totalPossible = 100.0,
      @JsonKey(name: 'grade_goal') this.gradeGoal,
      @JsonKey(name: 'last_updated') this.lastUpdated});

  factory _$SemesterCourseStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SemesterCourseStatsImplFromJson(json);

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

  @override
  String toString() {
    return 'SemesterCourseStats(id: $id, userId: $userId, semester: $semester, courseCode: $courseCode, marksObtained: $marksObtained, totalPossible: $totalPossible, gradeGoal: $gradeGoal, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SemesterCourseStatsImpl &&
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

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, semester, courseCode,
      marksObtained, totalPossible, gradeGoal, lastUpdated);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SemesterCourseStatsImplCopyWith<_$SemesterCourseStatsImpl> get copyWith =>
      __$$SemesterCourseStatsImplCopyWithImpl<_$SemesterCourseStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SemesterCourseStatsImplToJson(
      this,
    );
  }
}

abstract class _SemesterCourseStats implements SemesterCourseStats {
  const factory _SemesterCourseStats(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          required final String semester,
          @JsonKey(name: 'course_code') required final String courseCode,
          @JsonKey(name: 'marks_obtained') final double? marksObtained,
          @JsonKey(name: 'total_possible') final double totalPossible,
          @JsonKey(name: 'grade_goal') final String? gradeGoal,
          @JsonKey(name: 'last_updated') final DateTime? lastUpdated}) =
      _$SemesterCourseStatsImpl;

  factory _SemesterCourseStats.fromJson(Map<String, dynamic> json) =
      _$SemesterCourseStatsImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  String get semester;
  @override
  @JsonKey(name: 'course_code')
  String get courseCode;
  @override
  @JsonKey(name: 'marks_obtained')
  double? get marksObtained;
  @override
  @JsonKey(name: 'total_possible')
  double get totalPossible;
  @override
  @JsonKey(name: 'grade_goal')
  String? get gradeGoal;
  @override
  @JsonKey(name: 'last_updated')
  DateTime? get lastUpdated;
  @override
  @JsonKey(ignore: true)
  _$$SemesterCourseStatsImplCopyWith<_$SemesterCourseStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
