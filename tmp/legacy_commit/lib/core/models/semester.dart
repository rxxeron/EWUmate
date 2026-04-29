import 'package:freezed_annotation/freezed_annotation.dart';

part 'semester.freezed.dart';
part 'semester.g.dart';

@freezed
class Semester with _$Semester {
  const factory Semester({
    required String code,
    required String title,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Semester;

  factory Semester.fromJson(Map<String, dynamic> json) =>
      _$SemesterFromJson(json);
}
