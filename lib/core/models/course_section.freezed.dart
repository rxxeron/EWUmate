// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CourseSession _$CourseSessionFromJson(Map<String, dynamic> json) {
  return _CourseSession.fromJson(json);
}

/// @nodoc
mixin _$CourseSession {
  String get type => throw _privateConstructorUsedError;
  String get day => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  String get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time')
  String get endTime => throw _privateConstructorUsedError;
  String get room => throw _privateConstructorUsedError;
  String get faculty => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CourseSessionCopyWith<CourseSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CourseSessionCopyWith<$Res> {
  factory $CourseSessionCopyWith(
          CourseSession value, $Res Function(CourseSession) then) =
      _$CourseSessionCopyWithImpl<$Res, CourseSession>;
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
class _$CourseSessionCopyWithImpl<$Res, $Val extends CourseSession>
    implements $CourseSessionCopyWith<$Res> {
  _$CourseSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      room: null == room
          ? _value.room
          : room // ignore: cast_nullable_to_non_nullable
              as String,
      faculty: null == faculty
          ? _value.faculty
          : faculty // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CourseSessionImplCopyWith<$Res>
    implements $CourseSessionCopyWith<$Res> {
  factory _$$CourseSessionImplCopyWith(
          _$CourseSessionImpl value, $Res Function(_$CourseSessionImpl) then) =
      __$$CourseSessionImplCopyWithImpl<$Res>;
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
class __$$CourseSessionImplCopyWithImpl<$Res>
    extends _$CourseSessionCopyWithImpl<$Res, _$CourseSessionImpl>
    implements _$$CourseSessionImplCopyWith<$Res> {
  __$$CourseSessionImplCopyWithImpl(
      _$CourseSessionImpl _value, $Res Function(_$CourseSessionImpl) _then)
      : super(_value, _then);

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
    return _then(_$CourseSessionImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      room: null == room
          ? _value.room
          : room // ignore: cast_nullable_to_non_nullable
              as String,
      faculty: null == faculty
          ? _value.faculty
          : faculty // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CourseSessionImpl implements _CourseSession {
  const _$CourseSessionImpl(
      {this.type = 'Theory',
      this.day = '',
      @JsonKey(name: 'start_time') this.startTime = '',
      @JsonKey(name: 'end_time') this.endTime = '',
      this.room = '',
      this.faculty = ''});

  factory _$CourseSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CourseSessionImplFromJson(json);

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

  @override
  String toString() {
    return 'CourseSession(type: $type, day: $day, startTime: $startTime, endTime: $endTime, room: $room, faculty: $faculty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CourseSessionImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.room, room) || other.room == room) &&
            (identical(other.faculty, faculty) || other.faculty == faculty));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, day, startTime, endTime, room, faculty);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CourseSessionImplCopyWith<_$CourseSessionImpl> get copyWith =>
      __$$CourseSessionImplCopyWithImpl<_$CourseSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CourseSessionImplToJson(
      this,
    );
  }
}

abstract class _CourseSession implements CourseSession {
  const factory _CourseSession(
      {final String type,
      final String day,
      @JsonKey(name: 'start_time') final String startTime,
      @JsonKey(name: 'end_time') final String endTime,
      final String room,
      final String faculty}) = _$CourseSessionImpl;

  factory _CourseSession.fromJson(Map<String, dynamic> json) =
      _$CourseSessionImpl.fromJson;

  @override
  String get type;
  @override
  String get day;
  @override
  @JsonKey(name: 'start_time')
  String get startTime;
  @override
  @JsonKey(name: 'end_time')
  String get endTime;
  @override
  String get room;
  @override
  String get faculty;
  @override
  @JsonKey(ignore: true)
  _$$CourseSessionImplCopyWith<_$CourseSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CourseSection _$CourseSectionFromJson(Map<String, dynamic> json) {
  return _CourseSection.fromJson(json);
}

/// @nodoc
mixin _$CourseSection {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'course_name')
  String get courseName => throw _privateConstructorUsedError;
  @JsonKey(name: 'faculty_initials')
  String get facultyInitials => throw _privateConstructorUsedError;
  String get section => throw _privateConstructorUsedError;
  String get capacity => throw _privateConstructorUsedError;
  String get credits => throw _privateConstructorUsedError;
  String get semester => throw _privateConstructorUsedError;
  List<CourseSession> get sessions => throw _privateConstructorUsedError;
  @JsonKey(name: 'doc_id')
  String get docId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CourseSectionCopyWith<CourseSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CourseSectionCopyWith<$Res> {
  factory $CourseSectionCopyWith(
          CourseSection value, $Res Function(CourseSection) then) =
      _$CourseSectionCopyWithImpl<$Res, CourseSection>;
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
class _$CourseSectionCopyWithImpl<$Res, $Val extends CourseSection>
    implements $CourseSectionCopyWith<$Res> {
  _$CourseSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      courseName: null == courseName
          ? _value.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String,
      facultyInitials: null == facultyInitials
          ? _value.facultyInitials
          : facultyInitials // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _value.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      capacity: null == capacity
          ? _value.capacity
          : capacity // ignore: cast_nullable_to_non_nullable
              as String,
      credits: null == credits
          ? _value.credits
          : credits // ignore: cast_nullable_to_non_nullable
              as String,
      semester: null == semester
          ? _value.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String,
      sessions: null == sessions
          ? _value.sessions
          : sessions // ignore: cast_nullable_to_non_nullable
              as List<CourseSession>,
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CourseSectionImplCopyWith<$Res>
    implements $CourseSectionCopyWith<$Res> {
  factory _$$CourseSectionImplCopyWith(
          _$CourseSectionImpl value, $Res Function(_$CourseSectionImpl) then) =
      __$$CourseSectionImplCopyWithImpl<$Res>;
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
class __$$CourseSectionImplCopyWithImpl<$Res>
    extends _$CourseSectionCopyWithImpl<$Res, _$CourseSectionImpl>
    implements _$$CourseSectionImplCopyWith<$Res> {
  __$$CourseSectionImplCopyWithImpl(
      _$CourseSectionImpl _value, $Res Function(_$CourseSectionImpl) _then)
      : super(_value, _then);

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
    return _then(_$CourseSectionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      courseName: null == courseName
          ? _value.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String,
      facultyInitials: null == facultyInitials
          ? _value.facultyInitials
          : facultyInitials // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _value.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      capacity: null == capacity
          ? _value.capacity
          : capacity // ignore: cast_nullable_to_non_nullable
              as String,
      credits: null == credits
          ? _value.credits
          : credits // ignore: cast_nullable_to_non_nullable
              as String,
      semester: null == semester
          ? _value.semester
          : semester // ignore: cast_nullable_to_non_nullable
              as String,
      sessions: null == sessions
          ? _value._sessions
          : sessions // ignore: cast_nullable_to_non_nullable
              as List<CourseSession>,
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CourseSectionImpl implements _CourseSection {
  const _$CourseSectionImpl(
      {required this.id,
      this.code = '',
      @JsonKey(name: 'course_name') this.courseName = '',
      @JsonKey(name: 'faculty_initials') this.facultyInitials = '',
      this.section = '',
      this.capacity = '',
      this.credits = '3.0',
      this.semester = '',
      final List<CourseSession> sessions = const [],
      @JsonKey(name: 'doc_id') this.docId = ''})
      : _sessions = sessions;

  factory _$CourseSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CourseSectionImplFromJson(json);

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

  @override
  String toString() {
    return 'CourseSection(id: $id, code: $code, courseName: $courseName, facultyInitials: $facultyInitials, section: $section, capacity: $capacity, credits: $credits, semester: $semester, sessions: $sessions, docId: $docId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CourseSectionImpl &&
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
            const DeepCollectionEquality().equals(other._sessions, _sessions) &&
            (identical(other.docId, docId) || other.docId == docId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
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

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CourseSectionImplCopyWith<_$CourseSectionImpl> get copyWith =>
      __$$CourseSectionImplCopyWithImpl<_$CourseSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CourseSectionImplToJson(
      this,
    );
  }
}

abstract class _CourseSection implements CourseSection {
  const factory _CourseSection(
      {required final String id,
      final String code,
      @JsonKey(name: 'course_name') final String courseName,
      @JsonKey(name: 'faculty_initials') final String facultyInitials,
      final String section,
      final String capacity,
      final String credits,
      final String semester,
      final List<CourseSession> sessions,
      @JsonKey(name: 'doc_id') final String docId}) = _$CourseSectionImpl;

  factory _CourseSection.fromJson(Map<String, dynamic> json) =
      _$CourseSectionImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  @JsonKey(name: 'course_name')
  String get courseName;
  @override
  @JsonKey(name: 'faculty_initials')
  String get facultyInitials;
  @override
  String get section;
  @override
  String get capacity;
  @override
  String get credits;
  @override
  String get semester;
  @override
  List<CourseSession> get sessions;
  @override
  @JsonKey(name: 'doc_id')
  String get docId;
  @override
  @JsonKey(ignore: true)
  _$$CourseSectionImplCopyWith<_$CourseSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
