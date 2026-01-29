class CourseSession {
  final String type;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final String faculty;

  CourseSession({
    required this.type,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.faculty,
  });

  factory CourseSession.fromMap(Map<String, dynamic> data) {
    return CourseSession(
      type: data['type'] ?? 'Theory',
      day: data['day'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      room: data['room'] ?? '',
      faculty: data['faculty'] ?? '',
    );
  }
}

class Course {
  final String id;
  final String code;
  final String courseName;
  final String? section;
  final String? capacity;
  final String? credits;
  final String? semester;
  final List<CourseSession> sessions;

  final String? day;
  final String? startTime;
  final String? endTime;
  final String? faculty;
  final String? room;
  final String? docId;

  Course({
    required this.id,
    required this.code,
    required this.courseName,
    this.section,
    this.capacity,
    this.credits,
    this.semester,
    this.sessions = const [],
    this.day,
    this.startTime,
    this.endTime,
    this.room,
    this.faculty,
    this.docId,
  });

  factory Course.fromFirestore(Map<String, dynamic> data, String id) {
    List<CourseSession> sessionList = [];

    if (data['sessions'] != null && data['sessions'] is List) {
      sessionList = (data['sessions'] as List)
          .map((s) => CourseSession.fromMap(s as Map<String, dynamic>))
          .toList();
    } else if (data['day'] != null) {
      sessionList = [
        CourseSession(
          type: 'Theory',
          day: data['day'] ?? '',
          startTime: data['startTime'] ?? '',
          endTime: data['endTime'] ?? '',
          room: data['room'] ?? '',
          faculty: data['faculty'] ?? '',
        )
      ];
    }

    final theorySession = sessionList.isNotEmpty ? sessionList.first : null;

    return Course(
      id: id,
      code: data['code'] ?? data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      section: data['section']?.toString(),
      capacity: data['capacity']?.toString(),
      credits: data['credits']?.toString(),
      semester: data['semester'],
      sessions: sessionList,
      day: theorySession?.day ?? data['day'],
      startTime: theorySession?.startTime ?? data['startTime'],
      endTime: theorySession?.endTime ?? data['endTime'],
      faculty: theorySession?.faculty ?? data['faculty'],
      room: theorySession?.room ?? data['room'],
      docId: data['docId'],
    );
  }

  CourseSession? getFirstSession(String type) {
    return sessions.where((s) => s.type == type).firstOrNull;
  }
}
