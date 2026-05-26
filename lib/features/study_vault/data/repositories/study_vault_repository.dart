import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/study_material.dart';

final studyVaultRepositoryProvider = Provider<StudyVaultRepository>((ref) {
  return StudyVaultRepository(Supabase.instance.client);
});

class StudyVaultRepository {
  final SupabaseClient _supabase;

  StudyVaultRepository(this._supabase);

  Future<List<StudyMaterial>> getMaterials({
    String? facultyInitial,
    String? courseCode,
    String? semester,
    String? fileType,
    String? searchQuery,
  }) async {
    var query = _supabase.from('study_materials').select('*, profiles:uploader_id(full_name)');

    // Only show approved materials publicly
    query = query.eq('status', 'approved');

    if (facultyInitial != null && facultyInitial.isNotEmpty) {
      final normalized = facultyInitial.replaceAll(RegExp(r'[\s\.]'), '').toUpperCase();
      query = query.ilike('faculty_initial', normalized);
    }
    if (courseCode != null && courseCode.isNotEmpty) {
      final normalized = courseCode.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
      query = query.ilike('course_code', normalized);
    }
    if (semester != null && semester.isNotEmpty) {
      query = query.ilike('semester', semester);
    }
    if (fileType != null && fileType.isNotEmpty) {
      query = query.ilike('file_type', fileType);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('file_name.ilike.%$q%,course_code.ilike.%$q%,faculty_initial.ilike.%$q%');
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((e) => StudyMaterial.fromJson(e)).toList();
  }

  Future<void> uploadMaterial({
    required File file,
    required String fileName,
    required String? facultyInitial,
    required String? courseCode,
    required String? semester,
    required String? fileType,
  }) async {
    final fileBytes = await file.readAsBytes();
    final fileSizeBytes = fileBytes.length;

    // 1. Get Resumable Upload URL from Edge Function
    final response = await _supabase.functions.invoke(
      'get-drive-upload-url',
      body: {
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'mimeType': 'application/octet-stream',
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to get upload URL: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    final uploadUrl = data['uploadUrl'] as String;
    final driveAccountId = data['driveAccountId'] as String;

    // 2. Upload directly to Google Drive
    final driveResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Length': fileSizeBytes.toString(),
      },
      body: fileBytes,
    );

    if (driveResponse.statusCode != 200 && driveResponse.statusCode != 201) {
      throw Exception('Failed to upload file to Google Drive');
    }

    // Google returns the file metadata (including ID) in JSON
    // Wait, the edge function might be using POST with resumable which gives 200 for PUT...
    // Actually, resumable upload returns empty 200 or 201, but the body might have json if it's the final chunk
    // But since we just send the whole file, it should return the JSON with 'id'.
    // If it doesn't parse, we can catch it.
    
    // 3. Save to Supabase
    // We need the file ID from Google. When you PUT to resumable, it returns JSON on success.
    // However, if parsing fails, we might just store a placeholder or try to parse it safely.
    String driveFileId = 'unknown';
    try {
      // In Dart http, body is a string
      final jsonResponse = driveResponse.body;
      if (jsonResponse.isNotEmpty) {
         // Using a quick regex or dart convert.
         // Let's assume the json contains "id"
         final regex = RegExp(r'"id":\s*"([^"]+)"');
         final match = regex.firstMatch(jsonResponse);
         if (match != null) {
           driveFileId = match.group(1)!;
         }
      }
    } catch (e) {
      // Ignore
    }

    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final normalizedCourseCode = courseCode?.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final normalizedFacultyInitial = facultyInitial?.replaceAll(RegExp(r'[\s\.]'), '').toUpperCase();

    // 1. Insert primary material entry
    final inserted = await _supabase.from('study_materials').insert({
      'uploader_id': user.id,
      'faculty_initial': normalizedFacultyInitial,
      'course_code': normalizedCourseCode,
      'semester': semester,
      'file_type': fileType,
      'drive_account_id': driveAccountId,
      'drive_file_id': driveFileId,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
    }).select('id').single();

    final primaryId = inserted['id'] as String;

    // 2. Fetch if this course has a "same_course" mapped equivalent
    String? sameCourseCode;
    try {
      if (normalizedCourseCode != null) {
        final courseRes = await _supabase
            .from('course_metadata')
            .select('same_course')
            .eq('code', normalizedCourseCode)
            .maybeSingle();
        if (courseRes != null) {
          sameCourseCode = courseRes['same_course'] as String?;
        }
      }
    } catch (_) {
      // Fail silently, do not prevent main upload
    }

    // 3. Insert child entry for the peer equivalent course
    if (sameCourseCode != null && sameCourseCode.isNotEmpty) {
      try {
        await _supabase.from('study_materials').insert({
          'uploader_id': user.id,
          'faculty_initial': normalizedFacultyInitial,
          'course_code': sameCourseCode,
          'semester': semester,
          'file_type': fileType,
          'drive_account_id': driveAccountId,
          'drive_file_id': driveFileId,
          'file_name': fileName,
          'file_size_bytes': fileSizeBytes,
          'parent_id': primaryId,
        });
      } catch (_) {
        // Fail silently
      }
    }
  }

  Future<List<StudyMaterial>> getMyMaterials() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = await _supabase
        .from('study_materials')
        .select('*, profiles:uploader_id(full_name)')
        .eq('uploader_id', user.id)
        .order('created_at', ascending: false);

    return data.map((e) => StudyMaterial.fromJson(e)).toList();
  }

  Future<void> requestRemoval(String materialId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase
        .from('study_materials')
        .update({'status': 'removal_requested'})
        .eq('id', materialId)
        .eq('uploader_id', user.id);
  }
}
