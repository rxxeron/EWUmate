// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Task _$TaskFromJson(Map<String, dynamic> json) {
  return _Task.fromJson(json);
}

/// @nodoc
mixin _$Task {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'course_code')
  String? get courseCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'course_name')
  String? get courseName => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_date')
  DateTime? get assignDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  DateTime? get dueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'submission_type')
  String? get submissionType => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_missed')
  bool get isMissed => throw _privateConstructorUsedError;
  @JsonKey(name: 'semester_code')
  String? get semesterCode => throw _privateConstructorUsedError;
  String? get track => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res, Task>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String title,
      @JsonKey(name: 'course_code') String? courseCode,
      @JsonKey(name: 'course_name') String? courseName,
      @JsonKey(name: 'assign_date') DateTime? assignDate,
      @JsonKey(name: 'due_date') DateTime? dueDate,
      @JsonKey(name: 'submission_type') String? submissionType,
      String? type,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'is_missed') bool isMissed,
      @JsonKey(name: 'semester_code') String? semesterCode,
      String? track,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$TaskCopyWithImpl<$Res, $Val extends Task>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? courseCode = freezed,
    Object? courseName = freezed,
    Object? assignDate = freezed,
    Object? dueDate = freezed,
    Object? submissionType = freezed,
    Object? type = freezed,
    Object? isCompleted = null,
    Object? isMissed = null,
    Object? semesterCode = freezed,
    Object? track = freezed,
    Object? createdAt = freezed,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: freezed == courseCode
          ? _value.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      courseName: freezed == courseName
          ? _value.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String?,
      assignDate: freezed == assignDate
          ? _value.assignDate
          : assignDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      submissionType: freezed == submissionType
          ? _value.submissionType
          : submissionType // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      isMissed: null == isMissed
          ? _value.isMissed
          : isMissed // ignore: cast_nullable_to_non_nullable
              as bool,
      semesterCode: freezed == semesterCode
          ? _value.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _value.track
          : track // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskImplCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$$TaskImplCopyWith(
          _$TaskImpl value, $Res Function(_$TaskImpl) then) =
      __$$TaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String title,
      @JsonKey(name: 'course_code') String? courseCode,
      @JsonKey(name: 'course_name') String? courseName,
      @JsonKey(name: 'assign_date') DateTime? assignDate,
      @JsonKey(name: 'due_date') DateTime? dueDate,
      @JsonKey(name: 'submission_type') String? submissionType,
      String? type,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'is_missed') bool isMissed,
      @JsonKey(name: 'semester_code') String? semesterCode,
      String? track,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$TaskImplCopyWithImpl<$Res>
    extends _$TaskCopyWithImpl<$Res, _$TaskImpl>
    implements _$$TaskImplCopyWith<$Res> {
  __$$TaskImplCopyWithImpl(_$TaskImpl _value, $Res Function(_$TaskImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? courseCode = freezed,
    Object? courseName = freezed,
    Object? assignDate = freezed,
    Object? dueDate = freezed,
    Object? submissionType = freezed,
    Object? type = freezed,
    Object? isCompleted = null,
    Object? isMissed = null,
    Object? semesterCode = freezed,
    Object? track = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$TaskImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: freezed == courseCode
          ? _value.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      courseName: freezed == courseName
          ? _value.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String?,
      assignDate: freezed == assignDate
          ? _value.assignDate
          : assignDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      submissionType: freezed == submissionType
          ? _value.submissionType
          : submissionType // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      isMissed: null == isMissed
          ? _value.isMissed
          : isMissed // ignore: cast_nullable_to_non_nullable
              as bool,
      semesterCode: freezed == semesterCode
          ? _value.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _value.track
          : track // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskImpl implements _Task {
  const _$TaskImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      required this.title,
      @JsonKey(name: 'course_code') this.courseCode,
      @JsonKey(name: 'course_name') this.courseName,
      @JsonKey(name: 'assign_date') this.assignDate,
      @JsonKey(name: 'due_date') this.dueDate,
      @JsonKey(name: 'submission_type') this.submissionType,
      this.type,
      @JsonKey(name: 'is_completed') this.isCompleted = false,
      @JsonKey(name: 'is_missed') this.isMissed = false,
      @JsonKey(name: 'semester_code') this.semesterCode,
      this.track,
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$TaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final String title;
  @override
  @JsonKey(name: 'course_code')
  final String? courseCode;
  @override
  @JsonKey(name: 'course_name')
  final String? courseName;
  @override
  @JsonKey(name: 'assign_date')
  final DateTime? assignDate;
  @override
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @override
  @JsonKey(name: 'submission_type')
  final String? submissionType;
  @override
  final String? type;
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @override
  @JsonKey(name: 'is_missed')
  final bool isMissed;
  @override
  @JsonKey(name: 'semester_code')
  final String? semesterCode;
  @override
  final String? track;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Task(id: $id, userId: $userId, title: $title, courseCode: $courseCode, courseName: $courseName, assignDate: $assignDate, dueDate: $dueDate, submissionType: $submissionType, type: $type, isCompleted: $isCompleted, isMissed: $isMissed, semesterCode: $semesterCode, track: $track, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.courseCode, courseCode) ||
                other.courseCode == courseCode) &&
            (identical(other.courseName, courseName) ||
                other.courseName == courseName) &&
            (identical(other.assignDate, assignDate) ||
                other.assignDate == assignDate) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.submissionType, submissionType) ||
                other.submissionType == submissionType) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.isMissed, isMissed) ||
                other.isMissed == isMissed) &&
            (identical(other.semesterCode, semesterCode) ||
                other.semesterCode == semesterCode) &&
            (identical(other.track, track) || other.track == track) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      title,
      courseCode,
      courseName,
      assignDate,
      dueDate,
      submissionType,
      type,
      isCompleted,
      isMissed,
      semesterCode,
      track,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      __$$TaskImplCopyWithImpl<_$TaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskImplToJson(
      this,
    );
  }
}

abstract class _Task implements Task {
  const factory _Task(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      required final String title,
      @JsonKey(name: 'course_code') final String? courseCode,
      @JsonKey(name: 'course_name') final String? courseName,
      @JsonKey(name: 'assign_date') final DateTime? assignDate,
      @JsonKey(name: 'due_date') final DateTime? dueDate,
      @JsonKey(name: 'submission_type') final String? submissionType,
      final String? type,
      @JsonKey(name: 'is_completed') final bool isCompleted,
      @JsonKey(name: 'is_missed') final bool isMissed,
      @JsonKey(name: 'semester_code') final String? semesterCode,
      final String? track,
      @JsonKey(name: 'created_at') final DateTime? createdAt}) = _$TaskImpl;

  factory _Task.fromJson(Map<String, dynamic> json) = _$TaskImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  String get title;
  @override
  @JsonKey(name: 'course_code')
  String? get courseCode;
  @override
  @JsonKey(name: 'course_name')
  String? get courseName;
  @override
  @JsonKey(name: 'assign_date')
  DateTime? get assignDate;
  @override
  @JsonKey(name: 'due_date')
  DateTime? get dueDate;
  @override
  @JsonKey(name: 'submission_type')
  String? get submissionType;
  @override
  String? get type;
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(name: 'is_missed')
  bool get isMissed;
  @override
  @JsonKey(name: 'semester_code')
  String? get semesterCode;
  @override
  String? get track;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
