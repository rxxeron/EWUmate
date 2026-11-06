// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleException {
  String get id;
  @JsonKey(name: 'user_id')
  String get userId;
  String get type;
  DateTime get date;
  @JsonKey(name: 'course_code')
  String? get courseCode;
  @JsonKey(name: 'course_name')
  String? get courseName;
  @JsonKey(name: 'start_time')
  String? get startTime;
  @JsonKey(name: 'end_time')
  String? get endTime;
  String? get room;
  Map<String, dynamic>? get metadata;

  /// Create a copy of ScheduleException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScheduleExceptionCopyWith<ScheduleException> get copyWith =>
      _$ScheduleExceptionCopyWithImpl<ScheduleException>(
          this as ScheduleException, _$identity);

  /// Serializes this ScheduleException to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as ScheduleException;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScheduleException &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.type, _this.type) || other.type == _this.type) &&
            (identical(other.date, _this.date) || other.date == _this.date) &&
            (identical(other.courseCode, _this.courseCode) ||
                other.courseCode == _this.courseCode) &&
            (identical(other.courseName, _this.courseName) ||
                other.courseName == _this.courseName) &&
            (identical(other.startTime, _this.startTime) ||
                other.startTime == _this.startTime) &&
            (identical(other.endTime, _this.endTime) ||
                other.endTime == _this.endTime) &&
            (identical(other.room, _this.room) || other.room == _this.room) &&
            const DeepCollectionEquality()
                .equals(other.metadata, _this.metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as ScheduleException;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.userId,
        _this.type,
        _this.date,
        _this.courseCode,
        _this.courseName,
        _this.startTime,
        _this.endTime,
        _this.room,
        const DeepCollectionEquality().hash(_this.metadata));
  }

  @override
  String toString() {
    final _this = this as ScheduleException;
    return 'ScheduleException(id: ${_this.id}, userId: ${_this.userId}, type: ${_this.type}, date: ${_this.date}, courseCode: ${_this.courseCode}, courseName: ${_this.courseName}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, room: ${_this.room}, metadata: ${_this.metadata})';
  }
}

