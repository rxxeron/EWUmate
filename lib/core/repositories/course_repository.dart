import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_metadata.dart';
import '../models/course_section.dart';
import '../providers/supabase_provider.dart';
import '../services/cache_service.dart';

part 'course_repository.g.dart';

class CourseRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;

  CourseRepository(this._supabase, this._cache);

  Future<List<CourseMetadata>> getAllCourses({int offset = 0, int limit = 3000}) async {
    // 1. Try cache first
    final cached = _cache.getMapData('course_catalog', 'full_list');
    if (cached != null && cached['data'] != null) {
      final updatedAtStr = cached['updated_at'] as String?;
      bool isStale = true;
      if (updatedAtStr != null) {
        final updatedAt = DateTime.tryParse(updatedAtStr);
        if (updatedAt != null && DateTime.now().difference(updatedAt).inDays < 7) {
          isStale = false;
        }
      }
      if (isStale) {
        // Trigger background sync if cache is older than 7 days
        _fetchAllAndCache(offset, limit);
      }
      return (cached['data'] as List).map((e) => CourseMetadata.fromJson(e)).toList();
    }

    return await _fetchAllAndCache(offset, limit);
  }

  Future<List<CourseMetadata>> _fetchAllAndCache(int offset, int limit) async {
    try {
      List<CourseMetadata> allResults = [];
      int currentOffset = offset;
      const int pageSize = 1000;
      
      while (allResults.length < limit) {
        final remaining = limit - allResults.length;
        final fetchSize = remaining < pageSize ? remaining : pageSize;
        
        final data = await _supabase
            .from('course_metadata')
            .select()
            .order('code', ascending: true)
            .range(currentOffset, currentOffset + fetchSize - 1);

        final List<dynamic> list = data as List;
        if (list.isEmpty) break;

        allResults.addAll(list.map((e) => CourseMetadata.fromJson(e)));
        currentOffset += list.length;
        if (list.length < fetchSize) break;
      }

      // Update Cache
      _cache.setMapData('course_catalog', 'full_list', {
        'data': allResults.map((e) => e.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return allResults;
    } catch (e) {
      if (kDebugMode) print('Failed to load courses from network: $e');
      return [];
    }
  }

  Future<List<CourseMetadata>> searchCourses(String query) async {
    if (query.isEmpty) return getAllCourses();

    try {
      final data = await _supabase
          .from('course_metadata')
          .select()
          .textSearch('code', "$query:*")
          .order('code', ascending: true);

      if ((data as List).isEmpty) {
        // Fallback to name search
        final nameData = await _supabase
            .from('course_metadata')
            .select()
            .ilike('name', "%$query%")
            .order('code', ascending: true);
        return (nameData as List)
            .map((e) => CourseMetadata.fromJson(e))
            .toList();
      }

      return data.map((e) => CourseMetadata.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to search courses: $e');
    }
  }

  Future<List<CourseSection>> getCourseSections(
    String semesterCode,
    String courseCode, {
    String? cycleType,
  }) async {
    // Basic formatting from original app -> "Spring 2026" / "spring_2026" -> "spring2026"
    final safeSem = semesterCode
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    final tableName = 'courses_$safeSem';

    try {
      final String base = courseCode.replaceAll(' ', '').toUpperCase();
      String alt = '';
      
      // Heuristic: ACT101 <-> ACT7101
      final reg3 = RegExp(r'^([A-Z]{2,4})(\d{3})$');
      final reg4 = RegExp(r'^([A-Z]{2,4})7(\d{3})$');
      
      if (reg3.hasMatch(base)) {
        final match = reg3.firstMatch(base)!;
        alt = '${match.group(1)}7${match.group(2)}';
      } else if (reg4.hasMatch(base)) {
        final match = reg4.firstMatch(base)!;
        alt = '${match.group(1)}${match.group(2)}';
      }

      final String fuzzyBase = base.split('').join('%');
      final String orClause = alt.isNotEmpty 
          ? 'course_code.ilike.%$fuzzyBase%,course_code.ilike.%${alt.split('').join('%')}%'
          : 'course_code.ilike.%$fuzzyBase%';

      final data = await _supabase
          .from(tableName)
          .select()
          .or(orClause);

      return (data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        // Fallback ids if they don't exactly map
        map['id'] = map['id']?.toString() ?? e['course_code'];
        map['code'] = map['course_code'] ?? map['code'];
        map['section'] = map['section_number'] ?? map['section'];
        map['sessions'] = (map['schedule_data'] as List? ?? []).map((s) {
          final sessionMap = Map<String, dynamic>.from(s);
          // Standardize for the current model generator (which expects snake_case)
          sessionMap['start_time'] = sessionMap['startTime'] ?? sessionMap['start_time'];
          sessionMap['end_time'] = sessionMap['endTime'] ?? sessionMap['end_time'];
          return sessionMap;
        }).toList();
        
        map['capacity'] = map['capacity']?.toString() ?? '0/0';
        map['credits'] = map['credit_val']?.toString() ?? '3.0';
        return CourseSection.fromJson(map);
      }).toList();
    } catch (e) {
      // Legacy app returned empty list on missing table/error
      return [];
    }
  }
  Future<List<CourseMetadata>> getSemesterCourses(String semesterCode) async {
    final cacheKey = 'sem_${semesterCode.toLowerCase()}';
    
    int? serverVersion;
    try {
      final configRes = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', 'catalog_cache_version')
          .maybeSingle();
      if (configRes != null && configRes['value'] != null) {
        serverVersion = (configRes['value']['version'] as num?)?.toInt();
      }
    } catch (_) {}

    final cached = _cache.getMapData('course_catalog', cacheKey);
    if (cached != null && cached['data'] != null && (cached['data'] as List).isNotEmpty) {
      final cachedVersion = (cached['version'] as num?)?.toInt() ?? 0;
      if (serverVersion != null && serverVersion > cachedVersion) {
        return await _fetchSemesterAndCache(semesterCode, cacheKey, serverVersion: serverVersion);
      }

      final updatedAtStr = cached['updated_at'] as String?;
      bool isStale = true;
      if (updatedAtStr != null) {
        final updatedAt = DateTime.tryParse(updatedAtStr);
        if (updatedAt != null && DateTime.now().difference(updatedAt).inDays < 7) {
          isStale = false;
        }
      }
      if (isStale) {
        // Trigger background sync if cache is older than 7 days
        _fetchSemesterAndCache(semesterCode, cacheKey, serverVersion: serverVersion);
      }
      return (cached['data'] as List).map((e) => CourseMetadata.fromJson(e)).toList();
    }

    return await _fetchSemesterAndCache(semesterCode, cacheKey, serverVersion: serverVersion);
  }

  Future<List<CourseMetadata>> _fetchSemesterAndCache(String semesterCode, String cacheKey, {int? serverVersion}) async {
    final safeSem = semesterCode
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    final tableName = 'courses_$safeSem';

    try {
      int currentOffset = 0;
      const int pageSize = 1000;
      const int limit = 20000;
      final Map<String, CourseMetadata> unique = {};

      while (currentOffset < limit) {
        final res = await _supabase
            .from(tableName)
            .select('course_code, course_name, credit_val')
            .order('course_code', ascending: true)
            .range(currentOffset, currentOffset + pageSize - 1);
        
        final list = res as List;
        if (list.isEmpty) break;

        for (final e in list) {
          final code = (e['course_code'] ?? '').toString();
          if (code.isEmpty || unique.containsKey(code)) continue;
          
          unique[code] = CourseMetadata(
            code: code,
            name: (e['course_name'] ?? e['name'] ?? 'Unknown').toString(),
            creditVal: (e['credit_val'] as num?)?.toDouble() ?? 3.0,
          );
        }
        
        currentOffset += list.length;
        if (list.length < pageSize) break;
      }
      
      final results = unique.values.toList();

      // Only cache non-empty results to prevent caching bad/corrupt table loads
      if (results.isNotEmpty) {
        _cache.setMapData('course_catalog', cacheKey, {
          'data': results.map((e) => e.toJson()).toList(),
          'updated_at': DateTime.now().toIso8601String(),
          'version': serverVersion ?? 0,
        });
      }

      return results;
    } catch (e) {
      if (kDebugMode) print('Database Error in getSemesterCourses: $e');
      return [];
    }
  }
}

@riverpod
CourseRepository courseRepository(CourseRepositoryRef ref) {
  return CourseRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(cacheServiceProvider),
  );
}

@riverpod
Future<List<CourseMetadata>> allCourses(AllCoursesRef ref) {
  return ref.watch(courseRepositoryProvider).getAllCourses(limit: 3000);
}

@riverpod
Future<List<CourseMetadata>> semesterCourses(SemesterCoursesRef ref, String semesterCode) {
  return ref.watch(courseRepositoryProvider).getSemesterCourses(semesterCode);
}

@riverpod
Future<List<CourseSection>> courseSections(
  CourseSectionsRef ref, {
  required String semesterCode,
  required String courseCode,
}) {
  return ref
      .watch(courseRepositoryProvider)
      .getCourseSections(semesterCode, courseCode);
}
