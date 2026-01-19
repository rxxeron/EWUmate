/// Represents a single session (theory or lab) within a course
class CourseSession {
  final String type; // "Theory" or "Lab"
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

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'faculty': faculty,
    };
  }
}

/// Represents a course with all its sessions
class Course {
  final String id;
  final String code;
  final String courseName;
  final String? section;
  final String? capacity;
  final String? credits;
  final String? semester;
  final List<CourseSession> sessions;

  // Legacy fields for backward compatibility with old data format
  final String? day;
  final String? startTime;
  final String? endTime;
  final String? room;
  final String? faculty;
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
    // Legacy fields
    this.day,
    this.startTime,
    this.endTime,
    this.room,
    this.faculty,
    this.docId,
  });

  factory Course.fromFirestore(Map<String, dynamic> data, String id) {
    // Parse sessions array if present (new format)
    List<CourseSession> sessionList = [];
    if (data['sessions'] != null && data['sessions'] is List) {
      sessionList = (data['sessions'] as List)
          .map((s) => CourseSession.fromMap(s as Map<String, dynamic>))
          .toList();
    } else if (data['day'] != null) {
      // Legacy format: single session stored directly on course
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

    return Course(
      id: id,
      code: data['code'] ?? data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      section: data['section']?.toString(),
      capacity: data['capacity']?.toString(),
      credits: data['credits']?.toString(),
      semester: data['semester'],
      sessions: sessionList,
      // Legacy fields for backward compatibility
      day: data['day'],
      startTime: data['startTime'],
      endTime: data['endTime'],
      room: data['room'],
      faculty: data['faculty'],
      docId: data['docId'],
    );
  }

  /// Get all sessions for a specific day letter (S, M, T, W, R, F, A)
  List<CourseSession> getSessionsForDay(String dayLetter) {
    return sessions.where((s) {
      final sessionDay = s.day.toUpperCase();
      return sessionDay.contains(dayLetter);
    }).toList();
  }
}
