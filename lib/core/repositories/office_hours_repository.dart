import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/faculty_office_hour.dart';
import '../providers/supabase_provider.dart';

final officeHoursRepositoryProvider = Provider<OfficeHoursRepository>((ref) {
  return OfficeHoursRepository(ref.watch(supabaseClientProvider));
});

class OfficeHoursRepository {
  final SupabaseClient _supabase;

  OfficeHoursRepository(this._supabase);

  // Fetch approved office hours for a faculty member for a specific semester
  Future<List<FacultyOfficeHour>> getApprovedOfficeHours(String initials, String semesterCode) async {
    try {
      final normalized = initials.trim().toUpperCase();
      final data = await _supabase
          .from('faculty_office_hours')
          .select()
          .eq('status', 'approved')
          .eq('semester_code', semesterCode)
          .ilike('faculty_initials', normalized)
          .order('day', ascending: true);

      return (data as List).map((e) => FacultyOfficeHour.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Fetch submissions created by the current user
  Future<List<FacultyOfficeHour>> getMySubmissions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('faculty_office_hours')
          .select()
          .eq('submitted_by', user.id)
          .order('created_at', ascending: false);

      return (data as List).map((e) => FacultyOfficeHour.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Upload proof and submit multiple office hours rows
  Future<void> submitOfficeHours({
    required File file,
    required String fileName,
    required String facultyInitials,
    required List<Map<String, String>> slots,
    required String semesterCode,
    String? officeRoom,
  }) async {
    final fileBytes = await file.readAsBytes();
    final fileSizeBytes = fileBytes.length;

    // 1. Request secure resumable upload URL from Supabase Edge Function
    final response = await _supabase.functions.invoke(
      'get-drive-upload-url',
      body: {
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'mimeType': 'application/octet-stream',
        'purpose': 'office_hours', // Route to the isolated office hours drive account
      },
    );

    if (response.status != 200) {
      throw Exception('Upload handshake failed: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    final uploadUrl = data['uploadUrl'] as String;
    final driveAccountId = data['driveAccountId'] as String;

    // 2. Perform direct resumable upload of bytes to Google Drive
    final driveResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Length': fileSizeBytes.toString(),
      },
      body: fileBytes,
    );

    if (driveResponse.statusCode != 200 && driveResponse.statusCode != 201) {
      throw Exception('Google Drive upload failed');
    }

    // Parse out Google Drive file ID
    String driveFileId = 'unknown';
    try {
      final jsonResponse = driveResponse.body;
      if (jsonResponse.isNotEmpty) {
        final regex = RegExp(r'"id":\s*"([^"]+)"');
        final match = regex.firstMatch(jsonResponse);
        if (match != null) {
          driveFileId = match.group(1)!;
        }
      }
    } catch (_) {}

    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final normalizedInitials = facultyInitials.trim().toUpperCase();

    // 3. Build rows and bulk-insert them into the Supabase database
    final rows = slots.map((slot) => {
      'faculty_initials': normalizedInitials,
      'day': slot['day'],
      'start_time': slot['startTime'],
      'end_time': slot['endTime'],
      'drive_account_id': driveAccountId,
      'drive_file_id': driveFileId,
      'file_name': fileName,
      'submitted_by': user.id,
      'status': 'pending', // Seed as pending, awaiting moderation approval
      'semester_code': semesterCode,
      'office_room': officeRoom,
    }).toList();

    await _supabase.from('faculty_office_hours').insert(rows);
  }
}
