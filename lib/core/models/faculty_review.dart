class FacultyReview {
  final String id;
  final String userId;
  final String facultyInitials;
  final String? facultyName;
  final String courseCode;
  final String semester;
  final String? semesterCode;
  final String status;
  final String? adminRejectionNote;
  final String deliveryType;
  final String? gradeReceived;
  final double clarityRating;
  final double gradingFairness;
  final double examAlignment;
  final double officeHoursAccessibility;
  final double attendanceStrictness;
  final String workloadLevel;
  final String slideReliance;
  final String quizFrequency;
  final String textbookNeed;
  final List<String> traits;
  final String? examPrepTips;
  final String? reviewNote;
  final bool wouldTakeAgain;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? studentName;
  final String? studentId;

  FacultyReview({
    required this.id,
    required this.userId,
    required this.facultyInitials,
    this.facultyName,
    required this.courseCode,
    required this.semester,
    this.semesterCode,
    required this.status,
    this.adminRejectionNote,
    this.deliveryType = 'theory',
    this.gradeReceived,
    required this.clarityRating,
    required this.gradingFairness,
    required this.examAlignment,
    required this.officeHoursAccessibility,
    required this.attendanceStrictness,
    this.workloadLevel = 'manageable',
    this.slideReliance = 'slides_with_whiteboard',
    this.quizFrequency = 'bi_weekly',
    this.textbookNeed = 'supplementary',
    this.traits = const [],
    this.examPrepTips,
    this.reviewNote,
    this.wouldTakeAgain = true,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.studentId,
  });

  double get averageRating =>
      (clarityRating +
          gradingFairness +
          examAlignment +
          officeHoursAccessibility +
          attendanceStrictness) /
      5.0;

  factory FacultyReview.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? profileMap;
    if (map['profiles'] is Map) {
      profileMap = Map<String, dynamic>.from(map['profiles']);
    }

    return FacultyReview(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      facultyInitials: (map['faculty_initials']?.toString() ?? '').toUpperCase(),
      facultyName: map['faculty_name']?.toString(),
      courseCode: (map['course_code']?.toString() ?? '').toUpperCase(),
      semester: map['semester']?.toString() ?? 'Summer 2026',
      semesterCode: map['semester_code']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      adminRejectionNote: map['admin_rejection_note']?.toString(),
      deliveryType: map['delivery_type']?.toString() ?? 'theory',
      gradeReceived: map['grade_received']?.toString(),
      clarityRating: (map['clarity_rating'] is num)
          ? (map['clarity_rating'] as num).toDouble()
          : double.tryParse(map['clarity_rating']?.toString() ?? '3.0') ?? 3.0,
      gradingFairness: (map['grading_fairness'] is num)
          ? (map['grading_fairness'] as num).toDouble()
          : double.tryParse(map['grading_fairness']?.toString() ?? '3.0') ?? 3.0,
      examAlignment: (map['exam_alignment'] is num)
          ? (map['exam_alignment'] as num).toDouble()
          : double.tryParse(map['exam_alignment']?.toString() ?? '3.0') ?? 3.0,
      officeHoursAccessibility: (map['office_hours_accessibility'] is num)
          ? (map['office_hours_accessibility'] as num).toDouble()
          : double.tryParse(map['office_hours_accessibility']?.toString() ?? '3.0') ?? 3.0,
      attendanceStrictness: (map['attendance_strictness'] is num)
          ? (map['attendance_strictness'] as num).toDouble()
          : double.tryParse(map['attendance_strictness']?.toString() ?? '3.0') ?? 3.0,
      workloadLevel: map['workload_level']?.toString() ?? 'manageable',
      slideReliance: map['slide_reliance']?.toString() ?? 'slides_with_whiteboard',
      quizFrequency: map['quiz_frequency']?.toString() ?? 'bi_weekly',
      textbookNeed: map['textbook_need']?.toString() ?? 'supplementary',
      traits: (map['traits'] is List)
          ? (map['traits'] as List).map((e) => e.toString()).toList()
          : [],
      examPrepTips: map['exam_prep_tips']?.toString(),
      reviewNote: map['review_note']?.toString(),
      wouldTakeAgain: map['would_take_again'] == true || map['would_take_again'] == null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
      studentName: profileMap?['full_name']?.toString(),
      studentId: profileMap?['student_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'faculty_initials': facultyInitials,
      'faculty_name': facultyName,
      'course_code': courseCode,
      'semester': semester,
      'semester_code': semesterCode,
      'status': status,
      'admin_rejection_note': adminRejectionNote,
      'delivery_type': deliveryType,
      'grade_received': gradeReceived,
      'clarity_rating': clarityRating,
      'grading_fairness': gradingFairness,
      'exam_alignment': examAlignment,
      'office_hours_accessibility': officeHoursAccessibility,
      'attendance_strictness': attendanceStrictness,
      'workload_level': workloadLevel,
      'slide_reliance': slideReliance,
      'quiz_frequency': quizFrequency,
      'textbook_need': textbookNeed,
      'traits': traits,
      'exam_prep_tips': examPrepTips,
      'review_note': reviewNote,
      'would_take_again': wouldTakeAgain,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
