import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faculty.dart';
import '../models/course_section.dart';
import '../providers/supabase_provider.dart';
import '../services/cache_service.dart';

part 'faculty_repository.g.dart';

class FacultyRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;

  FacultyRepository(this._supabase, this._cache);

  Future<List<Faculty>> getAllFaculty() async {
    // Try cache first
    final cached = _cache.getMapData('faculty', 'directory');
    if (cached != null && cached['data'] != null) {
      final updatedAtStr = cached['updated_at'] as String?;
      if (updatedAtStr != null) {
        final updatedAt = DateTime.tryParse(updatedAtStr);
        if (updatedAt != null && DateTime.now().difference(updatedAt).inDays < 7) {
          final list = (cached['data'] as List).map((e) => Faculty.fromMap(e)).toList();
          final withPhoto = list.where((f) => f.photoUrl != null && f.photoUrl!.isNotEmpty).length;
          debugPrint('🎓 FACULTY DIRECTORY (CACHE): total=${list.length}, withPhoto=$withPhoto');
          if (withPhoto > 0) {
            final sample = list.firstWhere((f) => f.photoUrl != null && f.photoUrl!.isNotEmpty);
            debugPrint('📸 Sample Photo in cache: ${sample.shortName} -> ${sample.photoUrl}');
          }
          return list;
        }
      }
    }

    return await _fetchAndCache();
  }

  Future<List<Faculty>> _fetchAndCache() async {
    try {
      // Fetch from the MASTER table directly
      final data = await _supabase
          .from('faculty_master')
          .select('id, full_name, short_name, email, designation_name, photo_url, office_room')
          .order('full_name', ascending: true);

      final list = data as List;
      final results = list.map((e) => Faculty.fromMap(e)).toList();
      final withPhoto = results.where((f) => f.photoUrl != null && f.photoUrl!.isNotEmpty).length;
      debugPrint('🎓 FACULTY DIRECTORY (SUPABASE): total=${results.length}, withPhoto=$withPhoto');
      if (withPhoto > 0) {
        final sample = results.firstWhere((f) => f.photoUrl != null && f.photoUrl!.isNotEmpty);
        debugPrint('📸 Sample Photo from DB: ${sample.shortName} -> ${sample.photoUrl}');
      }

      // Update Cache
      _cache.setMapData('faculty', 'directory', {
        'data': results.map((e) => e.toMap()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return results;
    } catch (e) {
      if (kDebugMode) print('Failed to fetch faculty directory: $e');
      return [];
    }
  }

  Future<List<Faculty>> searchFaculty(String query) async {
    if (query.isEmpty) return getAllFaculty();
    
    try {
      final data = await _supabase
          .from('faculty_master')
          .select('id, full_name, short_name, email, designation_name, photo_url, office_room')
          .or('full_name.ilike.%$query%,short_name.ilike.%$query%,email.ilike.%$query%')
          .order('full_name', ascending: true);
          
      return (data as List).map((e) => Faculty.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) print('Search failed: $e');
      return [];
    }
  }

  Future<List<CourseSection>> getFacultySections(String initials, String semesterCode) async {
    final safeSem = semesterCode.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    final tableName = 'courses_$safeSem';
    try {
      final data = await _supabase
          .from(tableName)
          .select()
          .ilike('faculty_initials', initials);

      return (data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        map['id'] = map['id']?.toString() ?? e['course_code'];
        map['code'] = map['course_code'] ?? map['code'];
        map['section'] = map['section_number'] ?? map['section'];
        map['sessions'] = (map['schedule_data'] as List? ?? []).map((s) {
          final sessionMap = Map<String, dynamic>.from(s);
          sessionMap['start_time'] = sessionMap['startTime'] ?? sessionMap['start_time'];
          sessionMap['end_time'] = sessionMap['endTime'] ?? sessionMap['end_time'];
          return sessionMap;
        }).toList();
        map['capacity'] = map['capacity']?.toString() ?? '0/0';
        map['credits'] = map['credit_val']?.toString() ?? '3.0';
        return CourseSection.fromJson(map);
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Failed to fetch faculty sections: $e');
      return [];
    }
  }
}

@riverpod
FacultyRepository facultyRepository(FacultyRepositoryRef ref) {
  return FacultyRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(cacheServiceProvider),
  );
}

@riverpod
Future<List<Faculty>> allFaculty(AllFacultyRef ref) {
  return ref.watch(facultyRepositoryProvider).getAllFaculty();
}

@riverpod
Future<List<CourseSection>> facultySections(
  FacultySectionsRef ref, {
  required String initials,
  required String semesterCode,
}) {
  return ref
      .watch(facultyRepositoryProvider)
      .getFacultySections(initials, semesterCode);
}
