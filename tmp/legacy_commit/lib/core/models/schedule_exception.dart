import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_exception.freezed.dart';
part 'schedule_exception.g.dart';

@freezed
class ScheduleException with _$ScheduleException {
  const factory ScheduleException({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String type,
    required DateTime date,
    @JsonKey(name: 'course_code') String? courseCode,
    @JsonKey(name: 'course_name') String? courseName,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    String? room,
    Map<String, dynamic>? metadata,
  }) = _ScheduleException;

  factory ScheduleException.fromJson(Map<String, dynamic> json) =>
      _$ScheduleExceptionFromJson(json);
}
