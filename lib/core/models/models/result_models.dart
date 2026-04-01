class CourseResult {
  final String courseCode;
  final String courseTitle;
  final double credits;
  final String grade;
  final bool isRetakable;
  final double gradePoint;

  CourseResult({
    required this.courseCode,
    required this.courseTitle,
    required this.credits,
    required this.grade,
    required this.gradePoint,
    this.isRetakable = false,
  });

  CourseResult copyWith({
    String? courseCode,
    String? courseTitle,
    double? credits,
    String? grade,
    double? gradePoint,
    bool? isRetakable,
  }) {
    return CourseResult(
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      credits: credits ?? this.credits,
      grade: grade ?? this.grade,
      gradePoint: gradePoint ?? this.gradePoint,
      isRetakable: isRetakable ?? this.isRetakable,
    );
  }

  double get totalPoints => credits * gradePoint;

  Map<String, dynamic> toMap() {
    return {
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'credits': credits,
      'grade': grade,
      'gradePoint': gradePoint,
      'isRetakable': isRetakable,
    };
  }

  factory CourseResult.fromMap(Map<String, dynamic> map) {
    final grade = (map['grade'] ?? '').toString().toUpperCase();
    return CourseResult(
      courseCode: map['courseCode'] ?? '',
      courseTitle: map['courseTitle'] ?? '',
      credits: (map['credits'] as num?)?.toDouble() ?? 0.0,
      grade: grade,
      gradePoint: (map['gradePoint'] as num?)?.toDouble() ?? 0.0,
      isRetakable: map['isRetakable'] as bool? ?? (grade == 'F' || grade == 'W'),
    );
  }
}

class SemesterResult {
  final String semesterName;
  final List<CourseResult> courses;
  double termGPA;
  double cumulativeGPA; // Calculated cumulatively
  double totalCredits; // For this term
  double totalPoints; // For this term

  SemesterResult({
    required this.semesterName,
    required this.courses,
    this.termGPA = 0.0,
    this.cumulativeGPA = 0.0,
    this.totalCredits = 0.0,
    this.totalPoints = 0.0,
  });

  SemesterResult copyWith({
    String? semesterName,
    List<CourseResult>? courses,
    double? termGPA,
    double? cumulativeGPA,
    double? totalCredits,
    double? totalPoints,
  }) {
    return SemesterResult(
      semesterName: semesterName ?? this.semesterName,
      courses: courses ?? this.courses,
      termGPA: termGPA ?? this.termGPA,
      cumulativeGPA: cumulativeGPA ?? this.cumulativeGPA,
      totalCredits: totalCredits ?? this.totalCredits,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'semesterName': semesterName,
      'courses': courses.map((c) => c.toMap()).toList(),
      'termGPA': termGPA,
      'cumulativeGPA': cumulativeGPA,
      'totalCredits': totalCredits,
      'totalPoints': totalPoints,
    };
  }

  factory SemesterResult.fromMap(Map<String, dynamic> map) {
    return SemesterResult(
      semesterName: map['semesterName'] ?? '',
      courses: (map['courses'] as List? ?? [])
          .map((c) => CourseResult.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
      termGPA: (map['termGPA'] as num?)?.toDouble() ?? 0.0,
      cumulativeGPA: (map['cumulativeGPA'] as num?)?.toDouble() ?? 0.0,
      totalCredits: (map['totalCredits'] as num?)?.toDouble() ?? 0.0,
      totalPoints: (map['totalPoints'] as num?)?.toDouble() ?? 0.0,
    );
  }

  void calculateTermGPA() {
    double tempCredits = 0;
    double tempPoints = 0;
    
    for (var c in courses) {
      final g = c.grade.toUpperCase().trim();
      // Only count towards TGPA if it's a graded course that is not Failed or Incomplete
      // Note: F is counted in CGPA/TGPA as 0.0 points but counts as 'graded credits'
      if (g != 'ONGOING' && g.isNotEmpty && !['W', 'I', 'S', 'U', 'P', 'R'].contains(g)) {
        tempCredits += c.credits;
        tempPoints += c.totalPoints;
      }
    }
    
    totalCredits = tempCredits;
    totalPoints = tempPoints;
    termGPA = tempCredits > 0 ? double.parse((tempPoints / tempCredits).toStringAsFixed(2)) : 0.0;
  }
}

class AcademicProfile {
  final List<SemesterResult> semesters;
  final double cgpa;
  final double totalCreditsEarned;

  // Metadata
  final String studentName;
  final String studentId;
  final String programId; // short code: 'cse', 'bba', etc.
  final String program;
  final String department;
  final String nickname;
  final String photoUrl;

  AcademicProfile({
    required this.semesters,
    required this.cgpa,
    required this.totalCreditsEarned,
    this.studentName = "",
    this.studentId = "",
    this.programId = "",
    this.program = "",
    this.department = "",
    this.nickname = "",
    this.photoUrl = "",
    this.scholarshipStatus = "",
    this.track = "tri_semester", 
    this.ongoingCourses = 0,
    this.totalCoursesCompleted = 0,
    this.remainedCredits = 0.0,
  });

  final int ongoingCourses;
  final int totalCoursesCompleted;
  final double remainedCredits;
  final String scholarshipStatus;
  final String track; // 'tri_semester' or 'bi_semester'
  String get semesterType => track;

  Map<String, dynamic> toMap() {
    return {
      'semesters': semesters.map((s) => s.toMap()).toList(),
      'cgpa': cgpa,
      'total_credits_earned': totalCreditsEarned,
      'full_name': studentName,
      'student_id': studentId,
      'program': program,
      'department': department,
      'nickname': nickname,
      'photo_url': photoUrl,
      'ongoing_courses': ongoingCourses,
      'total_courses_completed': totalCoursesCompleted,
      'remained_credits': remainedCredits,
      'scholarship_status': scholarshipStatus,
      'track': track,
    };
  }

  factory AcademicProfile.fromMap(Map<String, dynamic> map) {
    return AcademicProfile(
      semesters: (map['semesters'] as List? ?? [])
          .map((s) => SemesterResult.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
      cgpa: (map['cgpa'] as num?)?.toDouble() ?? 0.0,
      totalCreditsEarned: (map['total_credits_earned'] as num?)?.toDouble() ?? 
                         (map['totalCreditsEarned'] as num?)?.toDouble() ?? 0.0,
      studentName: map['full_name'] ?? map['studentName'] ?? '',
      studentId: map['student_id'] ?? map['studentId'] ?? '',
      program: map['program'] ?? '',
      department: map['department'] ?? '',
      nickname: map['nickname'] ?? '',
      photoUrl: map['photo_url'] ?? map['photoUrl'] ?? '',
      ongoingCourses: map['ongoing_courses'] ?? map['ongoingCourses'] ?? 0,
      totalCoursesCompleted: map['total_courses_completed'] ?? map['totalCoursesCompleted'] ?? 0,
      remainedCredits: (map['remained_credits'] as num?)?.toDouble() ?? 
                       (map['remainedCredits'] as num?)?.toDouble() ?? 0.0,
      scholarshipStatus: map['scholarship_status'] ?? map['scholarshipStatus'] ?? '',
      track: map['track'] ?? map['semesterType'] ?? 'tri_semester',
    );
  }
}
