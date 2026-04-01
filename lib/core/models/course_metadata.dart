import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_metadata.freezed.dart';
part 'course_metadata.g.dart';

@freezed
class CourseMetadata with _$CourseMetadata {
  const factory CourseMetadata({
    required String code,
    required String name,
    @JsonKey(name: 'credit_val') required double creditVal,
  }) = _CourseMetadata;

  factory CourseMetadata.fromJson(Map<String, dynamic> json) =>
      _$CourseMetadataFromJson(json);
}
