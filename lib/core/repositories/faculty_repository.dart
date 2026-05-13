import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faculty.dart';
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
          return (cached['data'] as List).map((e) => Faculty.fromMap(e)).toList();
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
          .select('id, full_name, short_name, email, designation_name, photo_url')
          .order('full_name', ascending: true);

      final list = data as List;
      final results = list.map((e) => Faculty.fromMap(e)).toList();

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
          .select('id, full_name, short_name, email, designation_name, photo_url')
          .or('full_name.ilike.%$query%,short_name.ilike.%$query%,email.ilike.%$query%')
          .order('full_name', ascending: true);
          
      return (data as List).map((e) => Faculty.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) print('Search failed: $e');
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
