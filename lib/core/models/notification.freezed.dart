// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Notification _$NotificationFromJson(Map<String, dynamic> json) {
  return _Notification.fromJson(json);
}

/// @nodoc
mixin _$Notification {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(name: 'trigger_at')
  DateTime? get triggerAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_dispatched')
  bool get isDispatched => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_read')
  bool get isRead => throw _privateConstructorUsedError;
  Map<String, dynamic>? get payload => throw _privateConstructorUsedError;
  @JsonKey(name: 'alert_key')
  String? get alertKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationCopyWith<Notification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCopyWith<$Res> {
  factory $NotificationCopyWith(
          Notification value, $Res Function(Notification) then) =
      _$NotificationCopyWithImpl<$Res, Notification>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String type,
      String title,
      String body,
      @JsonKey(name: 'trigger_at') DateTime? triggerAt,
      @JsonKey(name: 'is_dispatched') bool isDispatched,
      @JsonKey(name: 'is_read') bool isRead,
      Map<String, dynamic>? payload,
      @JsonKey(name: 'alert_key') String? alertKey,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$NotificationCopyWithImpl<$Res, $Val extends Notification>
    implements $NotificationCopyWith<$Res> {
  _$NotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? title = null,
    Object? body = null,
    Object? triggerAt = freezed,
    Object? isDispatched = null,
    Object? isRead = null,
    Object? payload = freezed,
    Object? alertKey = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      triggerAt: freezed == triggerAt
          ? _value.triggerAt
          : triggerAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isDispatched: null == isDispatched
          ? _value.isDispatched
          : isDispatched // ignore: cast_nullable_to_non_nullable
              as bool,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      payload: freezed == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      alertKey: freezed == alertKey
          ? _value.alertKey
          : alertKey // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationImplCopyWith<$Res>
    implements $NotificationCopyWith<$Res> {
  factory _$$NotificationImplCopyWith(
          _$NotificationImpl value, $Res Function(_$NotificationImpl) then) =
      __$$NotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String type,
      String title,
      String body,
      @JsonKey(name: 'trigger_at') DateTime? triggerAt,
      @JsonKey(name: 'is_dispatched') bool isDispatched,
      @JsonKey(name: 'is_read') bool isRead,
      Map<String, dynamic>? payload,
      @JsonKey(name: 'alert_key') String? alertKey,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$NotificationImplCopyWithImpl<$Res>
    extends _$NotificationCopyWithImpl<$Res, _$NotificationImpl>
    implements _$$NotificationImplCopyWith<$Res> {
  __$$NotificationImplCopyWithImpl(
      _$NotificationImpl _value, $Res Function(_$NotificationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? title = null,
    Object? body = null,
    Object? triggerAt = freezed,
    Object? isDispatched = null,
    Object? isRead = null,
    Object? payload = freezed,
    Object? alertKey = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$NotificationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      triggerAt: freezed == triggerAt
          ? _value.triggerAt
          : triggerAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isDispatched: null == isDispatched
          ? _value.isDispatched
          : isDispatched // ignore: cast_nullable_to_non_nullable
              as bool,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      payload: freezed == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      alertKey: freezed == alertKey
          ? _value.alertKey
          : alertKey // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationImpl implements _Notification {
  const _$NotificationImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      this.type = 'system',
      required this.title,
      required this.body,
      @JsonKey(name: 'trigger_at') this.triggerAt,
      @JsonKey(name: 'is_dispatched') this.isDispatched = true,
      @JsonKey(name: 'is_read') this.isRead = false,
      final Map<String, dynamic>? payload,
      @JsonKey(name: 'alert_key') this.alertKey,
      @JsonKey(name: 'created_at') this.createdAt})
      : _payload = payload;

  factory _$NotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey()
  final String type;
  @override
  final String title;
  @override
  final String body;
  @override
  @JsonKey(name: 'trigger_at')
  final DateTime? triggerAt;
  @override
  @JsonKey(name: 'is_dispatched')
  final bool isDispatched;
  @override
  @JsonKey(name: 'is_read')
  final bool isRead;
  final Map<String, dynamic>? _payload;
  @override
  Map<String, dynamic>? get payload {
    final value = _payload;
    if (value == null) return null;
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'alert_key')
  final String? alertKey;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Notification(id: $id, userId: $userId, type: $type, title: $title, body: $body, triggerAt: $triggerAt, isDispatched: $isDispatched, isRead: $isRead, payload: $payload, alertKey: $alertKey, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.triggerAt, triggerAt) ||
                other.triggerAt == triggerAt) &&
            (identical(other.isDispatched, isDispatched) ||
                other.isDispatched == isDispatched) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.alertKey, alertKey) ||
                other.alertKey == alertKey) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      type,
      title,
      body,
      triggerAt,
      isDispatched,
      isRead,
      const DeepCollectionEquality().hash(_payload),
      alertKey,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      __$$NotificationImplCopyWithImpl<_$NotificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationImplToJson(
      this,
    );
  }
}

abstract class _Notification implements Notification {
  const factory _Notification(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          final String type,
          required final String title,
          required final String body,
          @JsonKey(name: 'trigger_at') final DateTime? triggerAt,
          @JsonKey(name: 'is_dispatched') final bool isDispatched,
          @JsonKey(name: 'is_read') final bool isRead,
          final Map<String, dynamic>? payload,
          @JsonKey(name: 'alert_key') final String? alertKey,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$NotificationImpl;

  factory _Notification.fromJson(Map<String, dynamic> json) =
      _$NotificationImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  String get type;
  @override
  String get title;
  @override
  String get body;
  @override
  @JsonKey(name: 'trigger_at')
  DateTime? get triggerAt;
  @override
  @JsonKey(name: 'is_dispatched')
  bool get isDispatched;
  @override
  @JsonKey(name: 'is_read')
  bool get isRead;
  @override
  Map<String, dynamic>? get payload;
  @override
  @JsonKey(name: 'alert_key')
  String? get alertKey;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
