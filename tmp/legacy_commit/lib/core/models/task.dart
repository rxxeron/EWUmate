import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    @JsonKey(name: 'course_code') String? courseCode,
    @JsonKey(name: 'course_name') String? courseName,
    @JsonKey(name: 'assign_date') DateTime? assignDate,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'submission_type') String? submissionType,
    String? type,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'is_missed') @Default(false) bool isMissed,
    @JsonKey(name: 'semester_code') String? semesterCode,
    String? track,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
