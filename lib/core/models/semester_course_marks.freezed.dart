// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semester_course_marks.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SemesterCourseMarks {
  String get id;
  @JsonKey(name: 'user_id')
  String get userId;
  @JsonKey(name: 'semester_code')
  String get semesterCode;
  @JsonKey(name: 'course_code')
  String get courseCode;
  @JsonKey(name: 'course_name')
  String? get courseName;
  String? get section;
  @JsonKey(name: 'quiz_strategy')
  String get quizStrategy;
  @JsonKey(name: 'quiz_n')
  int get quizN;
  @JsonKey(name: 'short_quiz_n')
  int get shortQuizN;
  @JsonKey(name: 'dist_mid')
  double get distMid;
  @JsonKey(name: 'dist_final')
  double get distFinal;
  @JsonKey(name: 'dist_quiz')
  double get distQuiz;
  @JsonKey(name: 'dist_short_quiz')
  double? get distShortQuiz;
  @JsonKey(name: 'dist_assignment')
  double? get distAssignment;
  @JsonKey(name: 'dist_presentation')
  double? get distPresentation;
  @JsonKey(name: 'dist_viva')
  double? get distViva;
  @JsonKey(name: 'dist_attendance')
  double? get distAttendance;
  @JsonKey(name: 'dist_lab')
  double? get distLab;
  @JsonKey(name: 'dist_project')
  double? get distProject;
  @JsonKey(name: 'dist_term_paper')
  double? get distTermPaper;
  @JsonKey(name: 'dist_class_performance')
  double? get distClassPerformance;
  @JsonKey(name: 'obt_mid')
  double? get obtMid;
  @JsonKey(name: 'obt_final')
  double? get obtFinal;
  @JsonKey(name: 'obt_assignment')
  double? get obtAssignment;
  @JsonKey(name: 'obt_presentation')
  double? get obtPresentation;
  @JsonKey(name: 'obt_viva')
  double? get obtViva;
  @JsonKey(name: 'obt_attendance')
  double? get obtAttendance;
  @JsonKey(name: 'obt_lab')
  double? get obtLab;
  @JsonKey(name: 'obt_project')
  double? get obtProject;
  @JsonKey(name: 'obt_term_paper')
  double? get obtTermPaper;
  @JsonKey(name: 'obt_class_performance')
  double? get obtClassPerformance;
  @JsonKey(name: 'obt_quizzes')
  List<double> get obtQuizzes;
  @JsonKey(name: 'obt_short_quizzes')
  List<double> get obtShortQuizzes;
  @JsonKey(name: 'grade_goal')
  String? get gradeGoal;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of SemesterCourseMarks
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SemesterCourseMarksCopyWith<SemesterCourseMarks> get copyWith =>
      _$SemesterCourseMarksCopyWithImpl<SemesterCourseMarks>(
          this as SemesterCourseMarks, _$identity);

  /// Serializes this SemesterCourseMarks to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SemesterCourseMarks;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SemesterCourseMarks &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.semesterCode, _this.semesterCode) ||
                other.semesterCode == _this.semesterCode) &&
            (identical(other.courseCode, _this.courseCode) ||
                other.courseCode == _this.courseCode) &&
            (identical(other.courseName, _this.courseName) ||
                other.courseName == _this.courseName) &&
            (identical(other.section, _this.section) ||
                other.section == _this.section) &&
            (identical(other.quizStrategy, _this.quizStrategy) ||
                other.quizStrategy == _this.quizStrategy) &&
            (identical(other.quizN, _this.quizN) ||
                other.quizN == _this.quizN) &&
            (identical(other.shortQuizN, _this.shortQuizN) ||
                other.shortQuizN == _this.shortQuizN) &&
            (identical(other.distMid, _this.distMid) ||
                other.distMid == _this.distMid) &&
            (identical(other.distFinal, _this.distFinal) ||
                other.distFinal == _this.distFinal) &&
            (identical(other.distQuiz, _this.distQuiz) ||
                other.distQuiz == _this.distQuiz) &&
            (identical(other.distShortQuiz, _this.distShortQuiz) ||
                other.distShortQuiz == _this.distShortQuiz) &&
            (identical(other.distAssignment, _this.distAssignment) ||
                other.distAssignment == _this.distAssignment) &&
            (identical(other.distPresentation, _this.distPresentation) ||
                other.distPresentation == _this.distPresentation) &&
            (identical(other.distViva, _this.distViva) ||
                other.distViva == _this.distViva) &&
            (identical(other.distAttendance, _this.distAttendance) ||
                other.distAttendance == _this.distAttendance) &&
            (identical(other.distLab, _this.distLab) ||
                other.distLab == _this.distLab) &&
            (identical(other.distProject, _this.distProject) ||
                other.distProject == _this.distProject) &&
            (identical(other.distTermPaper, _this.distTermPaper) ||
                other.distTermPaper == _this.distTermPaper) &&
            (identical(
                    other.distClassPerformance, _this.distClassPerformance) ||
                other.distClassPerformance == _this.distClassPerformance) &&
            (identical(other.obtMid, _this.obtMid) ||
                other.obtMid == _this.obtMid) &&
            (identical(other.obtFinal, _this.obtFinal) ||
                other.obtFinal == _this.obtFinal) &&
            (identical(other.obtAssignment, _this.obtAssignment) ||
                other.obtAssignment == _this.obtAssignment) &&
            (identical(other.obtPresentation, _this.obtPresentation) ||
                other.obtPresentation == _this.obtPresentation) &&
            (identical(other.obtViva, _this.obtViva) ||
                other.obtViva == _this.obtViva) &&
            (identical(other.obtAttendance, _this.obtAttendance) ||
                other.obtAttendance == _this.obtAttendance) &&
            (identical(other.obtLab, _this.obtLab) ||
                other.obtLab == _this.obtLab) &&
            (identical(other.obtProject, _this.obtProject) ||
                other.obtProject == _this.obtProject) &&
            (identical(other.obtTermPaper, _this.obtTermPaper) ||
                other.obtTermPaper == _this.obtTermPaper) &&
            (identical(other.obtClassPerformance, _this.obtClassPerformance) ||
                other.obtClassPerformance == _this.obtClassPerformance) &&
            const DeepCollectionEquality()
                .equals(other.obtQuizzes, _this.obtQuizzes) &&
            const DeepCollectionEquality()
                .equals(other.obtShortQuizzes, _this.obtShortQuizzes) &&
            (identical(other.gradeGoal, _this.gradeGoal) ||
                other.gradeGoal == _this.gradeGoal) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SemesterCourseMarks;
    return Object.hashAll([
      runtimeType,
      _this.id,
      _this.userId,
      _this.semesterCode,
      _this.courseCode,
      _this.courseName,
      _this.section,
      _this.quizStrategy,
      _this.quizN,
      _this.shortQuizN,
      _this.distMid,
      _this.distFinal,
      _this.distQuiz,
      _this.distShortQuiz,
      _this.distAssignment,
      _this.distPresentation,
      _this.distViva,
      _this.distAttendance,
      _this.distLab,
      _this.distProject,
      _this.distTermPaper,
      _this.distClassPerformance,
      _this.obtMid,
      _this.obtFinal,
      _this.obtAssignment,
      _this.obtPresentation,
      _this.obtViva,
      _this.obtAttendance,
      _this.obtLab,
      _this.obtProject,
      _this.obtTermPaper,
      _this.obtClassPerformance,
      const DeepCollectionEquality().hash(_this.obtQuizzes),
      const DeepCollectionEquality().hash(_this.obtShortQuizzes),
      _this.gradeGoal,
      _this.createdAt,
      _this.updatedAt
    ]);
  }

  @override
  String toString() {
    final _this = this as SemesterCourseMarks;
    return 'SemesterCourseMarks(id: ${_this.id}, userId: ${_this.userId}, semesterCode: ${_this.semesterCode}, courseCode: ${_this.courseCode}, courseName: ${_this.courseName}, section: ${_this.section}, quizStrategy: ${_this.quizStrategy}, quizN: ${_this.quizN}, shortQuizN: ${_this.shortQuizN}, distMid: ${_this.distMid}, distFinal: ${_this.distFinal}, distQuiz: ${_this.distQuiz}, distShortQuiz: ${_this.distShortQuiz}, distAssignment: ${_this.distAssignment}, distPresentation: ${_this.distPresentation}, distViva: ${_this.distViva}, distAttendance: ${_this.distAttendance}, distLab: ${_this.distLab}, distProject: ${_this.distProject}, distTermPaper: ${_this.distTermPaper}, distClassPerformance: ${_this.distClassPerformance}, obtMid: ${_this.obtMid}, obtFinal: ${_this.obtFinal}, obtAssignment: ${_this.obtAssignment}, obtPresentation: ${_this.obtPresentation}, obtViva: ${_this.obtViva}, obtAttendance: ${_this.obtAttendance}, obtLab: ${_this.obtLab}, obtProject: ${_this.obtProject}, obtTermPaper: ${_this.obtTermPaper}, obtClassPerformance: ${_this.obtClassPerformance}, obtQuizzes: ${_this.obtQuizzes}, obtShortQuizzes: ${_this.obtShortQuizzes}, gradeGoal: ${_this.gradeGoal}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $SemesterCourseMarksCopyWith<$Res> {
  factory $SemesterCourseMarksCopyWith(
          SemesterCourseMarks value, $Res Function(SemesterCourseMarks) _then) =
      _$SemesterCourseMarksCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'course_code') String courseCode,
      @JsonKey(name: 'course_name') String? courseName,
      String? section,
      @JsonKey(name: 'quiz_strategy') String quizStrategy,
      @JsonKey(name: 'quiz_n') int quizN,
      @JsonKey(name: 'short_quiz_n') int shortQuizN,
      @JsonKey(name: 'dist_mid') double distMid,
      @JsonKey(name: 'dist_final') double distFinal,
      @JsonKey(name: 'dist_quiz') double distQuiz,
      @JsonKey(name: 'dist_short_quiz') double? distShortQuiz,
      @JsonKey(name: 'dist_assignment') double? distAssignment,
      @JsonKey(name: 'dist_presentation') double? distPresentation,
      @JsonKey(name: 'dist_viva') double? distViva,
      @JsonKey(name: 'dist_attendance') double? distAttendance,
      @JsonKey(name: 'dist_lab') double? distLab,
      @JsonKey(name: 'dist_project') double? distProject,
      @JsonKey(name: 'dist_term_paper') double? distTermPaper,
      @JsonKey(name: 'dist_class_performance') double? distClassPerformance,
      @JsonKey(name: 'obt_mid') double? obtMid,
      @JsonKey(name: 'obt_final') double? obtFinal,
      @JsonKey(name: 'obt_assignment') double? obtAssignment,
      @JsonKey(name: 'obt_presentation') double? obtPresentation,
      @JsonKey(name: 'obt_viva') double? obtViva,
      @JsonKey(name: 'obt_attendance') double? obtAttendance,
      @JsonKey(name: 'obt_lab') double? obtLab,
      @JsonKey(name: 'obt_project') double? obtProject,
      @JsonKey(name: 'obt_term_paper') double? obtTermPaper,
      @JsonKey(name: 'obt_class_performance') double? obtClassPerformance,
      @JsonKey(name: 'obt_quizzes') List<double> obtQuizzes,
      @JsonKey(name: 'obt_short_quizzes') List<double> obtShortQuizzes,
      @JsonKey(name: 'grade_goal') String? gradeGoal,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$SemesterCourseMarksCopyWithImpl<$Res>
    implements $SemesterCourseMarksCopyWith<$Res> {
  _$SemesterCourseMarksCopyWithImpl(this._self, this._then);

  final SemesterCourseMarks _self;
  final $Res Function(SemesterCourseMarks) _then;

  /// Create a copy of SemesterCourseMarks
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? semesterCode = null,
    Object? courseCode = null,
    Object? courseName = freezed,
    Object? section = freezed,
    Object? quizStrategy = null,
    Object? quizN = null,
    Object? shortQuizN = null,
    Object? distMid = null,
    Object? distFinal = null,
    Object? distQuiz = null,
    Object? distShortQuiz = freezed,
    Object? distAssignment = freezed,
    Object? distPresentation = freezed,
    Object? distViva = freezed,
    Object? distAttendance = freezed,
    Object? distLab = freezed,
    Object? distProject = freezed,
    Object? distTermPaper = freezed,
    Object? distClassPerformance = freezed,
    Object? obtMid = freezed,
    Object? obtFinal = freezed,
    Object? obtAssignment = freezed,
    Object? obtPresentation = freezed,
    Object? obtViva = freezed,
    Object? obtAttendance = freezed,
    Object? obtLab = freezed,
    Object? obtProject = freezed,
    Object? obtTermPaper = freezed,
    Object? obtClassPerformance = freezed,
    Object? obtQuizzes = null,
    Object? obtShortQuizzes = null,
    Object? gradeGoal = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(SemesterCourseMarks(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _self.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      courseName: freezed == courseName
          ? _self.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String?,
      section: freezed == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String?,
      quizStrategy: null == quizStrategy
          ? _self.quizStrategy
          : quizStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      quizN: null == quizN
          ? _self.quizN
          : quizN // ignore: cast_nullable_to_non_nullable
              as int,
      shortQuizN: null == shortQuizN
          ? _self.shortQuizN
          : shortQuizN // ignore: cast_nullable_to_non_nullable
              as int,
      distMid: null == distMid
          ? _self.distMid
          : distMid // ignore: cast_nullable_to_non_nullable
              as double,
      distFinal: null == distFinal
          ? _self.distFinal
          : distFinal // ignore: cast_nullable_to_non_nullable
              as double,
      distQuiz: null == distQuiz
          ? _self.distQuiz
          : distQuiz // ignore: cast_nullable_to_non_nullable
              as double,
      distShortQuiz: freezed == distShortQuiz
          ? _self.distShortQuiz
          : distShortQuiz // ignore: cast_nullable_to_non_nullable
              as double?,
      distAssignment: freezed == distAssignment
          ? _self.distAssignment
          : distAssignment // ignore: cast_nullable_to_non_nullable
              as double?,
      distPresentation: freezed == distPresentation
          ? _self.distPresentation
          : distPresentation // ignore: cast_nullable_to_non_nullable
              as double?,
      distViva: freezed == distViva
          ? _self.distViva
          : distViva // ignore: cast_nullable_to_non_nullable
              as double?,
      distAttendance: freezed == distAttendance
          ? _self.distAttendance
          : distAttendance // ignore: cast_nullable_to_non_nullable
              as double?,
      distLab: freezed == distLab
          ? _self.distLab
          : distLab // ignore: cast_nullable_to_non_nullable
              as double?,
      distProject: freezed == distProject
          ? _self.distProject
          : distProject // ignore: cast_nullable_to_non_nullable
              as double?,
      distTermPaper: freezed == distTermPaper
          ? _self.distTermPaper
          : distTermPaper // ignore: cast_nullable_to_non_nullable
              as double?,
      distClassPerformance: freezed == distClassPerformance
          ? _self.distClassPerformance
          : distClassPerformance // ignore: cast_nullable_to_non_nullable
              as double?,
      obtMid: freezed == obtMid
          ? _self.obtMid
          : obtMid // ignore: cast_nullable_to_non_nullable
              as double?,
      obtFinal: freezed == obtFinal
          ? _self.obtFinal
          : obtFinal // ignore: cast_nullable_to_non_nullable
              as double?,
      obtAssignment: freezed == obtAssignment
          ? _self.obtAssignment
          : obtAssignment // ignore: cast_nullable_to_non_nullable
              as double?,
      obtPresentation: freezed == obtPresentation
          ? _self.obtPresentation
          : obtPresentation // ignore: cast_nullable_to_non_nullable
              as double?,
      obtViva: freezed == obtViva
          ? _self.obtViva
          : obtViva // ignore: cast_nullable_to_non_nullable
              as double?,
      obtAttendance: freezed == obtAttendance
          ? _self.obtAttendance
          : obtAttendance // ignore: cast_nullable_to_non_nullable
              as double?,
      obtLab: freezed == obtLab
          ? _self.obtLab
          : obtLab // ignore: cast_nullable_to_non_nullable
              as double?,
      obtProject: freezed == obtProject
          ? _self.obtProject
          : obtProject // ignore: cast_nullable_to_non_nullable
              as double?,
      obtTermPaper: freezed == obtTermPaper
          ? _self.obtTermPaper
          : obtTermPaper // ignore: cast_nullable_to_non_nullable
              as double?,
      obtClassPerformance: freezed == obtClassPerformance
          ? _self.obtClassPerformance
          : obtClassPerformance // ignore: cast_nullable_to_non_nullable
              as double?,
      obtQuizzes: null == obtQuizzes
          ? _self.obtQuizzes
          : obtQuizzes // ignore: cast_nullable_to_non_nullable
              as List<double>,
      obtShortQuizzes: null == obtShortQuizzes
          ? _self.obtShortQuizzes
          : obtShortQuizzes // ignore: cast_nullable_to_non_nullable
              as List<double>,
      gradeGoal: freezed == gradeGoal
          ? _self.gradeGoal
          : gradeGoal // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SemesterCourseMarks].
extension SemesterCourseMarksPatterns on SemesterCourseMarks {
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
    TResult Function(_SemesterCourseMarks value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseMarks() when $default != null:
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
    TResult Function(_SemesterCourseMarks value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseMarks():
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
    TResult? Function(_SemesterCourseMarks value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseMarks() when $default != null:
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
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'course_name') String? courseName,
            String? section,
            @JsonKey(name: 'quiz_strategy') String quizStrategy,
            @JsonKey(name: 'quiz_n') int quizN,
            @JsonKey(name: 'short_quiz_n') int shortQuizN,
            @JsonKey(name: 'dist_mid') double distMid,
            @JsonKey(name: 'dist_final') double distFinal,
            @JsonKey(name: 'dist_quiz') double distQuiz,
            @JsonKey(name: 'dist_short_quiz') double? distShortQuiz,
            @JsonKey(name: 'dist_assignment') double? distAssignment,
            @JsonKey(name: 'dist_presentation') double? distPresentation,
            @JsonKey(name: 'dist_viva') double? distViva,
            @JsonKey(name: 'dist_attendance') double? distAttendance,
            @JsonKey(name: 'dist_lab') double? distLab,
            @JsonKey(name: 'dist_project') double? distProject,
            @JsonKey(name: 'dist_term_paper') double? distTermPaper,
            @JsonKey(name: 'dist_class_performance')
            double? distClassPerformance,
            @JsonKey(name: 'obt_mid') double? obtMid,
            @JsonKey(name: 'obt_final') double? obtFinal,
            @JsonKey(name: 'obt_assignment') double? obtAssignment,
            @JsonKey(name: 'obt_presentation') double? obtPresentation,
            @JsonKey(name: 'obt_viva') double? obtViva,
            @JsonKey(name: 'obt_attendance') double? obtAttendance,
            @JsonKey(name: 'obt_lab') double? obtLab,
            @JsonKey(name: 'obt_project') double? obtProject,
            @JsonKey(name: 'obt_term_paper') double? obtTermPaper,
            @JsonKey(name: 'obt_class_performance') double? obtClassPerformance,
            @JsonKey(name: 'obt_quizzes') List<double> obtQuizzes,
            @JsonKey(name: 'obt_short_quizzes') List<double> obtShortQuizzes,
            @JsonKey(name: 'grade_goal') String? gradeGoal,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseMarks() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.courseCode,
            _that.courseName,
            _that.section,
            _that.quizStrategy,
            _that.quizN,
            _that.shortQuizN,
            _that.distMid,
            _that.distFinal,
            _that.distQuiz,
            _that.distShortQuiz,
            _that.distAssignment,
            _that.distPresentation,
            _that.distViva,
            _that.distAttendance,
            _that.distLab,
            _that.distProject,
            _that.distTermPaper,
            _that.distClassPerformance,
            _that.obtMid,
            _that.obtFinal,
            _that.obtAssignment,
            _that.obtPresentation,
            _that.obtViva,
            _that.obtAttendance,
            _that.obtLab,
            _that.obtProject,
            _that.obtTermPaper,
            _that.obtClassPerformance,
            _that.obtQuizzes,
            _that.obtShortQuizzes,
            _that.gradeGoal,
            _that.createdAt,
            _that.updatedAt);
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
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'course_name') String? courseName,
            String? section,
            @JsonKey(name: 'quiz_strategy') String quizStrategy,
            @JsonKey(name: 'quiz_n') int quizN,
            @JsonKey(name: 'short_quiz_n') int shortQuizN,
            @JsonKey(name: 'dist_mid') double distMid,
            @JsonKey(name: 'dist_final') double distFinal,
            @JsonKey(name: 'dist_quiz') double distQuiz,
            @JsonKey(name: 'dist_short_quiz') double? distShortQuiz,
            @JsonKey(name: 'dist_assignment') double? distAssignment,
            @JsonKey(name: 'dist_presentation') double? distPresentation,
            @JsonKey(name: 'dist_viva') double? distViva,
            @JsonKey(name: 'dist_attendance') double? distAttendance,
            @JsonKey(name: 'dist_lab') double? distLab,
            @JsonKey(name: 'dist_project') double? distProject,
            @JsonKey(name: 'dist_term_paper') double? distTermPaper,
            @JsonKey(name: 'dist_class_performance')
            double? distClassPerformance,
            @JsonKey(name: 'obt_mid') double? obtMid,
            @JsonKey(name: 'obt_final') double? obtFinal,
            @JsonKey(name: 'obt_assignment') double? obtAssignment,
            @JsonKey(name: 'obt_presentation') double? obtPresentation,
            @JsonKey(name: 'obt_viva') double? obtViva,
            @JsonKey(name: 'obt_attendance') double? obtAttendance,
            @JsonKey(name: 'obt_lab') double? obtLab,
            @JsonKey(name: 'obt_project') double? obtProject,
            @JsonKey(name: 'obt_term_paper') double? obtTermPaper,
            @JsonKey(name: 'obt_class_performance') double? obtClassPerformance,
            @JsonKey(name: 'obt_quizzes') List<double> obtQuizzes,
            @JsonKey(name: 'obt_short_quizzes') List<double> obtShortQuizzes,
            @JsonKey(name: 'grade_goal') String? gradeGoal,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseMarks():
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.courseCode,
            _that.courseName,
            _that.section,
            _that.quizStrategy,
            _that.quizN,
            _that.shortQuizN,
            _that.distMid,
            _that.distFinal,
            _that.distQuiz,
            _that.distShortQuiz,
            _that.distAssignment,
            _that.distPresentation,
            _that.distViva,
            _that.distAttendance,
            _that.distLab,
            _that.distProject,
            _that.distTermPaper,
            _that.distClassPerformance,
            _that.obtMid,
            _that.obtFinal,
            _that.obtAssignment,
            _that.obtPresentation,
            _that.obtViva,
            _that.obtAttendance,
            _that.obtLab,
            _that.obtProject,
            _that.obtTermPaper,
            _that.obtClassPerformance,
            _that.obtQuizzes,
            _that.obtShortQuizzes,
            _that.gradeGoal,
            _that.createdAt,
            _that.updatedAt);
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
            @JsonKey(name: 'semester_code') String semesterCode,
            @JsonKey(name: 'course_code') String courseCode,
            @JsonKey(name: 'course_name') String? courseName,
            String? section,
            @JsonKey(name: 'quiz_strategy') String quizStrategy,
            @JsonKey(name: 'quiz_n') int quizN,
            @JsonKey(name: 'short_quiz_n') int shortQuizN,
            @JsonKey(name: 'dist_mid') double distMid,
            @JsonKey(name: 'dist_final') double distFinal,
            @JsonKey(name: 'dist_quiz') double distQuiz,
            @JsonKey(name: 'dist_short_quiz') double? distShortQuiz,
            @JsonKey(name: 'dist_assignment') double? distAssignment,
            @JsonKey(name: 'dist_presentation') double? distPresentation,
            @JsonKey(name: 'dist_viva') double? distViva,
            @JsonKey(name: 'dist_attendance') double? distAttendance,
            @JsonKey(name: 'dist_lab') double? distLab,
            @JsonKey(name: 'dist_project') double? distProject,
            @JsonKey(name: 'dist_term_paper') double? distTermPaper,
            @JsonKey(name: 'dist_class_performance')
            double? distClassPerformance,
            @JsonKey(name: 'obt_mid') double? obtMid,
            @JsonKey(name: 'obt_final') double? obtFinal,
            @JsonKey(name: 'obt_assignment') double? obtAssignment,
            @JsonKey(name: 'obt_presentation') double? obtPresentation,
            @JsonKey(name: 'obt_viva') double? obtViva,
            @JsonKey(name: 'obt_attendance') double? obtAttendance,
            @JsonKey(name: 'obt_lab') double? obtLab,
            @JsonKey(name: 'obt_project') double? obtProject,
            @JsonKey(name: 'obt_term_paper') double? obtTermPaper,
            @JsonKey(name: 'obt_class_performance') double? obtClassPerformance,
            @JsonKey(name: 'obt_quizzes') List<double> obtQuizzes,
            @JsonKey(name: 'obt_short_quizzes') List<double> obtShortQuizzes,
            @JsonKey(name: 'grade_goal') String? gradeGoal,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SemesterCourseMarks() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.semesterCode,
            _that.courseCode,
            _that.courseName,
            _that.section,
            _that.quizStrategy,
            _that.quizN,
            _that.shortQuizN,
            _that.distMid,
            _that.distFinal,
            _that.distQuiz,
            _that.distShortQuiz,
            _that.distAssignment,
            _that.distPresentation,
            _that.distViva,
            _that.distAttendance,
            _that.distLab,
            _that.distProject,
            _that.distTermPaper,
            _that.distClassPerformance,
            _that.obtMid,
            _that.obtFinal,
            _that.obtAssignment,
            _that.obtPresentation,
            _that.obtViva,
            _that.obtAttendance,
            _that.obtLab,
            _that.obtProject,
            _that.obtTermPaper,
            _that.obtClassPerformance,
            _that.obtQuizzes,
            _that.obtShortQuizzes,
            _that.gradeGoal,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SemesterCourseMarks extends SemesterCourseMarks {
  const _SemesterCourseMarks(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'semester_code') required this.semesterCode,
      @JsonKey(name: 'course_code') required this.courseCode,
      @JsonKey(name: 'course_name') this.courseName,
      this.section,
      @JsonKey(name: 'quiz_strategy') this.quizStrategy = 'bestN',
      @JsonKey(name: 'quiz_n') this.quizN = 2,
      @JsonKey(name: 'short_quiz_n') this.shortQuizN = 2,
      @JsonKey(name: 'dist_mid') this.distMid = 30.0,
      @JsonKey(name: 'dist_final') this.distFinal = 40.0,
      @JsonKey(name: 'dist_quiz') this.distQuiz = 10.0,
      @JsonKey(name: 'dist_short_quiz') this.distShortQuiz,
      @JsonKey(name: 'dist_assignment') this.distAssignment,
      @JsonKey(name: 'dist_presentation') this.distPresentation,
      @JsonKey(name: 'dist_viva') this.distViva,
      @JsonKey(name: 'dist_attendance') this.distAttendance,
      @JsonKey(name: 'dist_lab') this.distLab,
      @JsonKey(name: 'dist_project') this.distProject,
      @JsonKey(name: 'dist_term_paper') this.distTermPaper,
      @JsonKey(name: 'dist_class_performance') this.distClassPerformance,
      @JsonKey(name: 'obt_mid') this.obtMid,
      @JsonKey(name: 'obt_final') this.obtFinal,
      @JsonKey(name: 'obt_assignment') this.obtAssignment,
      @JsonKey(name: 'obt_presentation') this.obtPresentation,
      @JsonKey(name: 'obt_viva') this.obtViva,
      @JsonKey(name: 'obt_attendance') this.obtAttendance,
      @JsonKey(name: 'obt_lab') this.obtLab,
      @JsonKey(name: 'obt_project') this.obtProject,
      @JsonKey(name: 'obt_term_paper') this.obtTermPaper,
      @JsonKey(name: 'obt_class_performance') this.obtClassPerformance,
      @JsonKey(name: 'obt_quizzes') List<double> obtQuizzes = const [],
      @JsonKey(name: 'obt_short_quizzes')
      List<double> obtShortQuizzes = const [],
      @JsonKey(name: 'grade_goal') this.gradeGoal,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _obtQuizzes = obtQuizzes,
        _obtShortQuizzes = obtShortQuizzes,
        super._();
  factory _SemesterCourseMarks.fromJson(Map<String, dynamic> json) =>
      _$SemesterCourseMarksFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'semester_code')
  final String semesterCode;
  @override
  @JsonKey(name: 'course_code')
  final String courseCode;
  @override
  @JsonKey(name: 'course_name')
  final String? courseName;
  @override
  final String? section;
  @override
  @JsonKey(name: 'quiz_strategy')
  final String quizStrategy;
  @override
  @JsonKey(name: 'quiz_n')
  final int quizN;
  @override
  @JsonKey(name: 'short_quiz_n')
  final int shortQuizN;
  @override
  @JsonKey(name: 'dist_mid')
  final double distMid;
  @override
  @JsonKey(name: 'dist_final')
  final double distFinal;
  @override
  @JsonKey(name: 'dist_quiz')
  final double distQuiz;
  @override
  @JsonKey(name: 'dist_short_quiz')
  final double? distShortQuiz;
  @override
  @JsonKey(name: 'dist_assignment')
  final double? distAssignment;
  @override
  @JsonKey(name: 'dist_presentation')
  final double? distPresentation;
  @override
  @JsonKey(name: 'dist_viva')
  final double? distViva;
  @override
  @JsonKey(name: 'dist_attendance')
  final double? distAttendance;
  @override
  @JsonKey(name: 'dist_lab')
  final double? distLab;
  @override
  @JsonKey(name: 'dist_project')
  final double? distProject;
  @override
  @JsonKey(name: 'dist_term_paper')
  final double? distTermPaper;
  @override
  @JsonKey(name: 'dist_class_performance')
  final double? distClassPerformance;
  @override
  @JsonKey(name: 'obt_mid')
  final double? obtMid;
  @override
  @JsonKey(name: 'obt_final')
  final double? obtFinal;
  @override
  @JsonKey(name: 'obt_assignment')
  final double? obtAssignment;
  @override
  @JsonKey(name: 'obt_presentation')
  final double? obtPresentation;
  @override
  @JsonKey(name: 'obt_viva')
  final double? obtViva;
  @override
  @JsonKey(name: 'obt_attendance')
  final double? obtAttendance;
  @override
  @JsonKey(name: 'obt_lab')
  final double? obtLab;
  @override
  @JsonKey(name: 'obt_project')
  final double? obtProject;
  @override
  @JsonKey(name: 'obt_term_paper')
  final double? obtTermPaper;
  @override
  @JsonKey(name: 'obt_class_performance')
  final double? obtClassPerformance;
  final List<double> _obtQuizzes;
  @override
  @JsonKey(name: 'obt_quizzes')
  List<double> get obtQuizzes {
    if (_obtQuizzes is EqualUnmodifiableListView) return _obtQuizzes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_obtQuizzes);
  }

  final List<double> _obtShortQuizzes;
  @override
  @JsonKey(name: 'obt_short_quizzes')
  List<double> get obtShortQuizzes {
    if (_obtShortQuizzes is EqualUnmodifiableListView) return _obtShortQuizzes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_obtShortQuizzes);
  }

  @override
  @JsonKey(name: 'grade_goal')
  final String? gradeGoal;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of SemesterCourseMarks
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SemesterCourseMarksCopyWith<_SemesterCourseMarks> get copyWith =>
      __$SemesterCourseMarksCopyWithImpl<_SemesterCourseMarks>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SemesterCourseMarksToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SemesterCourseMarks &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.semesterCode, semesterCode) ||
                other.semesterCode == semesterCode) &&
            (identical(other.courseCode, courseCode) ||
                other.courseCode == courseCode) &&
            (identical(other.courseName, courseName) ||
                other.courseName == courseName) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.quizStrategy, quizStrategy) ||
                other.quizStrategy == quizStrategy) &&
            (identical(other.quizN, quizN) || other.quizN == quizN) &&
            (identical(other.shortQuizN, shortQuizN) ||
                other.shortQuizN == shortQuizN) &&
            (identical(other.distMid, distMid) || other.distMid == distMid) &&
            (identical(other.distFinal, distFinal) ||
                other.distFinal == distFinal) &&
            (identical(other.distQuiz, distQuiz) ||
                other.distQuiz == distQuiz) &&
            (identical(other.distShortQuiz, distShortQuiz) ||
                other.distShortQuiz == distShortQuiz) &&
            (identical(other.distAssignment, distAssignment) ||
                other.distAssignment == distAssignment) &&
            (identical(other.distPresentation, distPresentation) ||
                other.distPresentation == distPresentation) &&
            (identical(other.distViva, distViva) ||
                other.distViva == distViva) &&
            (identical(other.distAttendance, distAttendance) ||
                other.distAttendance == distAttendance) &&
            (identical(other.distLab, distLab) || other.distLab == distLab) &&
            (identical(other.distProject, distProject) ||
                other.distProject == distProject) &&
            (identical(other.distTermPaper, distTermPaper) ||
                other.distTermPaper == distTermPaper) &&
            (identical(other.distClassPerformance, distClassPerformance) ||
                other.distClassPerformance == distClassPerformance) &&
            (identical(other.obtMid, obtMid) || other.obtMid == obtMid) &&
            (identical(other.obtFinal, obtFinal) ||
                other.obtFinal == obtFinal) &&
            (identical(other.obtAssignment, obtAssignment) ||
                other.obtAssignment == obtAssignment) &&
            (identical(other.obtPresentation, obtPresentation) ||
                other.obtPresentation == obtPresentation) &&
            (identical(other.obtViva, obtViva) || other.obtViva == obtViva) &&
            (identical(other.obtAttendance, obtAttendance) ||
                other.obtAttendance == obtAttendance) &&
            (identical(other.obtLab, obtLab) || other.obtLab == obtLab) &&
            (identical(other.obtProject, obtProject) ||
                other.obtProject == obtProject) &&
            (identical(other.obtTermPaper, obtTermPaper) ||
                other.obtTermPaper == obtTermPaper) &&
            (identical(other.obtClassPerformance, obtClassPerformance) ||
                other.obtClassPerformance == obtClassPerformance) &&
            const DeepCollectionEquality()
                .equals(other.obtQuizzes, _obtQuizzes) &&
            const DeepCollectionEquality()
                .equals(other.obtShortQuizzes, _obtShortQuizzes) &&
            (identical(other.gradeGoal, gradeGoal) ||
                other.gradeGoal == gradeGoal) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      id,
      userId,
      semesterCode,
      courseCode,
      courseName,
      section,
      quizStrategy,
      quizN,
      shortQuizN,
      distMid,
      distFinal,
      distQuiz,
      distShortQuiz,
      distAssignment,
      distPresentation,
      distViva,
      distAttendance,
      distLab,
      distProject,
      distTermPaper,
      distClassPerformance,
      obtMid,
      obtFinal,
      obtAssignment,
      obtPresentation,
      obtViva,
      obtAttendance,
      obtLab,
      obtProject,
      obtTermPaper,
      obtClassPerformance,
      const DeepCollectionEquality().hash(_obtQuizzes),
      const DeepCollectionEquality().hash(_obtShortQuizzes),
      gradeGoal,
      createdAt,
      updatedAt
    ]);
  }

  @override
  String toString() {
    return 'SemesterCourseMarks(id: $id, userId: $userId, semesterCode: $semesterCode, courseCode: $courseCode, courseName: $courseName, section: $section, quizStrategy: $quizStrategy, quizN: $quizN, shortQuizN: $shortQuizN, distMid: $distMid, distFinal: $distFinal, distQuiz: $distQuiz, distShortQuiz: $distShortQuiz, distAssignment: $distAssignment, distPresentation: $distPresentation, distViva: $distViva, distAttendance: $distAttendance, distLab: $distLab, distProject: $distProject, distTermPaper: $distTermPaper, distClassPerformance: $distClassPerformance, obtMid: $obtMid, obtFinal: $obtFinal, obtAssignment: $obtAssignment, obtPresentation: $obtPresentation, obtViva: $obtViva, obtAttendance: $obtAttendance, obtLab: $obtLab, obtProject: $obtProject, obtTermPaper: $obtTermPaper, obtClassPerformance: $obtClassPerformance, obtQuizzes: $obtQuizzes, obtShortQuizzes: $obtShortQuizzes, gradeGoal: $gradeGoal, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$SemesterCourseMarksCopyWith<$Res>
    implements $SemesterCourseMarksCopyWith<$Res> {
  factory _$SemesterCourseMarksCopyWith(_SemesterCourseMarks value,
          $Res Function(_SemesterCourseMarks) _then) =
      __$SemesterCourseMarksCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'semester_code') String semesterCode,
      @JsonKey(name: 'course_code') String courseCode,
      @JsonKey(name: 'course_name') String? courseName,
      String? section,
      @JsonKey(name: 'quiz_strategy') String quizStrategy,
      @JsonKey(name: 'quiz_n') int quizN,
      @JsonKey(name: 'short_quiz_n') int shortQuizN,
      @JsonKey(name: 'dist_mid') double distMid,
      @JsonKey(name: 'dist_final') double distFinal,
      @JsonKey(name: 'dist_quiz') double distQuiz,
      @JsonKey(name: 'dist_short_quiz') double? distShortQuiz,
      @JsonKey(name: 'dist_assignment') double? distAssignment,
      @JsonKey(name: 'dist_presentation') double? distPresentation,
      @JsonKey(name: 'dist_viva') double? distViva,
      @JsonKey(name: 'dist_attendance') double? distAttendance,
      @JsonKey(name: 'dist_lab') double? distLab,
      @JsonKey(name: 'dist_project') double? distProject,
      @JsonKey(name: 'dist_term_paper') double? distTermPaper,
      @JsonKey(name: 'dist_class_performance') double? distClassPerformance,
      @JsonKey(name: 'obt_mid') double? obtMid,
      @JsonKey(name: 'obt_final') double? obtFinal,
      @JsonKey(name: 'obt_assignment') double? obtAssignment,
      @JsonKey(name: 'obt_presentation') double? obtPresentation,
      @JsonKey(name: 'obt_viva') double? obtViva,
      @JsonKey(name: 'obt_attendance') double? obtAttendance,
      @JsonKey(name: 'obt_lab') double? obtLab,
      @JsonKey(name: 'obt_project') double? obtProject,
      @JsonKey(name: 'obt_term_paper') double? obtTermPaper,
      @JsonKey(name: 'obt_class_performance') double? obtClassPerformance,
      @JsonKey(name: 'obt_quizzes') List<double> obtQuizzes,
      @JsonKey(name: 'obt_short_quizzes') List<double> obtShortQuizzes,
      @JsonKey(name: 'grade_goal') String? gradeGoal,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$SemesterCourseMarksCopyWithImpl<$Res>
    implements _$SemesterCourseMarksCopyWith<$Res> {
  __$SemesterCourseMarksCopyWithImpl(this._self, this._then);

  final _SemesterCourseMarks _self;
  final $Res Function(_SemesterCourseMarks) _then;

  /// Create a copy of SemesterCourseMarks
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? semesterCode = null,
    Object? courseCode = null,
    Object? courseName = freezed,
    Object? section = freezed,
    Object? quizStrategy = null,
    Object? quizN = null,
    Object? shortQuizN = null,
    Object? distMid = null,
    Object? distFinal = null,
    Object? distQuiz = null,
    Object? distShortQuiz = freezed,
    Object? distAssignment = freezed,
    Object? distPresentation = freezed,
    Object? distViva = freezed,
    Object? distAttendance = freezed,
    Object? distLab = freezed,
    Object? distProject = freezed,
    Object? distTermPaper = freezed,
    Object? distClassPerformance = freezed,
    Object? obtMid = freezed,
    Object? obtFinal = freezed,
    Object? obtAssignment = freezed,
    Object? obtPresentation = freezed,
    Object? obtViva = freezed,
    Object? obtAttendance = freezed,
    Object? obtLab = freezed,
    Object? obtProject = freezed,
    Object? obtTermPaper = freezed,
    Object? obtClassPerformance = freezed,
    Object? obtQuizzes = null,
    Object? obtShortQuizzes = null,
    Object? gradeGoal = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_SemesterCourseMarks(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      semesterCode: null == semesterCode
          ? _self.semesterCode
          : semesterCode // ignore: cast_nullable_to_non_nullable
              as String,
      courseCode: null == courseCode
          ? _self.courseCode
          : courseCode // ignore: cast_nullable_to_non_nullable
              as String,
      courseName: freezed == courseName
          ? _self.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String?,
      section: freezed == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String?,
      quizStrategy: null == quizStrategy
          ? _self.quizStrategy
          : quizStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      quizN: null == quizN
          ? _self.quizN
          : quizN // ignore: cast_nullable_to_non_nullable
              as int,
      shortQuizN: null == shortQuizN
          ? _self.shortQuizN
          : shortQuizN // ignore: cast_nullable_to_non_nullable
              as int,
      distMid: null == distMid
          ? _self.distMid
          : distMid // ignore: cast_nullable_to_non_nullable
              as double,
      distFinal: null == distFinal
          ? _self.distFinal
          : distFinal // ignore: cast_nullable_to_non_nullable
              as double,
      distQuiz: null == distQuiz
          ? _self.distQuiz
          : distQuiz // ignore: cast_nullable_to_non_nullable
              as double,
      distShortQuiz: freezed == distShortQuiz
          ? _self.distShortQuiz
          : distShortQuiz // ignore: cast_nullable_to_non_nullable
              as double?,
      distAssignment: freezed == distAssignment
          ? _self.distAssignment
          : distAssignment // ignore: cast_nullable_to_non_nullable
              as double?,
      distPresentation: freezed == distPresentation
          ? _self.distPresentation
          : distPresentation // ignore: cast_nullable_to_non_nullable
              as double?,
      distViva: freezed == distViva
          ? _self.distViva
          : distViva // ignore: cast_nullable_to_non_nullable
              as double?,
      distAttendance: freezed == distAttendance
          ? _self.distAttendance
          : distAttendance // ignore: cast_nullable_to_non_nullable
              as double?,
      distLab: freezed == distLab
          ? _self.distLab
          : distLab // ignore: cast_nullable_to_non_nullable
              as double?,
      distProject: freezed == distProject
          ? _self.distProject
          : distProject // ignore: cast_nullable_to_non_nullable
              as double?,
      distTermPaper: freezed == distTermPaper
          ? _self.distTermPaper
          : distTermPaper // ignore: cast_nullable_to_non_nullable
              as double?,
      distClassPerformance: freezed == distClassPerformance
          ? _self.distClassPerformance
          : distClassPerformance // ignore: cast_nullable_to_non_nullable
              as double?,
      obtMid: freezed == obtMid
          ? _self.obtMid
          : obtMid // ignore: cast_nullable_to_non_nullable
              as double?,
      obtFinal: freezed == obtFinal
          ? _self.obtFinal
          : obtFinal // ignore: cast_nullable_to_non_nullable
              as double?,
      obtAssignment: freezed == obtAssignment
          ? _self.obtAssignment
          : obtAssignment // ignore: cast_nullable_to_non_nullable
              as double?,
      obtPresentation: freezed == obtPresentation
          ? _self.obtPresentation
          : obtPresentation // ignore: cast_nullable_to_non_nullable
              as double?,
      obtViva: freezed == obtViva
          ? _self.obtViva
          : obtViva // ignore: cast_nullable_to_non_nullable
              as double?,
      obtAttendance: freezed == obtAttendance
          ? _self.obtAttendance
          : obtAttendance // ignore: cast_nullable_to_non_nullable
              as double?,
      obtLab: freezed == obtLab
          ? _self.obtLab
          : obtLab // ignore: cast_nullable_to_non_nullable
              as double?,
      obtProject: freezed == obtProject
          ? _self.obtProject
          : obtProject // ignore: cast_nullable_to_non_nullable
              as double?,
      obtTermPaper: freezed == obtTermPaper
          ? _self.obtTermPaper
          : obtTermPaper // ignore: cast_nullable_to_non_nullable
              as double?,
      obtClassPerformance: freezed == obtClassPerformance
          ? _self.obtClassPerformance
          : obtClassPerformance // ignore: cast_nullable_to_non_nullable
              as double?,
      obtQuizzes: null == obtQuizzes
          ? _self._obtQuizzes
          : obtQuizzes // ignore: cast_nullable_to_non_nullable
              as List<double>,
      obtShortQuizzes: null == obtShortQuizzes
          ? _self._obtShortQuizzes
          : obtShortQuizzes // ignore: cast_nullable_to_non_nullable
              as List<double>,
      gradeGoal: freezed == gradeGoal
          ? _self.gradeGoal
          : gradeGoal // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
