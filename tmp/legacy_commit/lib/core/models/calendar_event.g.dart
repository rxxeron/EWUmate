// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CalendarEventImpl _$$CalendarEventImplFromJson(Map<String, dynamic> json) =>
    _$CalendarEventImpl(
      id: json['id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      title: json['title'] as String,
      type: json['type'] as String,
      targetTrack: json['target_track'] as String?,
    );

Map<String, dynamic> _$$CalendarEventImplToJson(_$CalendarEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_date': instance.eventDate.toIso8601String(),
      'title': instance.title,
      'type': instance.type,
      'target_track': instance.targetTrack,
    };
