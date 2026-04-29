import 'package:freezed_annotation/freezed_annotation.dart';

part 'program.freezed.dart';
part 'program.g.dart';

@freezed
class Program with _$Program {
  const factory Program({
    @JsonKey(name: 'program_code') required String programCode,
    required String name,
    required String track,
    @JsonKey(name: 'total_degree_credits')
    @Default(130.0)
    double totalDegreeCredits,
    @JsonKey(name: 'department_name') String? departmentName,
  }) = _Program;

  factory Program.fromJson(Map<String, dynamic> json) =>
      _$ProgramFromJson(json);
}
