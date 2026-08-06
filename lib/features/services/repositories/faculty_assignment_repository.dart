import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';

class FacultyAssignmentItem {
  final String courseCode;
  final String sectionNumber;
  final String? facultyInitial;

  FacultyAssignmentItem({
    required this.courseCode,
    required this.sectionNumber,
    this.facultyInitial,
  });

  Map<String, dynamic> toJson() => {
        'course_code': courseCode,
        'section_number': sectionNumber,
        if (facultyInitial != null) 'faculty_initial': facultyInitial,
      };
}

class FacultyAssignmentSubmission {
  final String id;
  final String userId;
  final String submissionType;
  final String semester;
  final String? facultyInitial;
  final String? facultyFullName;
  final List<FacultyAssignmentItem> assignments;
  final String screenshotUrl;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;

  FacultyAssignmentSubmission({
    required this.id,
    required this.userId,
    required this.submissionType,
    required this.semester,
    this.facultyInitial,
    this.facultyFullName,
    required this.assignments,
    required this.screenshotUrl,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory FacultyAssignmentSubmission.fromJson(Map<String, dynamic> json) {
    final list = (json['assignments'] as List? ?? [])
        .map((e) => FacultyAssignmentItem(
              courseCode: e['course_code'] ?? '',
              sectionNumber: e['section_number'] ?? '',
              facultyInitial: e['faculty_initial'],
            ))
        .toList();

    return FacultyAssignmentSubmission(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      submissionType: json['submission_type'] ?? 'ENROLLED',
      semester: json['semester'] ?? '',
      facultyInitial: json['faculty_initial'],
      facultyFullName: json['faculty_full_name'],
      assignments: list,
      screenshotUrl: json['screenshot_url'] ?? '',
      status: json['status'] ?? 'PENDING',
      adminNotes: json['admin_notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class FacultyAssignmentRepository {
  final SupabaseClient _client;

  FacultyAssignmentRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchFacultyMasterList() async {
    final res = await _client
        .from('faculty_master')
        .select('short_name, full_name, designation_name')
        .order('short_name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<String> uploadScreenshot(Uint8List bytes, String fileName) async {
    final path = 'proofs/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('faculty_assignment_proofs').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _client.storage.from('faculty_assignment_proofs').getPublicUrl(path);
  }

  Future<void> submitEnrolledAssignments({
    required String semester,
    required List<FacultyAssignmentItem> items,
    required Uint8List screenshotBytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    final screenshotUrl = await uploadScreenshot(screenshotBytes, fileName);

    await _client.from('faculty_assignment_submissions').insert({
      'user_id': userId,
      'submission_type': 'ENROLLED',
      'semester': semester,
      'assignments': items.map((e) => e.toJson()).toList(),
      'screenshot_url': screenshotUrl,
      'status': 'PENDING',
    });
  }

  Future<void> submitBulkAssignments({
    required String semester,
    required String facultyInitial,
    required String facultyFullName,
    required List<FacultyAssignmentItem> items,
    required Uint8List screenshotBytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    final screenshotUrl = await uploadScreenshot(screenshotBytes, fileName);

    await _client.from('faculty_assignment_submissions').insert({
      'user_id': userId,
      'submission_type': 'BULK',
      'semester': semester,
      'faculty_initial': facultyInitial,
      'faculty_full_name': facultyFullName,
      'assignments': items.map((e) => e.toJson()).toList(),
      'screenshot_url': screenshotUrl,
      'status': 'PENDING',
    });
  }

  Future<List<FacultyAssignmentSubmission>> fetchMySubmissions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _client
        .from('faculty_assignment_submissions')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => FacultyAssignmentSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final facultyAssignmentRepositoryProvider = Provider<FacultyAssignmentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return FacultyAssignmentRepository(supabase);
});
