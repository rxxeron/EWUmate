// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_course_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SemesterCourseStatsImpl _$$SemesterCourseStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$SemesterCourseStatsImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      semester: json['semester'] as String,
      courseCode: json['course_code'] as String,
      marksObtained: (json['marks_obtained'] as num?)?.toDouble(),
      totalPossible: (json['total_possible'] as num?)?.toDouble() ?? 100.0,
      gradeGoal: json['grade_goal'] as String?,
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$$SemesterCourseStatsImplToJson(
        _$SemesterCourseStatsImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'semester': instance.semester,
      'course_code': instance.courseCode,
      'marks_obtained': instance.marksObtained,
      'total_possible': instance.totalPossible,
      'grade_goal': instance.gradeGoal,
      'last_updated': instance.lastUpdated?.toIso8601String(),
    };
