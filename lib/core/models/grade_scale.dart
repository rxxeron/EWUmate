class GradeScale {
  final String grade;
  final double point;
  final double? minScore;
  final String? description;
  final String policy;

  GradeScale({
    required this.grade,
    required this.point,
    this.minScore,
    this.description,
    required this.policy,
  });

  factory GradeScale.fromJson(Map<String, dynamic> json) {
    return GradeScale(
      grade: json['grade'] as String,
      point: (json['point'] as num).toDouble(),
      minScore: json['min_score'] != null ? (json['min_score'] as num).toDouble() : null,
      description: json['description'] as String?,
      policy: json['policy'] as String? ?? 'modern',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'point': point,
      'min_score': minScore,
      'description': description,
      'policy': policy,
    };
  }
}
