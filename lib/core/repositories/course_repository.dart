import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_metadata.dart';
import '../models/course_section.dart';
import '../providers/supabase_provider.dart';

part 'course_repository.g.dart';

class CourseRepository {
  final SupabaseClient _supabase;

  CourseRepository(this._supabase);

  Future<List<CourseMetadata>> getAllCourses({int offset = 0, int limit = 3000}) async {
    try {
      List<CourseMetadata> allResults = [];
      int currentOffset = offset;
      const int pageSize = 1000; // Standard Supabase limit
      
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
        
        // If we got fewer than requested, we reached the end
        if (list.length < fetchSize) break;
      }

      return allResults;
    } catch (e) {
      throw Exception('Failed to load courses: $e');
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
    String table = 'courses_$safeSem';

    // Add cycle type if needed from legacy logic (bi-semester phrm or law)
    final isBi = cycleType == 'bi' || cycleType == 'bi_semester';
    final programSpecifier = (isBi && !table.endsWith('_phrm_llb'))
        ? '_phrm_llb'
        : '';
    final tableName = '$table$programSpecifier';

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
    final safeSem = semesterCode
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    final tableName = 'courses_$safeSem';

    try {
      int currentOffset = 0;
      const int pageSize = 1000;
      const int limit = 5000; // Hard max loop threshold to prevent infinite runaway
      final Map<String, CourseMetadata> unique = {};

      while (currentOffset < limit) {
        final res = await _supabase
            .from(tableName)
            .select('course_code, course_name')
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
            creditVal: 3.0,
          );
        }
        
        currentOffset += list.length;
        if (list.length < pageSize) break; // Reached the end of the data
      }
      
      return unique.values.toList();
    } catch (e) {
      return [];
    }
  }
}

@riverpod
CourseRepository courseRepository(CourseRepositoryRef ref) {
  return CourseRepository(ref.watch(supabaseClientProvider));
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
