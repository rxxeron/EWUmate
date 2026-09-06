// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _Profile.fromJson(json);
}

/// @nodoc
mixin _$Profile {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'student_id')
  String? get studentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'full_name')
  String? get fullName => throw _privateConstructorUsedError;
  String? get nickname => throw _privateConstructorUsedError;
  @JsonKey(name: 'program_code')
  String? get programCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'admitted_semester')
  String? get admittedSemester => throw _privateConstructorUsedError;
  double? get cgpa => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_credits_earned')
  double? get totalCreditsEarned => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'onboarding_status')
  String get onboardingStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'semester_type')
  String get semesterType => throw _privateConstructorUsedError;
  @JsonKey(name: 'department_name')
  String? get departmentName => throw _privateConstructorUsedError;
  @JsonKey(name: 'scholarship_status')
  String? get scholarshipStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'program_name')
  String? get programName => throw _privateConstructorUsedError;
  String? get track => throw _privateConstructorUsedError;
  @JsonKey(name: 'enrolled_sections')
  List<String> get enrolledSections => throw _privateConstructorUsedError;
  @JsonKey(name: 'enrolled_sections_next')
  List<String> get enrolledSectionsNext => throw _privateConstructorUsedError;
  @JsonKey(name: 'enrolled_credits')
  double get enrolledCredits => throw _privateConstructorUsedError;
  @JsonKey(name: 'enrolled_credits_next')
  double get enrolledCreditsNext => throw _privateConstructorUsedError;
  @JsonKey(name: 'past_history')
  List<dynamic> get pastHistory => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_courses_completed')
  int get totalCoursesCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_active_at')
  DateTime? get lastActiveAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'app_open_count')
  int get appOpenCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'app_version')
  String? get appVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'reminder_settings')
  Map<String, dynamic> get reminderSettings =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'student_id') String? studentId,
      @JsonKey(name: 'full_name') String? fullName,
      String? nickname,
      @JsonKey(name: 'program_code') String? programCode,
      @JsonKey(name: 'admitted_semester') String? admittedSemester,
      double? cgpa,
      @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'onboarding_status') String onboardingStatus,
      @JsonKey(name: 'semester_type') String semesterType,
      @JsonKey(name: 'department_name') String? departmentName,
      @JsonKey(name: 'scholarship_status') String? scholarshipStatus,
      @JsonKey(name: 'program_name') String? programName,
      String? track,
      @JsonKey(name: 'enrolled_sections') List<String> enrolledSections,
      @JsonKey(name: 'enrolled_sections_next')
      List<String> enrolledSectionsNext,
      @JsonKey(name: 'enrolled_credits') double enrolledCredits,
      @JsonKey(name: 'enrolled_credits_next') double enrolledCreditsNext,
      @JsonKey(name: 'past_history') List<dynamic> pastHistory,
      @JsonKey(name: 'total_courses_completed') int totalCoursesCompleted,
      @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
      @JsonKey(name: 'app_open_count') int appOpenCount,
      @JsonKey(name: 'app_version') String? appVersion,
      @JsonKey(name: 'reminder_settings') Map<String, dynamic> reminderSettings,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? studentId = freezed,
    Object? fullName = freezed,
    Object? nickname = freezed,
    Object? programCode = freezed,
    Object? admittedSemester = freezed,
    Object? cgpa = freezed,
    Object? totalCreditsEarned = freezed,
    Object? photoUrl = freezed,
    Object? onboardingStatus = null,
    Object? semesterType = null,
    Object? departmentName = freezed,
    Object? scholarshipStatus = freezed,
    Object? programName = freezed,
    Object? track = freezed,
    Object? enrolledSections = null,
    Object? enrolledSectionsNext = null,
    Object? enrolledCredits = null,
    Object? enrolledCreditsNext = null,
    Object? pastHistory = null,
    Object? totalCoursesCompleted = null,
    Object? lastActiveAt = freezed,
    Object? appOpenCount = null,
    Object? appVersion = freezed,
    Object? reminderSettings = null,
    Object? updatedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: freezed == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      programCode: freezed == programCode
          ? _value.programCode
          : programCode // ignore: cast_nullable_to_non_nullable
              as String?,
      admittedSemester: freezed == admittedSemester
          ? _value.admittedSemester
          : admittedSemester // ignore: cast_nullable_to_non_nullable
              as String?,
      cgpa: freezed == cgpa
          ? _value.cgpa
          : cgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCreditsEarned: freezed == totalCreditsEarned
          ? _value.totalCreditsEarned
          : totalCreditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      onboardingStatus: null == onboardingStatus
          ? _value.onboardingStatus
          : onboardingStatus // ignore: cast_nullable_to_non_nullable
              as String,
      semesterType: null == semesterType
          ? _value.semesterType
          : semesterType // ignore: cast_nullable_to_non_nullable
              as String,
      departmentName: freezed == departmentName
          ? _value.departmentName
          : departmentName // ignore: cast_nullable_to_non_nullable
              as String?,
      scholarshipStatus: freezed == scholarshipStatus
          ? _value.scholarshipStatus
          : scholarshipStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      programName: freezed == programName
          ? _value.programName
          : programName // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _value.track
          : track // ignore: cast_nullable_to_non_nullable
              as String?,
      enrolledSections: null == enrolledSections
          ? _value.enrolledSections
          : enrolledSections // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enrolledSectionsNext: null == enrolledSectionsNext
          ? _value.enrolledSectionsNext
          : enrolledSectionsNext // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enrolledCredits: null == enrolledCredits
          ? _value.enrolledCredits
          : enrolledCredits // ignore: cast_nullable_to_non_nullable
              as double,
      enrolledCreditsNext: null == enrolledCreditsNext
          ? _value.enrolledCreditsNext
          : enrolledCreditsNext // ignore: cast_nullable_to_non_nullable
              as double,
      pastHistory: null == pastHistory
          ? _value.pastHistory
          : pastHistory // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      totalCoursesCompleted: null == totalCoursesCompleted
          ? _value.totalCoursesCompleted
          : totalCoursesCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      appOpenCount: null == appOpenCount
          ? _value.appOpenCount
          : appOpenCount // ignore: cast_nullable_to_non_nullable
              as int,
      appVersion: freezed == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      reminderSettings: null == reminderSettings
          ? _value.reminderSettings
          : reminderSettings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
          _$ProfileImpl value, $Res Function(_$ProfileImpl) then) =
      __$$ProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'student_id') String? studentId,
      @JsonKey(name: 'full_name') String? fullName,
      String? nickname,
      @JsonKey(name: 'program_code') String? programCode,
      @JsonKey(name: 'admitted_semester') String? admittedSemester,
      double? cgpa,
      @JsonKey(name: 'total_credits_earned') double? totalCreditsEarned,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'onboarding_status') String onboardingStatus,
      @JsonKey(name: 'semester_type') String semesterType,
      @JsonKey(name: 'department_name') String? departmentName,
      @JsonKey(name: 'scholarship_status') String? scholarshipStatus,
      @JsonKey(name: 'program_name') String? programName,
      String? track,
      @JsonKey(name: 'enrolled_sections') List<String> enrolledSections,
      @JsonKey(name: 'enrolled_sections_next')
      List<String> enrolledSectionsNext,
      @JsonKey(name: 'enrolled_credits') double enrolledCredits,
      @JsonKey(name: 'enrolled_credits_next') double enrolledCreditsNext,
      @JsonKey(name: 'past_history') List<dynamic> pastHistory,
      @JsonKey(name: 'total_courses_completed') int totalCoursesCompleted,
      @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
      @JsonKey(name: 'app_open_count') int appOpenCount,
      @JsonKey(name: 'app_version') String? appVersion,
      @JsonKey(name: 'reminder_settings') Map<String, dynamic> reminderSettings,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
      _$ProfileImpl _value, $Res Function(_$ProfileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? studentId = freezed,
    Object? fullName = freezed,
    Object? nickname = freezed,
    Object? programCode = freezed,
    Object? admittedSemester = freezed,
    Object? cgpa = freezed,
    Object? totalCreditsEarned = freezed,
    Object? photoUrl = freezed,
    Object? onboardingStatus = null,
    Object? semesterType = null,
    Object? departmentName = freezed,
    Object? scholarshipStatus = freezed,
    Object? programName = freezed,
    Object? track = freezed,
    Object? enrolledSections = null,
    Object? enrolledSectionsNext = null,
    Object? enrolledCredits = null,
    Object? enrolledCreditsNext = null,
    Object? pastHistory = null,
    Object? totalCoursesCompleted = null,
    Object? lastActiveAt = freezed,
    Object? appOpenCount = null,
    Object? appVersion = freezed,
    Object? reminderSettings = null,
    Object? updatedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: freezed == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      programCode: freezed == programCode
          ? _value.programCode
          : programCode // ignore: cast_nullable_to_non_nullable
              as String?,
      admittedSemester: freezed == admittedSemester
          ? _value.admittedSemester
          : admittedSemester // ignore: cast_nullable_to_non_nullable
              as String?,
      cgpa: freezed == cgpa
          ? _value.cgpa
          : cgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCreditsEarned: freezed == totalCreditsEarned
          ? _value.totalCreditsEarned
          : totalCreditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      onboardingStatus: null == onboardingStatus
          ? _value.onboardingStatus
          : onboardingStatus // ignore: cast_nullable_to_non_nullable
              as String,
      semesterType: null == semesterType
          ? _value.semesterType
          : semesterType // ignore: cast_nullable_to_non_nullable
              as String,
      departmentName: freezed == departmentName
          ? _value.departmentName
          : departmentName // ignore: cast_nullable_to_non_nullable
              as String?,
      scholarshipStatus: freezed == scholarshipStatus
          ? _value.scholarshipStatus
          : scholarshipStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      programName: freezed == programName
          ? _value.programName
          : programName // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _value.track
          : track // ignore: cast_nullable_to_non_nullable
              as String?,
      enrolledSections: null == enrolledSections
          ? _value._enrolledSections
          : enrolledSections // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enrolledSectionsNext: null == enrolledSectionsNext
          ? _value._enrolledSectionsNext
          : enrolledSectionsNext // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enrolledCredits: null == enrolledCredits
          ? _value.enrolledCredits
          : enrolledCredits // ignore: cast_nullable_to_non_nullable
              as double,
      enrolledCreditsNext: null == enrolledCreditsNext
          ? _value.enrolledCreditsNext
          : enrolledCreditsNext // ignore: cast_nullable_to_non_nullable
              as double,
      pastHistory: null == pastHistory
          ? _value._pastHistory
          : pastHistory // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      totalCoursesCompleted: null == totalCoursesCompleted
          ? _value.totalCoursesCompleted
          : totalCoursesCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      appOpenCount: null == appOpenCount
          ? _value.appOpenCount
          : appOpenCount // ignore: cast_nullable_to_non_nullable
              as int,
      appVersion: freezed == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      reminderSettings: null == reminderSettings
          ? _value._reminderSettings
          : reminderSettings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileImpl implements _Profile {
  const _$ProfileImpl(
      {required this.id,
      @JsonKey(name: 'student_id') this.studentId,
      @JsonKey(name: 'full_name') this.fullName,
      this.nickname,
      @JsonKey(name: 'program_code') this.programCode,
      @JsonKey(name: 'admitted_semester') this.admittedSemester,
      this.cgpa,
      @JsonKey(name: 'total_credits_earned') this.totalCreditsEarned,
      @JsonKey(name: 'photo_url') this.photoUrl,
      @JsonKey(name: 'onboarding_status') this.onboardingStatus = 'pending',
      @JsonKey(name: 'semester_type') this.semesterType = 'tri',
      @JsonKey(name: 'department_name') this.departmentName,
      @JsonKey(name: 'scholarship_status') this.scholarshipStatus,
      @JsonKey(name: 'program_name') this.programName,
      this.track,
      @JsonKey(name: 'enrolled_sections')
      final List<String> enrolledSections = const [],
      @JsonKey(name: 'enrolled_sections_next')
      final List<String> enrolledSectionsNext = const [],
      @JsonKey(name: 'enrolled_credits') this.enrolledCredits = 0.0,
      @JsonKey(name: 'enrolled_credits_next') this.enrolledCreditsNext = 0.0,
      @JsonKey(name: 'past_history') final List<dynamic> pastHistory = const [],
      @JsonKey(name: 'total_courses_completed') this.totalCoursesCompleted = 0,
      @JsonKey(name: 'last_active_at') this.lastActiveAt,
      @JsonKey(name: 'app_open_count') this.appOpenCount = 0,
      @JsonKey(name: 'app_version') this.appVersion,
      @JsonKey(name: 'reminder_settings')
      final Map<String, dynamic> reminderSettings = const {},
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'created_at') this.createdAt})
      : _enrolledSections = enrolledSections,
        _enrolledSectionsNext = enrolledSectionsNext,
        _pastHistory = pastHistory,
        _reminderSettings = reminderSettings;

  factory _$ProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'student_id')
  final String? studentId;
  @override
  @JsonKey(name: 'full_name')
  final String? fullName;
  @override
  final String? nickname;
  @override
  @JsonKey(name: 'program_code')
  final String? programCode;
  @override
  @JsonKey(name: 'admitted_semester')
  final String? admittedSemester;
  @override
  final double? cgpa;
  @override
  @JsonKey(name: 'total_credits_earned')
  final double? totalCreditsEarned;
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @override
  @JsonKey(name: 'onboarding_status')
  final String onboardingStatus;
  @override
  @JsonKey(name: 'semester_type')
  final String semesterType;
  @override
  @JsonKey(name: 'department_name')
  final String? departmentName;
  @override
  @JsonKey(name: 'scholarship_status')
  final String? scholarshipStatus;
  @override
  @JsonKey(name: 'program_name')
  final String? programName;
  @override
  final String? track;
  final List<String> _enrolledSections;
  @override
  @JsonKey(name: 'enrolled_sections')
  List<String> get enrolledSections {
    if (_enrolledSections is EqualUnmodifiableListView)
      return _enrolledSections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_enrolledSections);
  }

  final List<String> _enrolledSectionsNext;
  @override
  @JsonKey(name: 'enrolled_sections_next')
  List<String> get enrolledSectionsNext {
    if (_enrolledSectionsNext is EqualUnmodifiableListView)
      return _enrolledSectionsNext;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_enrolledSectionsNext);
  }

  @override
  @JsonKey(name: 'enrolled_credits')
  final double enrolledCredits;
  @override
  @JsonKey(name: 'enrolled_credits_next')
  final double enrolledCreditsNext;
  final List<dynamic> _pastHistory;
  @override
  @JsonKey(name: 'past_history')
  List<dynamic> get pastHistory {
    if (_pastHistory is EqualUnmodifiableListView) return _pastHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pastHistory);
  }

  @override
  @JsonKey(name: 'total_courses_completed')
  final int totalCoursesCompleted;
  @override
  @JsonKey(name: 'last_active_at')
  final DateTime? lastActiveAt;
  @override
  @JsonKey(name: 'app_open_count')
  final int appOpenCount;
  @override
  @JsonKey(name: 'app_version')
  final String? appVersion;
  final Map<String, dynamic> _reminderSettings;
  @override
  @JsonKey(name: 'reminder_settings')
  Map<String, dynamic> get reminderSettings {
    if (_reminderSettings is EqualUnmodifiableMapView) return _reminderSettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_reminderSettings);
  }

  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Profile(id: $id, studentId: $studentId, fullName: $fullName, nickname: $nickname, programCode: $programCode, admittedSemester: $admittedSemester, cgpa: $cgpa, totalCreditsEarned: $totalCreditsEarned, photoUrl: $photoUrl, onboardingStatus: $onboardingStatus, semesterType: $semesterType, departmentName: $departmentName, scholarshipStatus: $scholarshipStatus, programName: $programName, track: $track, enrolledSections: $enrolledSections, enrolledSectionsNext: $enrolledSectionsNext, enrolledCredits: $enrolledCredits, enrolledCreditsNext: $enrolledCreditsNext, pastHistory: $pastHistory, totalCoursesCompleted: $totalCoursesCompleted, lastActiveAt: $lastActiveAt, appOpenCount: $appOpenCount, appVersion: $appVersion, reminderSettings: $reminderSettings, updatedAt: $updatedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.programCode, programCode) ||
                other.programCode == programCode) &&
            (identical(other.admittedSemester, admittedSemester) ||
                other.admittedSemester == admittedSemester) &&
            (identical(other.cgpa, cgpa) || other.cgpa == cgpa) &&
            (identical(other.totalCreditsEarned, totalCreditsEarned) ||
                other.totalCreditsEarned == totalCreditsEarned) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.onboardingStatus, onboardingStatus) ||
                other.onboardingStatus == onboardingStatus) &&
            (identical(other.semesterType, semesterType) ||
                other.semesterType == semesterType) &&
            (identical(other.departmentName, departmentName) ||
                other.departmentName == departmentName) &&
            (identical(other.scholarshipStatus, scholarshipStatus) ||
                other.scholarshipStatus == scholarshipStatus) &&
            (identical(other.programName, programName) ||
                other.programName == programName) &&
            (identical(other.track, track) || other.track == track) &&
            const DeepCollectionEquality()
                .equals(other._enrolledSections, _enrolledSections) &&
            const DeepCollectionEquality()
                .equals(other._enrolledSectionsNext, _enrolledSectionsNext) &&
            (identical(other.enrolledCredits, enrolledCredits) ||
                other.enrolledCredits == enrolledCredits) &&
            (identical(other.enrolledCreditsNext, enrolledCreditsNext) ||
                other.enrolledCreditsNext == enrolledCreditsNext) &&
            const DeepCollectionEquality()
                .equals(other._pastHistory, _pastHistory) &&
            (identical(other.totalCoursesCompleted, totalCoursesCompleted) ||
                other.totalCoursesCompleted == totalCoursesCompleted) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.appOpenCount, appOpenCount) ||
                other.appOpenCount == appOpenCount) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            const DeepCollectionEquality()
                .equals(other._reminderSettings, _reminderSettings) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        studentId,
        fullName,
        nickname,
        programCode,
        admittedSemester,
        cgpa,
        totalCreditsEarned,
        photoUrl,
        onboardingStatus,
        semesterType,
        departmentName,
        scholarshipStatus,
        programName,
        track,
        const DeepCollectionEquality().hash(_enrolledSections),
        const DeepCollectionEquality().hash(_enrolledSectionsNext),
        enrolledCredits,
        enrolledCreditsNext,
        const DeepCollectionEquality().hash(_pastHistory),
        totalCoursesCompleted,
        lastActiveAt,
        appOpenCount,
        appVersion,
        const DeepCollectionEquality().hash(_reminderSettings),
        updatedAt,
        createdAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileImplToJson(
      this,
    );
  }
}

