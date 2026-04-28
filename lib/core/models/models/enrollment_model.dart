class Enrollment {
  final String id;
  final String userId;
  final String semesterCode;
  final String courseCode;
  final String? sectionId;

  Enrollment({
    required this.id,
    required this.userId,
    required this.semesterCode,
    required this.courseCode,
    this.sectionId,
  });

  factory Enrollment.fromSupabase(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      semesterCode: map['semester_code']?.toString() ?? '',
      courseCode: map['course_code']?.toString() ?? '',
      sectionId: map['section_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'semester_code': semesterCode,
      'course_code': courseCode,
      'section_id': sectionId,
    };
  }
}
