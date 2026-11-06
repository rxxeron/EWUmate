// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Notification {
  String get id;
  @JsonKey(name: 'user_id')
  String get userId;
  String get type;
  String get title;
  String get body;
  @JsonKey(name: 'trigger_at')
  DateTime? get triggerAt;
  @JsonKey(name: 'is_dispatched')
  bool get isDispatched;
  @JsonKey(name: 'is_read')
  bool get isRead;
  Map<String, dynamic>? get payload;
  @JsonKey(name: 'alert_key')
  String? get alertKey;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NotificationCopyWith<Notification> get copyWith =>
      _$NotificationCopyWithImpl<Notification>(
          this as Notification, _$identity);

  /// Serializes this Notification to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Notification;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Notification &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.type, _this.type) || other.type == _this.type) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.body, _this.body) || other.body == _this.body) &&
            (identical(other.triggerAt, _this.triggerAt) ||
                other.triggerAt == _this.triggerAt) &&
            (identical(other.isDispatched, _this.isDispatched) ||
                other.isDispatched == _this.isDispatched) &&
            (identical(other.isRead, _this.isRead) ||
                other.isRead == _this.isRead) &&
            const DeepCollectionEquality()
                .equals(other.payload, _this.payload) &&
            (identical(other.alertKey, _this.alertKey) ||
                other.alertKey == _this.alertKey) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Notification;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.userId,
        _this.type,
        _this.title,
        _this.body,
        _this.triggerAt,
        _this.isDispatched,
        _this.isRead,
        const DeepCollectionEquality().hash(_this.payload),
        _this.alertKey,
        _this.createdAt);
  }

  @override
  String toString() {
    final _this = this as Notification;
    return 'Notification(id: ${_this.id}, userId: ${_this.userId}, type: ${_this.type}, title: ${_this.title}, body: ${_this.body}, triggerAt: ${_this.triggerAt}, isDispatched: ${_this.isDispatched}, isRead: ${_this.isRead}, payload: ${_this.payload}, alertKey: ${_this.alertKey}, createdAt: ${_this.createdAt})';
  }
}

/// @nodoc
abstract mixin class $NotificationCopyWith<$Res> {
  factory $NotificationCopyWith(
          Notification value, $Res Function(Notification) _then) =
      _$NotificationCopyWithImpl;
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
class _$NotificationCopyWithImpl<$Res> implements $NotificationCopyWith<$Res> {
  _$NotificationCopyWithImpl(this._self, this._then);

  final Notification _self;
  final $Res Function(Notification) _then;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(Notification(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _self.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      triggerAt: freezed == triggerAt
          ? _self.triggerAt
          : triggerAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isDispatched: null == isDispatched
          ? _self.isDispatched
          : isDispatched // ignore: cast_nullable_to_non_nullable
              as bool,
      isRead: null == isRead
          ? _self.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      payload: freezed == payload
          ? _self.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      alertKey: freezed == alertKey
          ? _self.alertKey
          : alertKey // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Notification].
extension NotificationPatterns on Notification {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Notification value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Notification() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Notification value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Notification():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Notification value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Notification() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            @JsonKey(name: 'user_id') String userId,
            String type,
            String title,
            String body,
            @JsonKey(name: 'trigger_at') DateTime? triggerAt,
            @JsonKey(name: 'is_dispatched') bool isDispatched,
            @JsonKey(name: 'is_read') bool isRead,
            Map<String, dynamic>? payload,
            @JsonKey(name: 'alert_key') String? alertKey,
            @JsonKey(name: 'created_at') DateTime? createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Notification() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.type,
            _that.title,
            _that.body,
            _that.triggerAt,
            _that.isDispatched,
            _that.isRead,
            _that.payload,
            _that.alertKey,
            _that.createdAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            @JsonKey(name: 'user_id') String userId,
            String type,
            String title,
            String body,
            @JsonKey(name: 'trigger_at') DateTime? triggerAt,
            @JsonKey(name: 'is_dispatched') bool isDispatched,
            @JsonKey(name: 'is_read') bool isRead,
            Map<String, dynamic>? payload,
            @JsonKey(name: 'alert_key') String? alertKey,
            @JsonKey(name: 'created_at') DateTime? createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Notification():
        return $default(
            _that.id,
            _that.userId,
            _that.type,
            _that.title,
            _that.body,
            _that.triggerAt,
            _that.isDispatched,
            _that.isRead,
            _that.payload,
            _that.alertKey,
            _that.createdAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            @JsonKey(name: 'user_id') String userId,
            String type,
            String title,
            String body,
            @JsonKey(name: 'trigger_at') DateTime? triggerAt,
            @JsonKey(name: 'is_dispatched') bool isDispatched,
            @JsonKey(name: 'is_read') bool isRead,
            Map<String, dynamic>? payload,
            @JsonKey(name: 'alert_key') String? alertKey,
            @JsonKey(name: 'created_at') DateTime? createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Notification() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.type,
            _that.title,
            _that.body,
            _that.triggerAt,
            _that.isDispatched,
            _that.isRead,
            _that.payload,
            _that.alertKey,
            _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Notification implements Notification {
  const _Notification(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      this.type = 'system',
      required this.title,
      required this.body,
      @JsonKey(name: 'trigger_at') this.triggerAt,
      @JsonKey(name: 'is_dispatched') this.isDispatched = true,
      @JsonKey(name: 'is_read') this.isRead = false,
      Map<String, dynamic>? payload,
      @JsonKey(name: 'alert_key') this.alertKey,
      @JsonKey(name: 'created_at') this.createdAt})
      : _payload = payload;
  factory _Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);

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

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NotificationCopyWith<_Notification> get copyWith =>
      __$NotificationCopyWithImpl<_Notification>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NotificationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Notification &&
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
            const DeepCollectionEquality().equals(other.payload, _payload) &&
            (identical(other.alertKey, alertKey) ||
                other.alertKey == alertKey) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
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
  }

  @override
  String toString() {
    return 'Notification(id: $id, userId: $userId, type: $type, title: $title, body: $body, triggerAt: $triggerAt, isDispatched: $isDispatched, isRead: $isRead, payload: $payload, alertKey: $alertKey, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$NotificationCopyWith<$Res>
    implements $NotificationCopyWith<$Res> {
  factory _$NotificationCopyWith(
          _Notification value, $Res Function(_Notification) _then) =
      __$NotificationCopyWithImpl;
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
class __$NotificationCopyWithImpl<$Res>
    implements _$NotificationCopyWith<$Res> {
  __$NotificationCopyWithImpl(this._self, this._then);

  final _Notification _self;
  final $Res Function(_Notification) _then;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_Notification(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _self.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      triggerAt: freezed == triggerAt
          ? _self.triggerAt
          : triggerAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isDispatched: null == isDispatched
          ? _self.isDispatched
          : isDispatched // ignore: cast_nullable_to_non_nullable
              as bool,
      isRead: null == isRead
          ? _self.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      payload: freezed == payload
          ? _self._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      alertKey: freezed == alertKey
          ? _self.alertKey
          : alertKey // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