abstract class _Profile implements Profile {
  const factory _Profile(
      {required final String id,
      @JsonKey(name: 'student_id') final String? studentId,
      @JsonKey(name: 'full_name') final String? fullName,
      final String? nickname,
      @JsonKey(name: 'program_code') final String? programCode,
      @JsonKey(name: 'admitted_semester') final String? admittedSemester,
      final double? cgpa,
      @JsonKey(name: 'total_credits_earned') final double? totalCreditsEarned,
      @JsonKey(name: 'photo_url') final String? photoUrl,
      @JsonKey(name: 'onboarding_status') final String onboardingStatus,
      @JsonKey(name: 'semester_type') final String semesterType,
      @JsonKey(name: 'department_name') final String? departmentName,
      @JsonKey(name: 'scholarship_status') final String? scholarshipStatus,
      @JsonKey(name: 'program_name') final String? programName,
      final String? track,
      @JsonKey(name: 'enrolled_sections') final List<String> enrolledSections,
      @JsonKey(name: 'enrolled_sections_next')
      final List<String> enrolledSectionsNext,
      @JsonKey(name: 'enrolled_credits') final double enrolledCredits,
      @JsonKey(name: 'enrolled_credits_next') final double enrolledCreditsNext,
      @JsonKey(name: 'past_history') final List<dynamic> pastHistory,
      @JsonKey(name: 'total_courses_completed') final int totalCoursesCompleted,
      @JsonKey(name: 'last_active_at') final DateTime? lastActiveAt,
      @JsonKey(name: 'app_open_count') final int appOpenCount,
      @JsonKey(name: 'app_version') final String? appVersion,
      @JsonKey(name: 'reminder_settings')
      final Map<String, dynamic> reminderSettings,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt,
      @JsonKey(name: 'created_at') final DateTime? createdAt}) = _$ProfileImpl;

