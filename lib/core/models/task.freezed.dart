// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {
  String get id;
  @JsonKey(name: 'user_id')
  String get userId;
  String get title;
  @JsonKey(name: 'course_code')
  String? get courseCode;
  @JsonKey(name: 'course_name')
  String? get courseName;
  @JsonKey(name: 'assign_date')
  DateTime? get assignDate;
  @JsonKey(name: 'due_date')
  DateTime? get dueDate;
  @JsonKey(name: 'submission_type')
  String? get submissionType;
  String? get type;
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @JsonKey(name: 'is_missed')
  bool get isMissed;
  @JsonKey(name: 'semester_code')
  String? get semesterCode;
  String? get track;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TaskCopyWith<Task> get copyWith =>
      _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Task;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Task &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.courseCode, _this.courseCode) ||
                other.courseCode == _this.courseCode) &&
            (identical(other.courseName, _this.courseName) ||
                other.courseName == _this.courseName) &&
            (identical(other.assignDate, _this.assignDate) ||
                other.assignDate == _this.assignDate) &&
            (identical(other.dueDate, _this.dueDate) ||
                other.dueDate == _this.dueDate) &&
            (identical(other.submissionType, _this.submissionType) ||
                other.submissionType == _this.submissionType) &&
            (identical(other.type, _this.type) || other.type == _this.type) &&
            (identical(other.isCompleted, _this.isCompleted) ||
                other.isCompleted == _this.isCompleted) &&
            (identical(other.isMissed, _this.isMissed) ||
                other.isMissed == _this.isMissed) &&
            (identical(other.semesterCode, _this.semesterCode) ||
                other.semesterCode == _this.semesterCode) &&
            (identical(other.track, _this.track) ||
                other.track == _this.track) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Task;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.userId,
        _this.title,
        _this.courseCode,
        _this.courseName,
        _this.assignDate,
        _this.dueDate,
        _this.submissionType,
        _this.type,
        _this.isCompleted,
        _this.isMissed,
        _this.semesterCode,
        _this.track,
        _this.createdAt);
  }

  @override
  String toString() {
    final _this = this as Task;
    return 'Task(id: ${_this.id}, userId: ${_this.userId}, title: ${_this.title}, courseCode: ${_this.courseCode}, courseName: ${_this.courseName}, assignDate: ${_this.assignDate}, dueDate: ${_this.dueDate}, submissionType: ${_this.submissionType}, type: ${_this.type}, isCompleted: ${_this.isCompleted}, isMissed: ${_this.isMissed}, semesterCode: ${_this.semesterCode}, track: ${_this.track}, createdAt: ${_this.createdAt})';
  }
}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) =
      _$TaskCopyWithImpl;
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
class _$TaskCopyWithImpl<$Res> implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(Task(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: freezed == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      courseName: freezed == courseName
          ? _self.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String?,
      assignDate: freezed == assignDate
          ? _self.assignDate
          : assignDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDate: freezed == dueDate
          ? _self.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      submissionType: freezed == submissionType
          ? _self.submissionType
          : submissionType // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      isMissed: null == isMissed
          ? _self.isMissed
          : isMissed // ignore: cast_nullable_to_non_nullable
              as bool,
      semesterCode: freezed == semesterCode
          ? _self.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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
    TResult Function(_Task value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Task() when $default != null:
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
    TResult Function(_Task value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Task():
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
    TResult? Function(_Task value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Task() when $default != null:
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
            @JsonKey(name: 'created_at') DateTime? createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Task() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.title,
            _that.courseCode,
            _that.courseName,
            _that.assignDate,
            _that.dueDate,
            _that.submissionType,
            _that.type,
            _that.isCompleted,
            _that.isMissed,
            _that.semesterCode,
            _that.track,
            _that.createdAt);
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
            @JsonKey(name: 'created_at') DateTime? createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Task():
        return $default(
            _that.id,
            _that.userId,
            _that.title,
            _that.courseCode,
            _that.courseName,
            _that.assignDate,
            _that.dueDate,
            _that.submissionType,
            _that.type,
            _that.isCompleted,
            _that.isMissed,
            _that.semesterCode,
            _that.track,
            _that.createdAt);
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
            @JsonKey(name: 'created_at') DateTime? createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Task() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.title,
            _that.courseCode,
            _that.courseName,
            _that.assignDate,
            _that.dueDate,
            _that.submissionType,
            _that.type,
            _that.isCompleted,
            _that.isMissed,
            _that.semesterCode,
            _that.track,
            _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Task implements Task {
  const _Task(
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
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

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

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TaskCopyWith<_Task> get copyWith =>
      __$TaskCopyWithImpl<_Task>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TaskToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Task &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
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
  }

  @override
  String toString() {
    return 'Task(id: $id, userId: $userId, title: $title, courseCode: $courseCode, courseName: $courseName, assignDate: $assignDate, dueDate: $dueDate, submissionType: $submissionType, type: $type, isCompleted: $isCompleted, isMissed: $isMissed, semesterCode: $semesterCode, track: $track, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) =
      __$TaskCopyWithImpl;
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
class __$TaskCopyWithImpl<$Res> implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_Task(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: freezed == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      courseName: freezed == courseName
          ? _self.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String?,
      assignDate: freezed == assignDate
          ? _self.assignDate
          : assignDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDate: freezed == dueDate
          ? _self.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      submissionType: freezed == submissionType
          ? _self.submissionType
          : submissionType // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      isMissed: null == isMissed
          ? _self.isMissed
          : isMissed // ignore: cast_nullable_to_non_nullable
              as bool,
      semesterCode: freezed == semesterCode
          ? _self.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
