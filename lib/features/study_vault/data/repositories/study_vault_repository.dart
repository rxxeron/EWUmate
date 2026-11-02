import 'dart:io';
import 'package:crypto/crypto.dart';
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
    var query = _supabase.from('study_materials').select(
          'id, uploader_id, faculty_initial, course_code, semester, file_type, drive_file_id, file_name, file_size_bytes, created_at, updated_at, status, profiles:uploader_id(full_name)',
        );

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

    final data = await query.order('created_at', ascending: false).limit(100);
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

    // 0. Compute SHA-256 hash locally on device
    final fileHash = sha256.convert(fileBytes).toString();
    final normalizedCourseCode = courseCode?.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final normalizedFacultyInitial = facultyInitial?.replaceAll(RegExp(r'[\s\.]'), '').toUpperCase();

    // 1. Get Resumable Upload URL or Check Duplicate from Edge Function
    final response = await _supabase.functions.invoke(
      'get-drive-upload-url',
      body: {
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'fileHash': fileHash,
        'courseCode': normalizedCourseCode,
        'mimeType': 'application/octet-stream',
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to get upload URL: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    final isDuplicate = data['isDuplicate'] == true;
    var driveAccountId = data['driveAccountId'] as String? ?? 'primary';
    var driveFileId = data['driveFileId'] as String? ?? 'fallback-local-${DateTime.now().millisecondsSinceEpoch}';

    // 2. Upload directly to Google Drive ONLY IF NOT DUPLICATE
    if (!isDuplicate) {
      final uploadUrl = data['uploadUrl'] as String?;
      if (uploadUrl != null && uploadUrl.isNotEmpty) {
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

        try {
          final jsonResponse = driveResponse.body;
          if (jsonResponse.isNotEmpty) {
            final regex = RegExp(r'"id":\s*"([^"]+)"');
            final match = regex.firstMatch(jsonResponse);
            if (match != null) {
              driveFileId = match.group(1)!;
            }
          }
        } catch (e) {
          // Ignore parse fallback
        }
      }
    }

    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    if (driveFileId.startsWith('fallback-local-')) {
      throw Exception('Failed to obtain a valid Google Drive file ID. Upload aborted.');
    }

    // 3. Insert primary material entry (with file_hash)
    final basePayload = <String, dynamic>{
      'uploader_id': user.id,
      'faculty_initial': normalizedFacultyInitial,
      'course_code': normalizedCourseCode,
      'semester': semester,
      'file_type': fileType,
      'drive_account_id': driveAccountId,
      'drive_file_id': driveFileId,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
    };

    Map<String, dynamic> inserted;
    try {
      inserted = await _supabase.from('study_materials').insert({
        ...basePayload,
        'file_hash': fileHash,
      }).select('id').single();
    } catch (e) {
      // Fallback if file_hash column is not yet present in schema
      inserted = await _supabase.from('study_materials').insert(basePayload).select('id').single();
    }

    final primaryId = inserted['id'] as String;

    // 2. Fetch if this course has a "same_course" mapped equivalent
    String? sameCourseCode;
    try {
      if (normalizedCourseCode != null) {
        final courseRes = await _supabase
            .from('course_metadata')
            .select('equivalent_code, same_course')
            .eq('code', normalizedCourseCode)
            .maybeSingle();
        if (courseRes != null) {
          sameCourseCode = (courseRes['equivalent_code'] ?? courseRes['same_course']) as String?;
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
        .select(
          'id, uploader_id, faculty_initial, course_code, semester, file_type, drive_file_id, file_name, file_size_bytes, created_at, updated_at, status, profiles:uploader_id(full_name)',
        )
        .eq('uploader_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

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

  Future<void> deleteOrRequestRemoval(StudyMaterial item) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    if (item.status == 'pending') {
      try {
        await _supabase
            .from('study_materials')
            .delete()
            .eq('id', item.id)
            .eq('uploader_id', user.id);
        return;
      } catch (_) {
        // Fallback to request removal if delete policy prevents hard delete
      }
    }
    await requestRemoval(item.id);
  }
}