  factory _Profile.fromJson(Map<String, dynamic> json) = _$ProfileImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'student_id')
  String? get studentId;
  @override
  @JsonKey(name: 'full_name')
  String? get fullName;
  @override
  String? get nickname;
  @override
  @JsonKey(name: 'program_code')
  String? get programCode;
  @override
  @JsonKey(name: 'admitted_semester')
  String? get admittedSemester;
  @override
  double? get cgpa;
  @override
  @JsonKey(name: 'total_credits_earned')
  double? get totalCreditsEarned;
  @override
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  @override
  @JsonKey(name: 'onboarding_status')
  String get onboardingStatus;
  @override
  @JsonKey(name: 'semester_type')
  String get semesterType;
  @override
  @JsonKey(name: 'department_name')
  String? get departmentName;
  @override
  @JsonKey(name: 'scholarship_status')
  String? get scholarshipStatus;
  @override
  @JsonKey(name: 'program_name')
  String? get programName;
  @override
  String? get track;
  @override
  @JsonKey(name: 'enrolled_sections')
  List<String> get enrolledSections;
  @override
  @JsonKey(name: 'enrolled_sections_next')
  List<String> get enrolledSectionsNext;
  @override
  @JsonKey(name: 'enrolled_credits')
  double get enrolledCredits;
  @override
  @JsonKey(name: 'enrolled_credits_next')
  double get enrolledCreditsNext;
  @override
  @JsonKey(name: 'past_history')
  List<dynamic> get pastHistory;
  @override
  @JsonKey(name: 'total_courses_completed')
  int get totalCoursesCompleted;
  @override
  @JsonKey(name: 'last_active_at')
  DateTime? get lastActiveAt;
  @override
  @JsonKey(name: 'app_open_count')
  int get appOpenCount;
  @override
  @JsonKey(name: 'app_version')
  String? get appVersion;
  @override
  @JsonKey(name: 'reminder_settings')
  Map<String, dynamic> get reminderSettings;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
