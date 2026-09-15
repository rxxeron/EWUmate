import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final portalServiceProvider = Provider<PortalService>((ref) {
  return PortalService();
});

class PortalStudentProfile {
  final String studentId;
  final String fullName;
  final String email;
  final String programName;
  final String programCode;
  final String departmentName;
  final String departmentCode;
  final String admittedSemester;
  final double cgpa;
  final double creditsEarned;
  final String mentor;
  final String mentorEmail;

  PortalStudentProfile({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.programName,
    required this.programCode,
    required this.departmentName,
    required this.departmentCode,
    required this.admittedSemester,
    required this.cgpa,
    required this.creditsEarned,
    required this.mentor,
    required this.mentorEmail,
  });

  factory PortalStudentProfile.fromJson(Map<String, dynamic> json) {
    return PortalStudentProfile(
      studentId: json['StudentId']?.toString() ?? '',
      fullName: json['FirstName']?.toString() ?? '',
      email: json['EmailAddress']?.toString() ?? '',
      programName: json['ProgramName']?.toString() ?? '',
      programCode: json['ProgramShortName']?.toString() ?? '',
      departmentName: json['AcademicDepartmentName']?.toString() ?? '',
      departmentCode: json['AcademicDepartmentShortName']?.toString() ?? '',
      admittedSemester: json['StartedSemester']?.toString() ?? json['SemesterName']?.toString() ?? '',
      cgpa: (json['CGPA'] as num?)?.toDouble() ?? 0.0,
      creditsEarned: (json['CreditsCompleted'] as num?)?.toDouble() ?? 0.0,
      mentor: json['Mentor']?.toString() ?? '',
      mentorEmail: json['MentorEmail']?.toString() ?? '',
    );
  }
}

class PortalCourseSession {
  final String type; // Theory or Lab
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final String faculty;
  final String facultyName;
  final String facultyEmail;

  PortalCourseSession({
    required this.type,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.faculty,
    required this.facultyName,
    required this.facultyEmail,
  });

