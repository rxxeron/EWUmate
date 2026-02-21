enum TaskType {
  quiz,
  shortQuiz,
  viva,
  presentation,
  assignment,
  labReport,
  midTerm,
  finalExam,
  other
}

enum SubmissionType { online, offline }

class Task {
  final String id;
  final String title; // "Quiz 1", "Assignment 2"
  final String courseCode; // e.g., "CSE101"
  final String courseName;
  final DateTime assignDate;
  final DateTime dueDate;
  final SubmissionType submissionType;
  final TaskType type;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.courseName,
    required this.assignDate,
    required this.dueDate,
    required this.submissionType,
    required this.type,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'courseCode': courseCode,
      'courseName': courseName,
      'assignDate': assignDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'submissionType': submissionType.name,
      'type': type.name,
      'isCompleted': isCompleted,
    };
  }

  Map<String, dynamic> toSupabase(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'course_code': courseCode,
      'course_name': courseName,
      'assign_date': assignDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'submission_type': submissionType.name,
      'type': type.name,
      'is_completed': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      courseCode: map['courseCode'] ?? map['course_code'] ?? '',
      courseName: map['courseName'] ?? map['course_name'] ?? '',
      assignDate:
          DateTime.tryParse(map['assignDate'] ?? map['assign_date'] ?? '') ??
              DateTime.now(),
      dueDate: DateTime.tryParse(map['dueDate'] ?? map['due_date'] ?? '') ??
          DateTime.now(),
      submissionType:
          _parseSubmission(map['submissionType'] ?? map['submission_type']),
      type: _parseType(map['type']),
      isCompleted: map['isCompleted'] ?? map['is_completed'] ?? false,
    );
  }

  factory Task.fromSupabase(Map<String, dynamic> data) {
    return Task.fromMap(data, data['id'] ?? '');
  }

  static SubmissionType _parseSubmission(String? val) {
    return SubmissionType.values
        .firstWhere((e) => e.name == val, orElse: () => SubmissionType.offline);
  }

  static TaskType _parseType(String? val) {
    return TaskType.values
        .firstWhere((e) => e.name == val, orElse: () => TaskType.assignment);
  }
}
