class CourseResult {
  final String courseCode;
  final String courseTitle;
  final double credits;
  final String grade;
  final double gradePoint;

  CourseResult({
    required this.courseCode,
    required this.courseTitle,
    required this.credits,
    required this.grade,
    required this.gradePoint,
  });

  double get totalPoints => credits * gradePoint;

  Map<String, dynamic> toMap() {
    return {
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'credits': credits,
      'grade': grade,
      'gradePoint': gradePoint,
    };
  }

  factory CourseResult.fromMap(Map<String, dynamic> map) {
    return CourseResult(
      courseCode: map['courseCode'] ?? '',
      courseTitle: map['courseTitle'] ?? '',
      credits: (map['credits'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade'] ?? '',
      gradePoint: (map['gradePoint'] as num?)?.toDouble() ?? 0.0,
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

  /// Recalculates term GPA locally. 
  /// @deprecated Use backend-calculated [termGPA] whenever possible.
  void calculateTermGPA() {
    double points = 0;
    double creds = 0;
    for (var c in courses) {
      if (c.grade == "Ongoing" || c.grade == "W" || c.grade == "I" || c.grade == "S" || c.grade == "P") {
        continue; // Skip non-graded
      }
      points += c.totalPoints;
      creds += c.credits;
    }
    totalPoints = points;
    totalCredits = creds;
    termGPA = creds > 0 ? points / creds : 0.0;
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
}

class AcademicProfile {
  final List<SemesterResult> semesters;
  final double cgpa;
  final double totalCreditsEarned;

  // Metadata
  final String studentName;
  final String studentId;
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
    this.program = "",
    this.department = "",
    this.nickname = "",
    this.photoUrl = "",
    this.ongoingCourses = 0,
    this.totalCoursesCompleted = 0,
    this.remainedCredits = 0.0,
    this.scholarshipStatus = "",
  });

  final int ongoingCourses;
  final int totalCoursesCompleted;
  final double remainedCredits;
  final String scholarshipStatus; // New field

  Map<String, dynamic> toMap() {
    return {
      'semesters': semesters.map((s) => s.toMap()).toList(),
      'cgpa': cgpa,
      'totalCreditsEarned': totalCreditsEarned,
      'studentName': studentName,
      'studentId': studentId,
      'program': program,
      'department': department,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'ongoingCourses': ongoingCourses,
      'totalCoursesCompleted': totalCoursesCompleted,
      'remainedCredits': remainedCredits,
      'scholarshipStatus': scholarshipStatus,
    };
  }

  factory AcademicProfile.fromMap(Map<String, dynamic> map) {
    return AcademicProfile(
      semesters: (map['semesters'] as List? ?? [])
          .map((s) => SemesterResult.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
      cgpa: (map['cgpa'] as num?)?.toDouble() ?? 0.0,
      totalCreditsEarned: (map['totalCreditsEarned'] as num?)?.toDouble() ?? 0.0,
      studentName: map['studentName'] ?? '',
      studentId: map['studentId'] ?? '',
      program: map['program'] ?? '',
      department: map['department'] ?? '',
      nickname: map['nickname'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      ongoingCourses: map['ongoingCourses'] ?? 0,
      totalCoursesCompleted: map['totalCoursesCompleted'] ?? 0,
      remainedCredits: (map['remainedCredits'] as num?)?.toDouble() ?? 0.0,
      scholarshipStatus: map['scholarshipStatus'] ?? '',
    );
  }
}
