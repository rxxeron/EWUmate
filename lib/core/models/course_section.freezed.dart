// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourseSession {
  String get type;
  String get day;
  @JsonKey(name: 'start_time')
  String get startTime;
  @JsonKey(name: 'end_time')
  String get endTime;
  String get room;
  String get faculty;

  /// Create a copy of CourseSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CourseSessionCopyWith<CourseSession> get copyWith =>
      _$CourseSessionCopyWithImpl<CourseSession>(
          this as CourseSession, _$identity);

  /// Serializes this CourseSession to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as CourseSession;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CourseSession &&
            (identical(other.type, _this.type) || other.type == _this.type) &&
            (identical(other.day, _this.day) || other.day == _this.day) &&
            (identical(other.startTime, _this.startTime) ||
                other.startTime == _this.startTime) &&
            (identical(other.endTime, _this.endTime) ||
                other.endTime == _this.endTime) &&
            (identical(other.room, _this.room) || other.room == _this.room) &&
            (identical(other.faculty, _this.faculty) ||
                other.faculty == _this.faculty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as CourseSession;
    return Object.hash(runtimeType, _this.type, _this.day, _this.startTime,
        _this.endTime, _this.room, _this.faculty);
  }

  @override
  String toString() {
    final _this = this as CourseSession;
    return 'CourseSession(type: ${_this.type}, day: ${_this.day}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, room: ${_this.room}, faculty: ${_this.faculty})';
  }
}

/// @nodoc
abstract mixin class $CourseSessionCopyWith<$Res> {
  factory $CourseSessionCopyWith(
          CourseSession value, $Res Function(CourseSession) _then) =
      _$CourseSessionCopyWithImpl;
  @useResult
  $Res call(
      {String type,
      String day,
      @JsonKey(name: 'start_time') String startTime,
      @JsonKey(name: 'end_time') String endTime,
      String room,
      String faculty});
}

/// @nodoc
class _$CourseSessionCopyWithImpl<$Res>
    implements $CourseSessionCopyWith<$Res> {
  _$CourseSessionCopyWithImpl(this._self, this._then);

  final CourseSession _self;
  final $Res Function(CourseSession) _then;

  /// Create a copy of CourseSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? day = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? room = null,
    Object? faculty = null,
  }) {
    return _then(CourseSession(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      day: null == day
          ? _self.day
          : day // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      room: null == room
          ? _self.room
          : room // ignore: cast_nullable_to_non_nullable
              as String,
      faculty: null == faculty
          ? _self.faculty
          : faculty // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [CourseSession].
extension CourseSessionPatterns on CourseSession {
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
    TResult Function(_CourseSession value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CourseSession() when $default != null:
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
    TResult Function(_CourseSession value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseSession():
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
    TResult? Function(_CourseSession value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseSession() when $default != null:
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
            String type,
            String day,
            @JsonKey(name: 'start_time') String startTime,
            @JsonKey(name: 'end_time') String endTime,
            String room,
            String faculty)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CourseSession() when $default != null:
        return $default(_that.type, _that.day, _that.startTime, _that.endTime,
            _that.room, _that.faculty);
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
            String type,
            String day,
            @JsonKey(name: 'start_time') String startTime,
            @JsonKey(name: 'end_time') String endTime,
            String room,
            String faculty)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseSession():
        return $default(_that.type, _that.day, _that.startTime, _that.endTime,
            _that.room, _that.faculty);
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
            String type,
            String day,
            @JsonKey(name: 'start_time') String startTime,
            @JsonKey(name: 'end_time') String endTime,
            String room,
            String faculty)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseSession() when $default != null:
        return $default(_that.type, _that.day, _that.startTime, _that.endTime,
            _that.room, _that.faculty);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CourseSession implements CourseSession {
  const _CourseSession(
      {this.type = 'Theory',
      this.day = '',
      @JsonKey(name: 'start_time') this.startTime = '',
      @JsonKey(name: 'end_time') this.endTime = '',
      this.room = '',
      this.faculty = ''});
  factory _CourseSession.fromJson(Map<String, dynamic> json) =>
      _$CourseSessionFromJson(json);

  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final String day;
  @override
  @JsonKey(name: 'start_time')
  final String startTime;
  @override
  @JsonKey(name: 'end_time')
  final String endTime;
  @override
  @JsonKey()
  final String room;
  @override
  @JsonKey()
  final String faculty;

  /// Create a copy of CourseSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CourseSessionCopyWith<_CourseSession> get copyWith =>
      __$CourseSessionCopyWithImpl<_CourseSession>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CourseSessionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CourseSession &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.room, room) || other.room == room) &&
            (identical(other.faculty, faculty) || other.faculty == faculty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType, type, day, startTime, endTime, room, faculty);
  }

  @override
  String toString() {
    return 'CourseSession(type: $type, day: $day, startTime: $startTime, endTime: $endTime, room: $room, faculty: $faculty)';
  }
}

/// @nodoc
abstract mixin class _$CourseSessionCopyWith<$Res>
    implements $CourseSessionCopyWith<$Res> {
  factory _$CourseSessionCopyWith(
          _CourseSession value, $Res Function(_CourseSession) _then) =
      __$CourseSessionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String type,
      String day,
      @JsonKey(name: 'start_time') String startTime,
      @JsonKey(name: 'end_time') String endTime,
      String room,
      String faculty});
}