/// @nodoc
abstract mixin class $ScheduleExceptionCopyWith<$Res> {
  factory $ScheduleExceptionCopyWith(
          ScheduleException value, $Res Function(ScheduleException) _then) =
      _$ScheduleExceptionCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String type,
      DateTime date,
      @JsonKey(name: 'course_code') String? courseCode,
      @JsonKey(name: 'course_name') String? courseName,
      @JsonKey(name: 'start_time') String? startTime,
      @JsonKey(name: 'end_time') String? endTime,
      String? room,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$ScheduleExceptionCopyWithImpl<$Res>
    implements $ScheduleExceptionCopyWith<$Res> {
  _$ScheduleExceptionCopyWithImpl(this._self, this._then);

  final ScheduleException _self;
  final $Res Function(ScheduleException) _then;

  /// Create a copy of ScheduleException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? date = null,
    Object? courseCode = freezed,
    Object? courseName = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? room = freezed,
    Object? metadata = freezed,
  }) {
    return _then(ScheduleException(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      courseCode: freezed == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      courseName: freezed == courseName
          ? _self.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: freezed == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String?,
      room: freezed == room
          ? _self.room
          : room // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ScheduleException].
extension ScheduleExceptionPatterns on ScheduleException {
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
    TResult Function(_ScheduleException value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleException() when $default != null:
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
    TResult Function(_ScheduleException value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleException():
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
    TResult? Function(_ScheduleException value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleException() when $default != null:
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
            String type,
            DateTime date,
            @JsonKey(name: 'course_code') String? courseCode,
            @JsonKey(name: 'course_name') String? courseName,
            @JsonKey(name: 'start_time') String? startTime,
            @JsonKey(name: 'end_time') String? endTime,
            String? room,
            Map<String, dynamic>? metadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleException() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.type,
            _that.date,
            _that.courseCode,
            _that.courseName,
            _that.startTime,
            _that.endTime,
            _that.room,
            _that.metadata);
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
            String type,
            DateTime date,
            @JsonKey(name: 'course_code') String? courseCode,
            @JsonKey(name: 'course_name') String? courseName,
            @JsonKey(name: 'start_time') String? startTime,
            @JsonKey(name: 'end_time') String? endTime,
            String? room,
            Map<String, dynamic>? metadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleException():
        return $default(
            _that.id,
            _that.userId,
            _that.type,
            _that.date,
            _that.courseCode,
            _that.courseName,
            _that.startTime,
            _that.endTime,
            _that.room,
            _that.metadata);
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
            String type,
            DateTime date,
            @JsonKey(name: 'course_code') String? courseCode,
            @JsonKey(name: 'course_name') String? courseName,
            @JsonKey(name: 'start_time') String? startTime,
            @JsonKey(name: 'end_time') String? endTime,
            String? room,
            Map<String, dynamic>? metadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleException() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.type,
            _that.date,
            _that.courseCode,
            _that.courseName,
            _that.startTime,
            _that.endTime,
            _that.room,
            _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ScheduleException implements ScheduleException {
  const _ScheduleException(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      required this.type,
      required this.date,
      @JsonKey(name: 'course_code') this.courseCode,
      @JsonKey(name: 'course_name') this.courseName,
      @JsonKey(name: 'start_time') this.startTime,
      @JsonKey(name: 'end_time') this.endTime,
      this.room,
      Map<String, dynamic>? metadata})
      : _metadata = metadata;
  factory _ScheduleException.fromJson(Map<String, dynamic> json) =>
      _$ScheduleExceptionFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final String type;
  @override
  final DateTime date;
  @override
  @JsonKey(name: 'course_code')
  final String? courseCode;
  @override
  @JsonKey(name: 'course_name')
  final String? courseName;
  @override
  @JsonKey(name: 'start_time')
  final String? startTime;
  @override
  @JsonKey(name: 'end_time')
  final String? endTime;
  @override
  final String? room;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of ScheduleException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScheduleExceptionCopyWith<_ScheduleException> get copyWith =>
      __$ScheduleExceptionCopyWithImpl<_ScheduleException>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ScheduleExceptionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScheduleException &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.courseCode, courseCode) ||
                other.courseCode == courseCode) &&
            (identical(other.courseName, courseName) ||
                other.courseName == courseName) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.room, room) || other.room == room) &&
            const DeepCollectionEquality().equals(other.metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        userId,
        type,
        date,
        courseCode,
        courseName,
        startTime,
        endTime,
        room,
        const DeepCollectionEquality().hash(_metadata));
  }

  @override
  String toString() {
    return 'ScheduleException(id: $id, userId: $userId, type: $type, date: $date, courseCode: $courseCode, courseName: $courseName, startTime: $startTime, endTime: $endTime, room: $room, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class _$ScheduleExceptionCopyWith<$Res>
    implements $ScheduleExceptionCopyWith<$Res> {
  factory _$ScheduleExceptionCopyWith(
          _ScheduleException value, $Res Function(_ScheduleException) _then) =
      __$ScheduleExceptionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String type,
      DateTime date,
      @JsonKey(name: 'course_code') String? courseCode,
      @JsonKey(name: 'course_name') String? courseName,
      @JsonKey(name: 'start_time') String? startTime,
      @JsonKey(name: 'end_time') String? endTime,
      String? room,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$ScheduleExceptionCopyWithImpl<$Res>
    implements _$ScheduleExceptionCopyWith<$Res> {
  __$ScheduleExceptionCopyWithImpl(this._self, this._then);

  final _ScheduleException _self;
  final $Res Function(_ScheduleException) _then;

  /// Create a copy of ScheduleException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? date = null,
    Object? courseCode = freezed,
    Object? courseName = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? room = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_ScheduleException(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      courseCode: freezed == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String?,
      courseName: freezed == courseName
          ? _self.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: freezed == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String?,
      room: freezed == room
          ? _self.room
          : room // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

// dart format on
