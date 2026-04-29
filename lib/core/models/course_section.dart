import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_section.freezed.dart';
part 'course_section.g.dart';

@freezed
class CourseSession with _$CourseSession {
  const factory CourseSession({
    @Default('Theory') String type,
    @Default('') String day,
    @JsonKey(name: 'start_time') @Default('') String startTime,
    @JsonKey(name: 'end_time') @Default('') String endTime,
    @Default('') String room,
    @Default('') String faculty,
  }) = _CourseSession;

  factory CourseSession.fromJson(Map<String, dynamic> json) =>
      _$CourseSessionFromJson(json);
}

@freezed
class CourseSection with _$CourseSection {
  const factory CourseSection({
    required String id,
    @Default('') String code,
    @JsonKey(name: 'course_name') @Default('') String courseName,
    @JsonKey(name: 'faculty_initials') @Default('') String facultyInitials,
    @Default('') String section,
    @Default('') String capacity,
    @Default('3.0') String credits,
    @Default('') String semester,
    @Default([]) List<CourseSession> sessions,
    @JsonKey(name: 'doc_id') @Default('') String docId,
  }) = _CourseSection;

  factory CourseSection.fromJson(Map<String, dynamic> json) =>
      _$CourseSectionFromJson(json);
}
