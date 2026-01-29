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

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      courseCode: map['courseCode'] ?? '',
      courseName: map['courseName'] ?? '',
      assignDate: DateTime.tryParse(map['assignDate'] ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      submissionType: _parseSubmission(map['submissionType']),
      type: _parseType(map['type']),
      isCompleted: map['isCompleted'] ?? false,
    );
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
