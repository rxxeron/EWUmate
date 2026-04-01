import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @Default('system') String type,
    required String title,
    required String body,
    @JsonKey(name: 'trigger_at') DateTime? triggerAt,
    @JsonKey(name: 'is_dispatched') @Default(true) bool isDispatched,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    Map<String, dynamic>? payload,
    @JsonKey(name: 'alert_key') String? alertKey,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
}
