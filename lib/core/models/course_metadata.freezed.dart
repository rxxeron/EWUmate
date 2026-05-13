// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CourseMetadata _$CourseMetadataFromJson(Map<String, dynamic> json) {
  return _CourseMetadata.fromJson(json);
}

/// @nodoc
mixin _$CourseMetadata {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_val')
  double get creditVal => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CourseMetadataCopyWith<CourseMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CourseMetadataCopyWith<$Res> {
  factory $CourseMetadataCopyWith(
          CourseMetadata value, $Res Function(CourseMetadata) then) =
      _$CourseMetadataCopyWithImpl<$Res, CourseMetadata>;
  @useResult
  $Res call(
      {String code,
      String name,
      @JsonKey(name: 'credit_val') double creditVal});
}

/// @nodoc
class _$CourseMetadataCopyWithImpl<$Res, $Val extends CourseMetadata>
    implements $CourseMetadataCopyWith<$Res> {
  _$CourseMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? creditVal = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      creditVal: null == creditVal
          ? _value.creditVal
          : creditVal // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CourseMetadataImplCopyWith<$Res>
    implements $CourseMetadataCopyWith<$Res> {
  factory _$$CourseMetadataImplCopyWith(_$CourseMetadataImpl value,
          $Res Function(_$CourseMetadataImpl) then) =
      __$$CourseMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code,
      String name,
      @JsonKey(name: 'credit_val') double creditVal});
}

/// @nodoc
class __$$CourseMetadataImplCopyWithImpl<$Res>
    extends _$CourseMetadataCopyWithImpl<$Res, _$CourseMetadataImpl>
    implements _$$CourseMetadataImplCopyWith<$Res> {
  __$$CourseMetadataImplCopyWithImpl(
      _$CourseMetadataImpl _value, $Res Function(_$CourseMetadataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? creditVal = null,
  }) {
    return _then(_$CourseMetadataImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      creditVal: null == creditVal
          ? _value.creditVal
          : creditVal // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CourseMetadataImpl implements _CourseMetadata {
  const _$CourseMetadataImpl(
      {required this.code,
      required this.name,
      @JsonKey(name: 'credit_val') required this.creditVal});

  factory _$CourseMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$CourseMetadataImplFromJson(json);

  @override
  final String code;
  @override
  final String name;
  @override
  @JsonKey(name: 'credit_val')
  final double creditVal;

  @override
  String toString() {
    return 'CourseMetadata(code: $code, name: $name, creditVal: $creditVal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CourseMetadataImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.creditVal, creditVal) ||
                other.creditVal == creditVal));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, code, name, creditVal);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CourseMetadataImplCopyWith<_$CourseMetadataImpl> get copyWith =>
      __$$CourseMetadataImplCopyWithImpl<_$CourseMetadataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CourseMetadataImplToJson(
      this,
    );
  }
}

abstract class _CourseMetadata implements CourseMetadata {
  const factory _CourseMetadata(
          {required final String code,
          required final String name,
          @JsonKey(name: 'credit_val') required final double creditVal}) =
      _$CourseMetadataImpl;

  factory _CourseMetadata.fromJson(Map<String, dynamic> json) =
      _$CourseMetadataImpl.fromJson;

  @override
  String get code;
  @override
  String get name;
  @override
  @JsonKey(name: 'credit_val')
  double get creditVal;
  @override
  @JsonKey(ignore: true)
  _$$CourseMetadataImplCopyWith<_$CourseMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