/// @nodoc
class __$CourseSessionCopyWithImpl<$Res>
    implements _$CourseSessionCopyWith<$Res> {
  __$CourseSessionCopyWithImpl(this._self, this._then);

  final _CourseSession _self;
  final $Res Function(_CourseSession) _then;

  /// Create a copy of CourseSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? day = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? room = null,
    Object? faculty = null,
  }) {
    return _then(_CourseSession(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      day: null == day
          ? _self.day
          : day // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      room: null == room
          ? _self.room
          : room // ignore: cast_nullable_to_non_nullable
              as String,
      faculty: null == faculty
          ? _self.faculty
          : faculty // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$CourseSection {
  String get id;
  String get code;
  @JsonKey(name: 'course_name')
  String get courseName;
  @JsonKey(name: 'faculty_initials')
  String get facultyInitials;
  String get section;
  String get capacity;
  String get credits;
  String get semester;
  List<CourseSession> get sessions;
  @JsonKey(name: 'doc_id')
  String get docId;

  /// Create a copy of CourseSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CourseSectionCopyWith<CourseSection> get copyWith =>
      _$CourseSectionCopyWithImpl<CourseSection>(
          this as CourseSection, _$identity);

  /// Serializes this CourseSection to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as CourseSection;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CourseSection &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.code, _this.code) || other.code == _this.code) &&
            (identical(other.courseName, _this.courseName) ||
                other.courseName == _this.courseName) &&
            (identical(other.facultyInitials, _this.facultyInitials) ||
                other.facultyInitials == _this.facultyInitials) &&
            (identical(other.section, _this.section) ||
                other.section == _this.section) &&
            (identical(other.capacity, _this.capacity) ||
                other.capacity == _this.capacity) &&
            (identical(other.credits, _this.credits) ||
                other.credits == _this.credits) &&
            (identical(other.semester, _this.semester) ||
                other.semester == _this.semester) &&
            const DeepCollectionEquality()
                .equals(other.sessions, _this.sessions) &&
            (identical(other.docId, _this.docId) ||
                other.docId == _this.docId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as CourseSection;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.code,
        _this.courseName,
        _this.facultyInitials,
        _this.section,
        _this.capacity,
        _this.credits,
        _this.semester,
        const DeepCollectionEquality().hash(_this.sessions),
        _this.docId);
  }

  @override
  String toString() {
    final _this = this as CourseSection;
    return 'CourseSection(id: ${_this.id}, code: ${_this.code}, courseName: ${_this.courseName}, facultyInitials: ${_this.facultyInitials}, section: ${_this.section}, capacity: ${_this.capacity}, credits: ${_this.credits}, semester: ${_this.semester}, sessions: ${_this.sessions}, docId: ${_this.docId})';
  }
}

/// @nodoc
abstract mixin class $CourseSectionCopyWith<$Res> {
  factory $CourseSectionCopyWith(
          CourseSection value, $Res Function(CourseSection) _then) =
      _$CourseSectionCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String code,
      @JsonKey(name: 'course_name') String courseName,
      @JsonKey(name: 'faculty_initials') String facultyInitials,
      String section,
      String capacity,
      String credits,
      String semester,
      List<CourseSession> sessions,
      @JsonKey(name: 'doc_id') String docId});
}

