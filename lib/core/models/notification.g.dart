// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String,
      body: json['body'] as String,
      triggerAt: json['trigger_at'] == null
          ? null
          : DateTime.parse(json['trigger_at'] as String),
      isDispatched: json['is_dispatched'] as bool? ?? true,
      isRead: json['is_read'] as bool? ?? false,
      payload: json['payload'] as Map<String, dynamic>?,
      alertKey: json['alert_key'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'trigger_at': instance.triggerAt?.toIso8601String(),
      'is_dispatched': instance.isDispatched,
      'is_read': instance.isRead,
      'payload': instance.payload,
      'alert_key': instance.alertKey,
      'created_at': instance.createdAt?.toIso8601String(),
    };