  factory PortalCourseSession.fromJson(Map<String, dynamic> json) {
    return PortalCourseSession(
      type: json['type']?.toString() ?? 'Theory',
      day: json['day']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      room: json['room']?.toString() ?? 'TBA',
      faculty: json['faculty']?.toString() ?? 'TBA',
      facultyName: json['faculty_name']?.toString() ?? '',
      facultyEmail: json['faculty_email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'day': day,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'faculty': faculty,
    'faculty_name': facultyName,
    'faculty_email': facultyEmail,
  };
}

class PortalEnrolledCourse {
  final String courseCode;
  final String originalCode;
  final String section;
  final double credits;
  final String timing;
  final String room;
  final String facultyName;
  final String facultyInitial;
  final String facultyEmail;
  final String withdrawStatus;
  final String dropStatus;
  final bool isDroppedOrWithdrawn;
  final List<PortalCourseSession> sessions;

  PortalEnrolledCourse({
    required this.courseCode,
    this.originalCode = '',
    required this.section,
    required this.credits,
    required this.timing,
    required this.room,
    required this.facultyName,
    required this.facultyInitial,
    required this.facultyEmail,
    required this.withdrawStatus,
    required this.dropStatus,
    this.isDroppedOrWithdrawn = false,
    this.sessions = const [],
  });

  bool get isWithdrawn => withdrawStatus.toLowerCase() == 'yes';
  bool get isDropped => dropStatus.toLowerCase() == 'yes';
  bool get isInactive => isDroppedOrWithdrawn || isWithdrawn || isDropped;

  factory PortalEnrolledCourse.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'] as List? ?? [];
    final wStat = json['withdraw_status']?.toString() ?? json['WithDrawStatus']?.toString() ?? 'No';
    final dStat = json['drop_status']?.toString() ?? json['DropStatus']?.toString() ?? 'No';
    final isDroppedOrWithdrawn = json['is_dropped_or_withdrawn'] == true ||
        wStat.toLowerCase() == 'yes' ||
        dStat.toLowerCase() == 'yes';

    return PortalEnrolledCourse(
      courseCode: json['course_code']?.toString() ?? json['CourseCode']?.toString() ?? '',
      originalCode: json['original_code']?.toString() ?? json['CourseCode']?.toString() ?? '',
      section: json['section']?.toString() ?? json['SectionName']?.toString() ?? '',
      credits: (json['credits'] as num?)?.toDouble() ?? (json['CreditHour'] as num?)?.toDouble() ?? 3.0,
      timing: json['timing']?.toString() ?? json['TimeSlotName']?.toString() ?? '',
      room: json['room']?.toString() ?? json['RoomName']?.toString() ?? '',
      facultyName: json['faculty_name']?.toString() ?? json['FacultyName']?.toString() ?? '',
      facultyInitial: json['faculty_initial']?.toString() ?? json['ShortName']?.toString() ?? '',
      facultyEmail: json['faculty_email']?.toString() ?? json['Email']?.toString() ?? '',
      withdrawStatus: wStat,
      dropStatus: dStat,
      isDroppedOrWithdrawn: isDroppedOrWithdrawn,
      sessions: rawSessions.map((s) => PortalCourseSession.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  PortalEnrolledCourse copyWith({
    String? courseCode,
    String? originalCode,
    String? section,
    double? credits,
    String? timing,
    String? room,
    String? facultyName,
    String? facultyInitial,
    String? facultyEmail,
    String? withdrawStatus,
    String? dropStatus,
    bool? isDroppedOrWithdrawn,
    List<PortalCourseSession>? sessions,
  }) {
    return PortalEnrolledCourse(
      courseCode: courseCode ?? this.courseCode,
      originalCode: originalCode ?? this.originalCode,
      section: section ?? this.section,
      credits: credits ?? this.credits,
      timing: timing ?? this.timing,
      room: room ?? this.room,
      facultyName: facultyName ?? this.facultyName,
      facultyInitial: facultyInitial ?? this.facultyInitial,
      facultyEmail: facultyEmail ?? this.facultyEmail,
      withdrawStatus: withdrawStatus ?? this.withdrawStatus,
      dropStatus: dropStatus ?? this.dropStatus,
      isDroppedOrWithdrawn: isDroppedOrWithdrawn ?? this.isDroppedOrWithdrawn,
      sessions: sessions ?? this.sessions,
    );
  }
}

class PortalDegreeArea {
  final String area;
  final double totalCredits;
  final double creditsEarned;
  final double remainingCredits;
  final List<PortalDegreeCourse> courses;

  PortalDegreeArea({
    required this.area,
    required this.totalCredits,
    required this.creditsEarned,
    required this.remainingCredits,
    required this.courses,
  });

  factory PortalDegreeArea.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['CourseView'] as List? ?? [];
    return PortalDegreeArea(
      area: json['Area']?.toString() ?? 'Other Courses',
      totalCredits: (json['TotalAreaCredits'] as num?)?.toDouble() ?? 0.0,
      creditsEarned: (json['TotalCreditsEarned'] as num?)?.toDouble() ?? 0.0,
      remainingCredits: (json['TotalRemainingCredits'] as num?)?.toDouble() ?? 0.0,
      courses: rawCourses.map((c) => PortalDegreeCourse.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
}

class PortalDegreeCourse {
  final String courseCode;
  final String courseName;
  final double credits;
  final String grade;
  final double gradePoint;

  PortalDegreeCourse({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.grade,
    required this.gradePoint,
  });

  factory PortalDegreeCourse.fromJson(Map<String, dynamic> json) {
    return PortalDegreeCourse(
      courseCode: json['CourseCode']?.toString() ?? '',
      courseName: json['CourseName']?.toString() ?? '',
      credits: (json['CreditHour'] as num?)?.toDouble() ?? 0.0,
      grade: json['Grade']?.toString() ?? '',
      gradePoint: (json['GradePoint'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PortalSyncResult {
  final PortalStudentProfile profile;
  final String activeSemesterName;
  final int activeSemesterId;
  final String semesterCode;
  final List<PortalEnrolledCourse> enrolledCourses;
  final List<PortalDegreeArea> degreeAreas;

  PortalSyncResult({
    required this.profile,
    required this.activeSemesterName,
    required this.activeSemesterId,
    this.semesterCode = '',
    required this.enrolledCourses,
    required this.degreeAreas,
  });
}

class PortalService {
  static const String baseUrl = 'https://portal.ewubd.edu';
  final http.Client _client = http.Client();
  String? _sessionCookie;

  Map<String, String> _headers({bool isAjax = false}) {
    final h = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': '$baseUrl/',
    };
    if (isAjax) {
      h['X-Requested-With'] = 'XMLHttpRequest';
      h['Accept'] = 'application/json, text/plain, */*';
    }
    if (_sessionCookie != null) {
      h['Cookie'] = _sessionCookie!;
    }
    return h;
  }

  void _extractCookies(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final match = RegExp(r'(ASP\.NET_SessionId=[^;]+)').firstMatch(rawCookie);
      if (match != null) {
        _sessionCookie = match.group(1);
      }
    }
  }

  /// 1. Solves the arithmetic captcha and logs in
  Future<bool> login(String studentId, String password) async {
    _sessionCookie = null;
    final loginPageRes = await _client.get(
      Uri.parse('$baseUrl/Account/Login'),
      headers: _headers(),
    );
    _extractCookies(loginPageRes);

    final html = loginPageRes.body;
    final firstMatch = RegExp(r'''name=["']FirstNo["'][^>]*value=["'](\d+)["']|value=["'](\d+)["'][^>]*name=["']FirstNo["']''').firstMatch(html);
    final secondMatch = RegExp(r'''name=["']SecondNo["'][^>]*value=["'](\d+)["']|value=["'](\d+)["'][^>]*name=["']SecondNo["']''').firstMatch(html);

    final fStr = firstMatch?.group(1) ?? firstMatch?.group(2);
    final sStr = secondMatch?.group(1) ?? secondMatch?.group(2);

    if (fStr == null || sStr == null) {
      throw Exception('Could not locate captcha numbers on portal login page.');
    }

    final int firstNo = int.parse(fStr);
    final int secondNo = int.parse(sStr);
    final int answer = firstNo + secondNo;

    final loginPostRes = await _client.post(
      Uri.parse('$baseUrl/Account/Login'),
      headers: _headers(),
      body: {
        'Username': studentId,
        'Password': password,
        'FirstNo': firstNo.toString(),
        'SecondNo': secondNo.toString(),
        'Answer': answer.toString(),
      },
    );
    _extractCookies(loginPostRes);

    if (loginPostRes.body.contains('Invalid Username or Password')) {
      return false;
    }

    return _sessionCookie != null;
  }

  /// 2. Fetches profile metadata: Name, StudentID, Department, Program, Admitted Semester
  Future<PortalStudentProfile> getStudentProfile() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/StudentProfile/GetStudentProfile'),
      headers: _headers(isAjax: true),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch student profile from portal (Status: ${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return PortalStudentProfile.fromJson(data);
  }

  /// 3. Fetches active semester ID & Name
  Future<Map<String, dynamic>> getActiveSemester() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/utility/GetSemesterForDropDown'),
      headers: _headers(isAjax: true),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch semester list (Status: ${res.statusCode})');
    }

    final List list = jsonDecode(res.body);
    if (list.isEmpty) {
      throw Exception('No semesters found on portal.');
    }
    // Index 0 is always the latest active semester
    return list[0] as Map<String, dynamic>;
  }

  /// 4. Fetches the enrolled class schedule & assigned faculty for active semester
  Future<List<PortalEnrolledCourse>> getActiveSchedule(int semesterId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/Advising/GetSemesterStudentWiseAdvisingCourseListStudent/$semesterId'),
      headers: _headers(isAjax: true),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch class schedule (Status: ${res.statusCode})');
    }

    final List list = jsonDecode(res.body);
    return list.map((c) => PortalEnrolledCourse.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// 5. Fetches complete Degree Review: all completed courses, categories, credits, and letter grades
  Future<List<PortalDegreeArea>> getDegreeReview(String studentId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/DegreeReview/GetDegreeReviewCourseAreaCourses?studentId=$studentId'),
      headers: _headers(isAjax: true),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch degree review (Status: ${res.statusCode})');
    }

    final List list = jsonDecode(res.body);
    return list.map((a) => PortalDegreeArea.fromJson(a as Map<String, dynamic>)).toList();
  }

  /// Full Automated Sync: Login + Profile + Active Routine + Degree Review in one call
  Future<PortalSyncResult> syncAll({
    required String studentId,
    required String password,
  }) async {
    final loggedIn = await login(studentId, password);
    if (!loggedIn) {
      throw Exception('Invalid Portal Student ID or Password.');
    }

    final profileFuture = getStudentProfile();
    final semFuture = getActiveSemester();
    final degreeFuture = getDegreeReview(studentId);

    final profile = await profileFuture;
    final sem = await semFuture;
    final semId = sem['SemesterId'] as int;
    final semName = sem['SemesterName']?.toString() ?? 'Active Semester';

    final schedule = await getActiveSchedule(semId);
    final degreeAreas = await degreeFuture;

    return PortalSyncResult(
      profile: profile,
      activeSemesterName: semName,
      activeSemesterId: semId,
      enrolledCourses: schedule,
      degreeAreas: degreeAreas,
    );
  }
}
