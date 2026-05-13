// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_course_marks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SemesterCourseMarksImpl _$$SemesterCourseMarksImplFromJson(
        Map<String, dynamic> json) =>
    _$SemesterCourseMarksImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      semesterCode: json['semester_code'] as String,
      courseCode: json['course_code'] as String,
      courseName: json['course_name'] as String?,
      section: json['section'] as String?,
      quizStrategy: json['quiz_strategy'] as String? ?? 'bestN',
      quizN: (json['quiz_n'] as num?)?.toInt() ?? 2,
      shortQuizN: (json['short_quiz_n'] as num?)?.toInt() ?? 2,
      distMid: (json['dist_mid'] as num?)?.toDouble() ?? 30.0,
      distFinal: (json['dist_final'] as num?)?.toDouble() ?? 40.0,
      distQuiz: (json['dist_quiz'] as num?)?.toDouble() ?? 10.0,
      distShortQuiz: (json['dist_short_quiz'] as num?)?.toDouble(),
      distAssignment: (json['dist_assignment'] as num?)?.toDouble(),
      distPresentation: (json['dist_presentation'] as num?)?.toDouble(),
      distViva: (json['dist_viva'] as num?)?.toDouble(),
      distAttendance: (json['dist_attendance'] as num?)?.toDouble(),
      distLab: (json['dist_lab'] as num?)?.toDouble(),
      distProject: (json['dist_project'] as num?)?.toDouble(),
      distTermPaper: (json['dist_term_paper'] as num?)?.toDouble(),
      distClassPerformance:
          (json['dist_class_performance'] as num?)?.toDouble(),
      obtMid: (json['obt_mid'] as num?)?.toDouble(),
      obtFinal: (json['obt_final'] as num?)?.toDouble(),
      obtAssignment: (json['obt_assignment'] as num?)?.toDouble(),
      obtPresentation: (json['obt_presentation'] as num?)?.toDouble(),
      obtViva: (json['obt_viva'] as num?)?.toDouble(),
      obtAttendance: (json['obt_attendance'] as num?)?.toDouble(),
      obtLab: (json['obt_lab'] as num?)?.toDouble(),
      obtProject: (json['obt_project'] as num?)?.toDouble(),
      obtTermPaper: (json['obt_term_paper'] as num?)?.toDouble(),
      obtClassPerformance: (json['obt_class_performance'] as num?)?.toDouble(),
      obtQuizzes: (json['obt_quizzes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      obtShortQuizzes: (json['obt_short_quizzes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      gradeGoal: json['grade_goal'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$SemesterCourseMarksImplToJson(
        _$SemesterCourseMarksImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'semester_code': instance.semesterCode,
      'course_code': instance.courseCode,
      'course_name': instance.courseName,
      'section': instance.section,
      'quiz_strategy': instance.quizStrategy,
      'quiz_n': instance.quizN,
      'short_quiz_n': instance.shortQuizN,
      'dist_mid': instance.distMid,
      'dist_final': instance.distFinal,
      'dist_quiz': instance.distQuiz,
      'dist_short_quiz': instance.distShortQuiz,
      'dist_assignment': instance.distAssignment,
      'dist_presentation': instance.distPresentation,
      'dist_viva': instance.distViva,
      'dist_attendance': instance.distAttendance,
      'dist_lab': instance.distLab,
      'dist_project': instance.distProject,
      'dist_term_paper': instance.distTermPaper,
      'dist_class_performance': instance.distClassPerformance,
      'obt_mid': instance.obtMid,
      'obt_final': instance.obtFinal,
      'obt_assignment': instance.obtAssignment,
      'obt_presentation': instance.obtPresentation,
      'obt_viva': instance.obtViva,
      'obt_attendance': instance.obtAttendance,
      'obt_lab': instance.obtLab,
      'obt_project': instance.obtProject,
      'obt_term_paper': instance.obtTermPaper,
      'obt_class_performance': instance.obtClassPerformance,
      'obt_quizzes': instance.obtQuizzes,
      'obt_short_quizzes': instance.obtShortQuizzes,
      'grade_goal': instance.gradeGoal,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
