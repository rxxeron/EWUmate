class FacultyOfficeHour {
  final String id;
  final String facultyInitials;
  final String day;
  final String startTime;
  final String endTime;
  final String driveAccountId;
  final String driveFileId;
  final String fileName;
  final String? submittedBy;
  final String status;
  final String semesterCode;
  final String? officeRoom;
  final DateTime createdAt;

  FacultyOfficeHour({
    required this.id,
    required this.facultyInitials,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.driveAccountId,
    required this.driveFileId,
    required this.fileName,
    this.submittedBy,
    required this.status,
    required this.semesterCode,
    this.officeRoom,
    required this.createdAt,
  });

  factory FacultyOfficeHour.fromMap(Map<String, dynamic> map) {
    return FacultyOfficeHour(
      id: map['id'] ?? '',
      facultyInitials: map['faculty_initials'] ?? '',
      day: map['day'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      driveAccountId: map['drive_account_id'] ?? '',
      driveFileId: map['drive_file_id'] ?? '',
      fileName: map['file_name'] ?? '',
      submittedBy: map['submitted_by'],
      status: map['status'] ?? 'pending',
      semesterCode: map['semester_code'] ?? 'Summer 2026',
      officeRoom: map['office_room'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'faculty_initials': facultyInitials,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
      'drive_account_id': driveAccountId,
      'drive_file_id': driveFileId,
      'file_name': fileName,
      'submitted_by': submittedBy,
      'status': status,
      'semester_code': semesterCode,
      'office_room': officeRoom,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
