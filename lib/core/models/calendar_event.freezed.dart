// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarEvent {
  String get id;
  @JsonKey(name: 'event_date')
  DateTime get eventDate;
  String get title;
  String get type;
  @JsonKey(name: 'target_track')
  String? get targetTrack;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CalendarEventCopyWith<CalendarEvent> get copyWith =>
      _$CalendarEventCopyWithImpl<CalendarEvent>(
          this as CalendarEvent, _$identity);

  /// Serializes this CalendarEvent to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as CalendarEvent;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CalendarEvent &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.eventDate, _this.eventDate) ||
                other.eventDate == _this.eventDate) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.type, _this.type) || other.type == _this.type) &&
            (identical(other.targetTrack, _this.targetTrack) ||
                other.targetTrack == _this.targetTrack));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as CalendarEvent;
    return Object.hash(runtimeType, _this.id, _this.eventDate, _this.title,
        _this.type, _this.targetTrack);
  }

  @override
  String toString() {
    final _this = this as CalendarEvent;
    return 'CalendarEvent(id: ${_this.id}, eventDate: ${_this.eventDate}, title: ${_this.title}, type: ${_this.type}, targetTrack: ${_this.targetTrack})';
  }
}

/// @nodoc
abstract mixin class $CalendarEventCopyWith<$Res> {
  factory $CalendarEventCopyWith(
          CalendarEvent value, $Res Function(CalendarEvent) _then) =
      _$CalendarEventCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'event_date') DateTime eventDate,
      String title,
      String type,
      @JsonKey(name: 'target_track') String? targetTrack});
}

/// @nodoc
class _$CalendarEventCopyWithImpl<$Res>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._self, this._then);

  final CalendarEvent _self;
  final $Res Function(CalendarEvent) _then;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventDate = null,
    Object? title = null,
    Object? type = null,
    Object? targetTrack = freezed,
  }) {
    return _then(CalendarEvent(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventDate: null == eventDate
          ? _self.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetTrack: freezed == targetTrack
          ? _self.targetTrack
          : targetTrack // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [CalendarEvent].
extension CalendarEventPatterns on CalendarEvent {
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
    TResult Function(_CalendarEvent value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CalendarEvent() when $default != null:
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
    TResult Function(_CalendarEvent value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CalendarEvent():
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
    TResult? Function(_CalendarEvent value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CalendarEvent() when $default != null:
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
            @JsonKey(name: 'event_date') DateTime eventDate,
            String title,
            String type,
            @JsonKey(name: 'target_track') String? targetTrack)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CalendarEvent() when $default != null:
        return $default(_that.id, _that.eventDate, _that.title, _that.type,
            _that.targetTrack);
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
            @JsonKey(name: 'event_date') DateTime eventDate,
            String title,
            String type,
            @JsonKey(name: 'target_track') String? targetTrack)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CalendarEvent():
        return $default(_that.id, _that.eventDate, _that.title, _that.type,
            _that.targetTrack);
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
            @JsonKey(name: 'event_date') DateTime eventDate,
            String title,
            String type,
            @JsonKey(name: 'target_track') String? targetTrack)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CalendarEvent() when $default != null:
        return $default(_that.id, _that.eventDate, _that.title, _that.type,
            _that.targetTrack);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CalendarEvent implements CalendarEvent {
  const _CalendarEvent(
      {required this.id,
      @JsonKey(name: 'event_date') required this.eventDate,
      required this.title,
      required this.type,
      @JsonKey(name: 'target_track') this.targetTrack});
  factory _CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'event_date')
  final DateTime eventDate;
  @override
  final String title;
  @override
  final String type;
  @override
  @JsonKey(name: 'target_track')
  final String? targetTrack;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CalendarEventCopyWith<_CalendarEvent> get copyWith =>
      __$CalendarEventCopyWithImpl<_CalendarEvent>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CalendarEventToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CalendarEvent &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.targetTrack, targetTrack) ||
                other.targetTrack == targetTrack));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, eventDate, title, type, targetTrack);
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, eventDate: $eventDate, title: $title, type: $type, targetTrack: $targetTrack)';
  }
}

/// @nodoc
abstract mixin class _$CalendarEventCopyWith<$Res>
    implements $CalendarEventCopyWith<$Res> {
  factory _$CalendarEventCopyWith(
          _CalendarEvent value, $Res Function(_CalendarEvent) _then) =
      __$CalendarEventCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'event_date') DateTime eventDate,
      String title,
      String type,
      @JsonKey(name: 'target_track') String? targetTrack});
}

/// @nodoc
class __$CalendarEventCopyWithImpl<$Res>
    implements _$CalendarEventCopyWith<$Res> {
  __$CalendarEventCopyWithImpl(this._self, this._then);

  final _CalendarEvent _self;
  final $Res Function(_CalendarEvent) _then;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? eventDate = null,
    Object? title = null,
    Object? type = null,
    Object? targetTrack = freezed,
  }) {
    return _then(_CalendarEvent(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventDate: null == eventDate
          ? _self.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetTrack: freezed == targetTrack
          ? _self.targetTrack
          : targetTrack // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
