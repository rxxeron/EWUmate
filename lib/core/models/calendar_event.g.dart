// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    _CalendarEvent(
      id: json['id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      title: json['title'] as String,
      type: json['type'] as String,
      targetTrack: json['target_track'] as String?,
    );

Map<String, dynamic> _$CalendarEventToJson(_CalendarEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_date': instance.eventDate.toIso8601String(),
      'title': instance.title,
      'type': instance.type,
      'target_track': instance.targetTrack,
    };
