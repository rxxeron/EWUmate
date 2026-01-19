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

  void calculateTermGPA() {
    double points = 0;
    double creds = 0;
    for (var c in courses) {
      if (c.grade == "Ongoing" || c.grade == "W" || c.grade == "I") {
        continue; // Skip non-graded
      }
      points += c.totalPoints;
      creds += c.credits;
    }
    totalPoints = points;
    totalCredits = creds;
    termGPA = creds > 0 ? points / creds : 0.0;
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

  AcademicProfile({
    required this.semesters,
    required this.cgpa,
    required this.totalCreditsEarned,
    this.studentName = "",
    this.studentId = "",
    this.program = "",
    this.department = "",
    this.totalCoursesCompleted = 0,
    this.remainedCredits = 0.0,
    this.scholarshipStatus = "",
  });

  final int totalCoursesCompleted;
  final double remainedCredits;
  final String scholarshipStatus; // New field
}