/// @nodoc
class _$CourseSectionCopyWithImpl<$Res>
    implements $CourseSectionCopyWith<$Res> {
  _$CourseSectionCopyWithImpl(this._self, this._then);

  final CourseSection _self;
  final $Res Function(CourseSection) _then;

  /// Create a copy of CourseSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? courseName = null,
    Object? facultyInitials = null,
    Object? section = null,
    Object? capacity = null,
    Object? credits = null,
    Object? semester = null,
    Object? sessions = null,
    Object? docId = null,
  }) {
    return _then(CourseSection(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      courseName: null == courseName
          ? _self.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String,
      facultyInitials: null == facultyInitials
          ? _self.facultyInitials
          : facultyInitials // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      capacity: null == capacity
          ? _self.capacity
          : capacity // ignore: cast_nullable_to_non_nullable
              as String,
      credits: null == credits
          ? _self.credits
          : credits // ignore: cast_nullable_to_non_nullable
              as String,
      semester: null == semester
          ? _self.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String,
      sessions: null == sessions
          ? _self.sessions
          : sessions // ignore: cast_nullable_to_non_nullable
              as List<CourseSession>,
      docId: null == docId
          ? _self.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [CourseSection].
extension CourseSectionPatterns on CourseSection {
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
    TResult Function(_CourseSection value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CourseSection() when $default != null:
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
    TResult Function(_CourseSection value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseSection():
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
    TResult? Function(_CourseSection value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseSection() when $default != null:
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
            String code,
            @JsonKey(name: 'course_name') String courseName,
            @JsonKey(name: 'faculty_initials') String facultyInitials,
            String section,
            String capacity,
            String credits,
            String semester,
            List<CourseSession> sessions,
            @JsonKey(name: 'doc_id') String docId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CourseSection() when $default != null:
        return $default(
            _that.id,
            _that.code,
            _that.courseName,
            _that.facultyInitials,
            _that.section,
            _that.capacity,
            _that.credits,
            _that.semester,
            _that.sessions,
            _that.docId);
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
            String code,
            @JsonKey(name: 'course_name') String courseName,
            @JsonKey(name: 'faculty_initials') String facultyInitials,
            String section,
            String capacity,
            String credits,
            String semester,
            List<CourseSession> sessions,
            @JsonKey(name: 'doc_id') String docId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseSection():
        return $default(
            _that.id,
            _that.code,
            _that.courseName,
            _that.facultyInitials,
            _that.section,
            _that.capacity,
            _that.credits,
            _that.semester,
            _that.sessions,
            _that.docId);
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
            String code,
            @JsonKey(name: 'course_name') String courseName,
            @JsonKey(name: 'faculty_initials') String facultyInitials,
            String section,
            String capacity,
            String credits,
            String semester,
            List<CourseSession> sessions,
            @JsonKey(name: 'doc_id') String docId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CourseSection() when $default != null:
        return $default(
            _that.id,
            _that.code,
            _that.courseName,
            _that.facultyInitials,
            _that.section,
            _that.capacity,
            _that.credits,
            _that.semester,
            _that.sessions,
            _that.docId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CourseSection implements CourseSection {
  const _CourseSection(
      {required this.id,
      this.code = '',
      @JsonKey(name: 'course_name') this.courseName = '',
      @JsonKey(name: 'faculty_initials') this.facultyInitials = '',
      this.section = '',
      this.capacity = '',
      this.credits = '3.0',
      this.semester = '',
      List<CourseSession> sessions = const [],
      @JsonKey(name: 'doc_id') this.docId = ''})
      : _sessions = sessions;
  factory _CourseSection.fromJson(Map<String, dynamic> json) =>
      _$CourseSectionFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String code;
  @override
  @JsonKey(name: 'course_name')
  final String courseName;
  @override
  @JsonKey(name: 'faculty_initials')
  final String facultyInitials;
  @override
  @JsonKey()
  final String section;
  @override
  @JsonKey()
  final String capacity;
  @override
  @JsonKey()
  final String credits;
  @override
  @JsonKey()
  final String semester;
  final List<CourseSession> _sessions;
  @override
  @JsonKey()
  List<CourseSession> get sessions {
    if (_sessions is EqualUnmodifiableListView) return _sessions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sessions);
  }

  @override
  @JsonKey(name: 'doc_id')
  final String docId;

  /// Create a copy of CourseSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CourseSectionCopyWith<_CourseSection> get copyWith =>
      __$CourseSectionCopyWithImpl<_CourseSection>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CourseSectionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CourseSection &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.courseName, courseName) ||
                other.courseName == courseName) &&
            (identical(other.facultyInitials, facultyInitials) ||
                other.facultyInitials == facultyInitials) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.credits, credits) || other.credits == credits) &&
            (identical(other.semester, semester) ||
                other.semester == semester) &&
            const DeepCollectionEquality().equals(other.sessions, _sessions) &&
            (identical(other.docId, docId) || other.docId == docId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        code,
        courseName,
        facultyInitials,
        section,
        capacity,
        credits,
        semester,
        const DeepCollectionEquality().hash(_sessions),
        docId);
  }

  @override
  String toString() {
    return 'CourseSection(id: $id, code: $code, courseName: $courseName, facultyInitials: $facultyInitials, section: $section, capacity: $capacity, credits: $credits, semester: $semester, sessions: $sessions, docId: $docId)';
  }
}

/// @nodoc
abstract mixin class _$CourseSectionCopyWith<$Res>
    implements $CourseSectionCopyWith<$Res> {
  factory _$CourseSectionCopyWith(
          _CourseSection value, $Res Function(_CourseSection) _then) =
      __$CourseSectionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      @JsonKey(name: 'course_name') String courseName,
      @JsonKey(name: 'faculty_initials') String facultyInitials,
      String section,
      String capacity,
      String credits,
      String semester,
      List<CourseSession> sessions,
      @JsonKey(name: 'doc_id') String docId});
}

/// @nodoc
class __$CourseSectionCopyWithImpl<$Res>
    implements _$CourseSectionCopyWith<$Res> {
  __$CourseSectionCopyWithImpl(this._self, this._then);

  final _CourseSection _self;
  final $Res Function(_CourseSection) _then;

  /// Create a copy of CourseSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? courseName = null,
    Object? facultyInitials = null,
    Object? section = null,
    Object? capacity = null,
    Object? credits = null,
    Object? semester = null,
    Object? sessions = null,
    Object? docId = null,
  }) {
    return _then(_CourseSection(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      courseName: null == courseName
          ? _self.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String,
      facultyInitials: null == facultyInitials
          ? _self.facultyInitials
          : facultyInitials // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      capacity: null == capacity
          ? _self.capacity
          : capacity // ignore: cast_nullable_to_non_nullable
              as String,
      credits: null == credits
          ? _self.credits
          : credits // ignore: cast_nullable_to_non_nullable
              as String,
      semester: null == semester
          ? _self.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String,
      sessions: null == sessions
          ? _self._sessions
          : sessions // ignore: cast_nullable_to_non_nullable
              as List<CourseSession>,
      docId: null == docId
          ? _self.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
