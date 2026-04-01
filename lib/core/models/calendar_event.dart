import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event.freezed.dart';
part 'calendar_event.g.dart';

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required String id,
    @JsonKey(name: 'event_date') required DateTime eventDate,
    required String title,
    required String type,
    @JsonKey(name: 'target_track') String? targetTrack,
  }) = _CalendarEvent;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);
}
