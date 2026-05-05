
class SavedSchedule {
  final String id;
  final String userId;
  final String semesterCode;
  final Map<String, dynamic> combinationData;
  final DateTime createdAt;

  SavedSchedule({
    required this.id,
    required this.userId,
    required this.semesterCode,
    required this.combinationData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'semester_code': semesterCode,
      'combination_data': combinationData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedSchedule.fromJson(Map<String, dynamic> json) {
    return SavedSchedule(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      semesterCode: json['semester_code'] as String,
      combinationData: json['combination_data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
