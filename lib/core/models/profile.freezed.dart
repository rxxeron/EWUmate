// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profile {
  String get id;
  @JsonKey(name: 'student_id')
  String? get studentId;
  @JsonKey(name: 'full_name')
  String? get fullName;
  String? get nickname;
  @JsonKey(name: 'program_code')
  String? get programCode;
  @JsonKey(name: 'admitted_semester')
  String? get admittedSemester;
  double? get cgpa;
  @JsonKey(name: 'total_credits_earned')
  double? get totalCreditsEarned;
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  @JsonKey(name: 'onboarding_status')
  String get onboardingStatus;
  @JsonKey(name: 'semester_type')
  String get semesterType;
  @JsonKey(name: 'department_name')
  String? get departmentName;
  @JsonKey(name: 'scholarship_status')
  String? get scholarshipStatus;
  @JsonKey(name: 'program_name')
  String? get programName;
  String? get track;
  @JsonKey(name: 'enrolled_sections')
  List<String> get enrolledSections;
  @JsonKey(name: 'enrolled_sections_next')
  List<String> get enrolledSectionsNext;
  @JsonKey(name: 'enrolled_credits')
  double get enrolledCredits;
  @JsonKey(name: 'enrolled_credits_next')
  double get enrolledCreditsNext;
  @JsonKey(name: 'past_history')
  List<dynamic> get pastHistory;
  @JsonKey(name: 'total_courses_completed')
  int get totalCoursesCompleted;
  @JsonKey(name: 'last_active_at')
  DateTime? get lastActiveAt;
  @JsonKey(name: 'app_open_count')
  int get appOpenCount;
  @JsonKey(name: 'app_version')
  String? get appVersion;
  @JsonKey(name: 'reminder_settings')
  Map<String, dynamic> get reminderSettings;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProfileCopyWith<Profile> get copyWith =>
      _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Profile;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Profile &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.studentId, _this.studentId) ||
                other.studentId == _this.studentId) &&
            (identical(other.fullName, _this.fullName) ||
                other.fullName == _this.fullName) &&
            (identical(other.nickname, _this.nickname) ||
                other.nickname == _this.nickname) &&
            (identical(other.programCode, _this.programCode) ||
                other.programCode == _this.programCode) &&
            (identical(other.admittedSemester, _this.admittedSemester) ||
                other.admittedSemester == _this.admittedSemester) &&
            (identical(other.cgpa, _this.cgpa) || other.cgpa == _this.cgpa) &&
            (identical(other.totalCreditsEarned, _this.totalCreditsEarned) ||
                other.totalCreditsEarned == _this.totalCreditsEarned) &&
            (identical(other.photoUrl, _this.photoUrl) ||
                other.photoUrl == _this.photoUrl) &&
            (identical(other.onboardingStatus, _this.onboardingStatus) ||
                other.onboardingStatus == _this.onboardingStatus) &&
            (identical(other.semesterType, _this.semesterType) ||
                other.semesterType == _this.semesterType) &&
            (identical(other.departmentName, _this.departmentName) ||
                other.departmentName == _this.departmentName) &&
            (identical(other.scholarshipStatus, _this.scholarshipStatus) ||
                other.scholarshipStatus == _this.scholarshipStatus) &&
            (identical(other.programName, _this.programName) ||
                other.programName == _this.programName) &&
            (identical(other.track, _this.track) ||
                other.track == _this.track) &&
            const DeepCollectionEquality()
                .equals(other.enrolledSections, _this.enrolledSections) &&
            const DeepCollectionEquality().equals(
                other.enrolledSectionsNext, _this.enrolledSectionsNext) &&
            (identical(other.enrolledCredits, _this.enrolledCredits) ||
                other.enrolledCredits == _this.enrolledCredits) &&
            (identical(other.enrolledCreditsNext, _this.enrolledCreditsNext) ||
                other.enrolledCreditsNext == _this.enrolledCreditsNext) &&
            const DeepCollectionEquality()
                .equals(other.pastHistory, _this.pastHistory) &&
            (identical(
                    other.totalCoursesCompleted, _this.totalCoursesCompleted) ||
                other.totalCoursesCompleted == _this.totalCoursesCompleted) &&
            (identical(other.lastActiveAt, _this.lastActiveAt) ||
                other.lastActiveAt == _this.lastActiveAt) &&
            (identical(other.appOpenCount, _this.appOpenCount) ||
                other.appOpenCount == _this.appOpenCount) &&
            (identical(other.appVersion, _this.appVersion) ||
                other.appVersion == _this.appVersion) &&
            const DeepCollectionEquality()
                .equals(other.reminderSettings, _this.reminderSettings) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Profile;
    return Object.hashAll([
      runtimeType,
      _this.id,
      _this.studentId,
      _this.fullName,
      _this.nickname,
      _this.programCode,
      _this.admittedSemester,
      _this.cgpa,
      _this.totalCreditsEarned,
      _this.photoUrl,
      _this.onboardingStatus,
      _this.semesterType,
      _this.departmentName,
      _this.scholarshipStatus,
      _this.programName,
      _this.track,
      const DeepCollectionEquality().hash(_this.enrolledSections),
      const DeepCollectionEquality().hash(_this.enrolledSectionsNext),
      _this.enrolledCredits,
      _this.enrolledCreditsNext,
      const DeepCollectionEquality().hash(_this.pastHistory),
      _this.totalCoursesCompleted,
      _this.lastActiveAt,
      _this.appOpenCount,
      _this.appVersion,
      const DeepCollectionEquality().hash(_this.reminderSettings),
      _this.updatedAt,
      _this.createdAt
    ]);
  }

  @override
  String toString() {
    final _this = this as Profile;
    return 'Profile(id: ${_this.id}, studentId: ${_this.studentId}, fullName: ${_this.fullName}, nickname: ${_this.nickname}, programCode: ${_this.programCode}, admittedSemester: ${_this.admittedSemester}, cgpa: ${_this.cgpa}, totalCreditsEarned: ${_this.totalCreditsEarned}, photoUrl: ${_this.photoUrl}, onboardingStatus: ${_this.onboardingStatus}, semesterType: ${_this.semesterType}, departmentName: ${_this.departmentName}, scholarshipStatus: ${_this.scholarshipStatus}, programName: ${_this.programName}, track: ${_this.track}, enrolledSections: ${_this.enrolledSections}, enrolledSectionsNext: ${_this.enrolledSectionsNext}, enrolledCredits: ${_this.enrolledCredits}, enrolledCreditsNext: ${_this.enrolledCreditsNext}, pastHistory: ${_this.pastHistory}, totalCoursesCompleted: ${_this.totalCoursesCompleted}, lastActiveAt: ${_this.lastActiveAt}, appOpenCount: ${_this.appOpenCount}, appVersion: ${_this.appVersion}, reminderSettings: ${_this.reminderSettings}, updatedAt: ${_this.updatedAt}, createdAt: ${_this.createdAt})';
  }
}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) =
      _$ProfileCopyWithImpl;
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
class _$ProfileCopyWithImpl<$Res> implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(Profile(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: freezed == studentId
          ? _self.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: freezed == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: freezed == nickname
          ? _self.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      programCode: freezed == programCode
          ? _self.programCode
          : programCode // ignore: cast_nullable_to_non_nullable
              as String?,
      admittedSemester: freezed == admittedSemester
          ? _self.admittedSemester
          : admittedSemester // ignore: cast_nullable_to_non_nullable
              as String?,
      cgpa: freezed == cgpa
          ? _self.cgpa
          : cgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCreditsEarned: freezed == totalCreditsEarned
          ? _self.totalCreditsEarned
          : totalCreditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      onboardingStatus: null == onboardingStatus
          ? _self.onboardingStatus
          : onboardingStatus // ignore: cast_nullable_to_non_nullable
              as String,
      semesterType: null == semesterType
          ? _self.semesterType
          : semesterType // ignore: cast_nullable_to_non_nullable
              as String,
      departmentName: freezed == departmentName
          ? _self.departmentName
          : departmentName // ignore: cast_nullable_to_non_nullable
              as String?,
      scholarshipStatus: freezed == scholarshipStatus
          ? _self.scholarshipStatus
          : scholarshipStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      programName: freezed == programName
          ? _self.programName
          : programName // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String?,
      enrolledSections: null == enrolledSections
          ? _self.enrolledSections
          : enrolledSections // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enrolledSectionsNext: null == enrolledSectionsNext
          ? _self.enrolledSectionsNext
          : enrolledSectionsNext // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enrolledCredits: null == enrolledCredits
          ? _self.enrolledCredits
          : enrolledCredits // ignore: cast_nullable_to_non_nullable
              as double,
      enrolledCreditsNext: null == enrolledCreditsNext
          ? _self.enrolledCreditsNext
          : enrolledCreditsNext // ignore: cast_nullable_to_non_nullable
              as double,
      pastHistory: null == pastHistory
          ? _self.pastHistory
          : pastHistory // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      totalCoursesCompleted: null == totalCoursesCompleted
          ? _self.totalCoursesCompleted
          : totalCoursesCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      lastActiveAt: freezed == lastActiveAt
          ? _self.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      appOpenCount: null == appOpenCount
          ? _self.appOpenCount
          : appOpenCount // ignore: cast_nullable_to_non_nullable
              as int,
      appVersion: freezed == appVersion
          ? _self.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      reminderSettings: null == reminderSettings
          ? _self.reminderSettings
          : reminderSettings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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
    TResult Function(_Profile value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Profile() when $default != null:
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
    TResult Function(_Profile value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Profile():
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
    TResult? Function(_Profile value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Profile() when $default != null:
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
            @JsonKey(name: 'reminder_settings')
            Map<String, dynamic> reminderSettings,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            @JsonKey(name: 'created_at') DateTime? createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Profile() when $default != null:
        return $default(
            _that.id,
            _that.studentId,
            _that.fullName,
            _that.nickname,
            _that.programCode,
            _that.admittedSemester,
            _that.cgpa,
            _that.totalCreditsEarned,
            _that.photoUrl,
            _that.onboardingStatus,
            _that.semesterType,
            _that.departmentName,
            _that.scholarshipStatus,
            _that.programName,
            _that.track,
            _that.enrolledSections,
            _that.enrolledSectionsNext,
            _that.enrolledCredits,
            _that.enrolledCreditsNext,
            _that.pastHistory,
            _that.totalCoursesCompleted,
            _that.lastActiveAt,
            _that.appOpenCount,
            _that.appVersion,
            _that.reminderSettings,
            _that.updatedAt,
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
            @JsonKey(name: 'reminder_settings')
            Map<String, dynamic> reminderSettings,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            @JsonKey(name: 'created_at') DateTime? createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Profile():
        return $default(
            _that.id,
            _that.studentId,
            _that.fullName,
            _that.nickname,
            _that.programCode,
            _that.admittedSemester,
            _that.cgpa,
            _that.totalCreditsEarned,
            _that.photoUrl,
            _that.onboardingStatus,
            _that.semesterType,
            _that.departmentName,
            _that.scholarshipStatus,
            _that.programName,
            _that.track,
            _that.enrolledSections,
            _that.enrolledSectionsNext,
            _that.enrolledCredits,
            _that.enrolledCreditsNext,
            _that.pastHistory,
            _that.totalCoursesCompleted,
            _that.lastActiveAt,
            _that.appOpenCount,
            _that.appVersion,
            _that.reminderSettings,
            _that.updatedAt,
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
            @JsonKey(name: 'reminder_settings')
            Map<String, dynamic> reminderSettings,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            @JsonKey(name: 'created_at') DateTime? createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Profile() when $default != null:
        return $default(
            _that.id,
            _that.studentId,
            _that.fullName,
            _that.nickname,
            _that.programCode,
            _that.admittedSemester,
            _that.cgpa,
            _that.totalCreditsEarned,
            _that.photoUrl,
            _that.onboardingStatus,
            _that.semesterType,
            _that.departmentName,
            _that.scholarshipStatus,
            _that.programName,
            _that.track,
            _that.enrolledSections,
            _that.enrolledSectionsNext,
            _that.enrolledCredits,
            _that.enrolledCreditsNext,
            _that.pastHistory,
            _that.totalCoursesCompleted,
            _that.lastActiveAt,
            _that.appOpenCount,
            _that.appVersion,
            _that.reminderSettings,
            _that.updatedAt,
            _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Profile implements Profile {
  const _Profile(
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
      List<String> enrolledSections = const [],
      @JsonKey(name: 'enrolled_sections_next')
      List<String> enrolledSectionsNext = const [],
      @JsonKey(name: 'enrolled_credits') this.enrolledCredits = 0.0,
      @JsonKey(name: 'enrolled_credits_next') this.enrolledCreditsNext = 0.0,
      @JsonKey(name: 'past_history') List<dynamic> pastHistory = const [],
      @JsonKey(name: 'total_courses_completed') this.totalCoursesCompleted = 0,
      @JsonKey(name: 'last_active_at') this.lastActiveAt,
      @JsonKey(name: 'app_open_count') this.appOpenCount = 0,
      @JsonKey(name: 'app_version') this.appVersion,
      @JsonKey(name: 'reminder_settings')
      Map<String, dynamic> reminderSettings = const {},
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'created_at') this.createdAt})
      : _enrolledSections = enrolledSections,
        _enrolledSectionsNext = enrolledSectionsNext,
        _pastHistory = pastHistory,
        _reminderSettings = reminderSettings;
  factory _Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

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

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProfileCopyWith<_Profile> get copyWith =>
      __$ProfileCopyWithImpl<_Profile>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProfileToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Profile &&
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
                .equals(other.enrolledSections, _enrolledSections) &&
            const DeepCollectionEquality()
                .equals(other.enrolledSectionsNext, _enrolledSectionsNext) &&
            (identical(other.enrolledCredits, enrolledCredits) ||
                other.enrolledCredits == enrolledCredits) &&
            (identical(other.enrolledCreditsNext, enrolledCreditsNext) ||
                other.enrolledCreditsNext == enrolledCreditsNext) &&
            const DeepCollectionEquality()
                .equals(other.pastHistory, _pastHistory) &&
            (identical(other.totalCoursesCompleted, totalCoursesCompleted) ||
                other.totalCoursesCompleted == totalCoursesCompleted) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.appOpenCount, appOpenCount) ||
                other.appOpenCount == appOpenCount) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            const DeepCollectionEquality()
                .equals(other.reminderSettings, _reminderSettings) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hashAll([
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
  }

  @override
  String toString() {
    return 'Profile(id: $id, studentId: $studentId, fullName: $fullName, nickname: $nickname, programCode: $programCode, admittedSemester: $admittedSemester, cgpa: $cgpa, totalCreditsEarned: $totalCreditsEarned, photoUrl: $photoUrl, onboardingStatus: $onboardingStatus, semesterType: $semesterType, departmentName: $departmentName, scholarshipStatus: $scholarshipStatus, programName: $programName, track: $track, enrolledSections: $enrolledSections, enrolledSectionsNext: $enrolledSectionsNext, enrolledCredits: $enrolledCredits, enrolledCreditsNext: $enrolledCreditsNext, pastHistory: $pastHistory, totalCoursesCompleted: $totalCoursesCompleted, lastActiveAt: $lastActiveAt, appOpenCount: $appOpenCount, appVersion: $appVersion, reminderSettings: $reminderSettings, updatedAt: $updatedAt, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) =
      __$ProfileCopyWithImpl;
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
class __$ProfileCopyWithImpl<$Res> implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_Profile(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: freezed == studentId
          ? _self.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: freezed == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: freezed == nickname
          ? _self.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      programCode: freezed == programCode
          ? _self.programCode
          : programCode // ignore: cast_nullable_to_non_nullable
              as String?,
      admittedSemester: freezed == admittedSemester
          ? _self.admittedSemester
          : admittedSemester // ignore: cast_nullable_to_non_nullable
              as String?,
      cgpa: freezed == cgpa
          ? _self.cgpa
          : cgpa // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCreditsEarned: freezed == totalCreditsEarned
          ? _self.totalCreditsEarned
          : totalCreditsEarned // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      onboardingStatus: null == onboardingStatus
          ? _self.onboardingStatus
          : onboardingStatus // ignore: cast_nullable_to_non_nullable
              as String,
      semesterType: null == semesterType
          ? _self.semesterType
          : semesterType // ignore: cast_nullable_to_non_nullable
              as String,
      departmentName: freezed == departmentName
          ? _self.departmentName
          : departmentName // ignore: cast_nullable_to_non_nullable
              as String?,
      scholarshipStatus: freezed == scholarshipStatus
          ? _self.scholarshipStatus
          : scholarshipStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      programName: freezed == programName
          ? _self.programName
          : programName // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as String?,
      enrolledSections: null == enrolledSections
          ? _self._enrolledSections
          : enrolledSections // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enrolledSectionsNext: null == enrolledSectionsNext
          ? _self._enrolledSectionsNext
          : enrolledSectionsNext // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enrolledCredits: null == enrolledCredits
          ? _self.enrolledCredits
          : enrolledCredits // ignore: cast_nullable_to_non_nullable
              as double,
      enrolledCreditsNext: null == enrolledCreditsNext
          ? _self.enrolledCreditsNext
          : enrolledCreditsNext // ignore: cast_nullable_to_non_nullable
              as double,
      pastHistory: null == pastHistory
          ? _self._pastHistory
          : pastHistory // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      totalCoursesCompleted: null == totalCoursesCompleted
          ? _self.totalCoursesCompleted
          : totalCoursesCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      lastActiveAt: freezed == lastActiveAt
          ? _self.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      appOpenCount: null == appOpenCount
          ? _self.appOpenCount
          : appOpenCount // ignore: cast_nullable_to_non_nullable
              as int,
      appVersion: freezed == appVersion
          ? _self.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      reminderSettings: null == reminderSettings
          ? _self._reminderSettings
          : reminderSettings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
