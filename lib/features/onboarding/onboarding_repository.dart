import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../features/calendar/academic_repository.dart';
import '../../core/services/schedule_service.dart';
import '../../core/utils/course_utils.dart';
import '../../core/services/offline_cache_service.dart';

class OnboardingRepository {
  final _supabase = Supabase.instance.client;
  final _academicRepo = AcademicRepository();
  final _scheduleService = ScheduleService();

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    // 1. Try Disk Cache first
    final cached = OfflineCacheService().getCachedDepartments();
    if (cached != null) {
      debugPrint('[Onboarding] Departments loaded from disk cache');
      return cached;
    }

    try {
      debugPrint('[Onboarding] Fetching structured departments...');
      final data = await _supabase
          .from('departments')
          .select('id, name, programs, semester_type')
          .timeout(const Duration(seconds: 5));

      if (data.isNotEmpty) {
        debugPrint('[Onboarding] Departments loaded from remote DB');
        final List<Map<String, dynamic>> departments = List<Map<String, dynamic>>.from(data);
        departments.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        
        // Save to disk cache
        await OfflineCacheService().cacheDepartments(departments);
        
        return departments;
      }
    } catch (e) {
      debugPrint("Error fetching structured departments: $e");
    }

    return []; // Return empty if truly offline and no cache
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};
    
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data ?? {};
    } catch (e) {
      debugPrint("Error fetching user profile in onboarding: $e");
      return {};
    }
  }

  Future<void> saveProgram(
      String programId, String deptName, String admittedSemester, String semesterType) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");
 
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'program_id': programId,
      'department': deptName,
      'admitted_semester': admittedSemester,
      'semester_type': semesterType,
      'onboarding_status': 'program_selected',
    });
  }

  /// Saves course history, separating Live (Current) vs Archived (Past) semesters
  Future<void> saveCourseHistory(Map<String, Map<String, String>> history,
      List<String> enrolledIds, String currentSemester,
      {List<Map<String, dynamic>>? enrolledCourseDetails}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final pastHistory = Map<String, Map<String, String>>.from(history);
    final Map<String, String> currentCourses =
        pastHistory.remove(currentSemester) ?? {};

    // 3. Save Profile with enrollment details
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'enrolled_sections': enrolledIds,
      'onboarding_status': 'onboarded',
    });

    // 4. Save Academic Data (raw map → Azure Function will enrich with credits + names)
    await _supabase.from('academic_data').upsert({
      'user_id': user.id,
      'semesters': pastHistory,
    });

    // 5. Initialize Live Semester with course details
    if (currentCourses.isNotEmpty) {
      final safeSem = currentSemester.replaceAll(" ", "");

      final results = await _supabase
          .from('semester_progress')
          .select()
          .eq('user_id', user.id)
          .eq('semester_code', safeSem)
          .maybeSingle();

      Map<String, dynamic> summary = results?['summary'] ?? {};
      Map<String, dynamic> coursesMap = summary['courses'] ?? {};

      // Build a lookup from enrolledCourseDetails if provided
      final detailsMap = <String, Map<String, dynamic>>{};
      if (enrolledCourseDetails != null) {
        for (var detail in enrolledCourseDetails) {
          final code = (detail['code'] ?? '').toString();
          if (code.isNotEmpty) detailsMap[code] = detail;
        }
      }

      // Deduplicate current courses by base code (e.g., MAT102 vs MAT102_Sec4)
      final Set<String> uniqueBaseCodes = {};
      final List<String> deduplicatedCodes = [];
      for (var code in currentCourses.keys) {
        final base = code.split('_')[0].toUpperCase();
        if (!uniqueBaseCodes.contains(base)) {
          uniqueBaseCodes.add(base);
          deduplicatedCodes.add(code); // Keep the first specific code found
        }
      }

      for (var code in deduplicatedCodes) {
        // If we have a base code variant already, skip or prioritize the base one
        final base = code.split('_')[0].toUpperCase();
        if (!coursesMap.containsKey(base)) {
          final detail = detailsMap[code] ?? detailsMap[base];
          coursesMap[base] = {
            'courseCode': base,
            'courseName': detail?['name'] ?? base,
            'section': detail?['section'] ?? (code.contains('_Sec') ? code.split('_Sec')[1] : ''),
            'schedule': detail?['time'] ?? '',
            'distribution': {},
            'obtained': {'quizzes': [], 'shortQuizzes': []},
            'quizStrategy': 'bestN',
          };
        }
      }

      summary['courses'] = coursesMap;

      await _supabase.from('semester_progress').upsert({
        'user_id': user.id,
        'semester_code': safeSem,
        'summary': summary,
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, semester_code');
      debugPrint("Onboarding: Live courses initialized for $safeSem");

      // Trigger schedule sync
      await _scheduleService.syncUserSchedule(currentSemester, enrolledIds);
    }
  }

  Future<List<Map<String, dynamic>>> fetchCourseCatalog(
      {String? semester, bool isCurrent = false, String? searchQuery}) async {
    final queryStr = searchQuery?.toUpperCase().replaceAll(' ', '').trim();

    // Normalization logic: Bidirectional loose matching (104 <-> 7104)
    String? normalizedQuery;
    if (queryStr != null && queryStr.isNotEmpty) {
      // Case 1: Search is 3 digits (e.g., CSE104) -> also check 7-prefixed (CSE7104)
      final match3 = RegExp(r'^([A-Z]*?)(\d{3})$').firstMatch(queryStr);
      if (match3 != null) {
        final letters = match3.group(1) ?? "";
        final digits = match3.group(2)!;
        normalizedQuery = "${letters}7$digits";
      } 
      // Case 2: Search is 4 digits starting with 7 (e.g., CSE7104) -> also check 3-digit (CSE104)
      else {
        final match4 = RegExp(r'^([A-Z]*?)7(\d{3})$').firstMatch(queryStr);
        if (match4 != null) {
          final letters = match4.group(1) ?? "";
          final digits = match4.group(2)!;
          normalizedQuery = "$letters$digits";
        }
      }
    }

    // Determine if we should use dynamic sections (Active) or Metadata (Past)
    bool useDynamic = false;
    if (semester != null) {
      useDynamic = await _academicRepo.isSemesterActive(semester);
    }

    if (useDynamic) {
      try {
        final config = await _academicRepo.getActiveSemesterConfig();
        final cycleType = config['semester_type']?.toString();
        
        final actualTable = CourseUtils.semesterTable('courses', semester!, cycleType: cycleType);
        
        var queryBuilder = _supabase.from(actualTable).select();

        if (queryStr != null && queryStr.isNotEmpty) {
          if (normalizedQuery != null) {
            queryBuilder = queryBuilder.or('code.ilike.%$queryStr%,code.ilike.%$normalizedQuery%');
          } else {
            queryBuilder = queryBuilder.ilike('code', '%$queryStr%');
          }
        }

        List<dynamic> data = await queryBuilder
            .limit(500)
            .timeout(const Duration(seconds: 10));

        // IMPROVED LOGIC: Only fallback if the table itself is empty or missing, 
        // NOT just because a specific search returned no results.
        if (data.isEmpty && (queryStr == null || queryStr.isEmpty)) {
          debugPrint('[Onboarding] $actualTable is empty. Trying global "courses" table...');
          var globalQuery = _supabase.from('courses').select();
          data = await globalQuery.limit(500).timeout(const Duration(seconds: 10));
        }

        if (data.isNotEmpty) {
          final groups = <String, Map<String, dynamic>>{};

          for (var dRaw in data) {
            final d = Map<String, dynamic>.from(dRaw as Map);
            final rawCode = (d['code'] ?? d['course_code'] ?? "???").toString();
            final code = rawCode.replaceAll(' ', '');
            final section = (d['section'] ?? 'N/A').toString();
            final key = "${code}_Sec$section";

            String schedule = "TBA";
            if (d['sessions'] is List && (d['sessions'] as List).isNotEmpty) {
              final sessions = d['sessions'] as List;
              final scheduleList = sessions.map((s) {
                final day = s['day'] ?? 'TBA';
                final start = s['start_time'] ?? s['startTime'] ?? '??';
                final end = s['end_time'] ?? s['endTime'] ?? '??';
                return "$day $start-$end";
              }).toList();
              schedule = scheduleList.join(", ");
            } else if (d['time'] != null) {
              schedule = d['time'].toString();
            }

            if (!groups.containsKey(key)) {
              groups[key] = {
                'id': (d['doc_id'] ?? d['id'] ?? d['code']).toString(),
                'allIds': [(d['doc_id'] ?? d['id'] ?? d['code']).toString()],
                'code': code,
                'name': (d['course_name'] ?? d['courseName'] ?? d['name'] ?? d['title'] ?? rawCode).toString(),
                'section': section,
                'schedules': [schedule],
              };
            } else {
              groups[key]!['allIds'].add((d['doc_id'] ?? d['id'] ?? d['code']).toString());
              groups[key]!['schedules'].add(schedule);
            }
          }

          return groups.values.map((g) {
            return {
              ...g,
              'time': (g['schedules'] as List).join(", "),
              'day': "",
            };
          }).toList();
        } else {
          // If active table is totally empty (e.g., scraper hasn't run yet for Summer 2025), fallback to course_metadata
          // But ONLY if we were looking for the full list (no search query)
          if (queryStr == null || queryStr.isEmpty) {
            debugPrint('[Onboarding] Dynamic table "$actualTable" is empty. Falling back to course_metadata.');
            useDynamic = false;
          } else {
             debugPrint('[Onboarding] Search query returned no results in $actualTable.');
             return []; // Just return empty list, don't fall back to metadata UI mode
          }
        }
      } catch (e) {
        debugPrint("[Onboarding] Dynamic table error: $e");
        useDynamic = false; // Trigger fallback on error too
      }
    }

    if (!useDynamic) {
      // FALLBACK: Use course_metadata for Past Semesters (or empty Active Semesters)
      try {
      debugPrint('[Onboarding] Loading courses from course_metadata...');

      var queryBuilder = _supabase.from('course_metadata').select();

      if (queryStr != null && queryStr.isNotEmpty) {
        if (normalizedQuery != null) {
          queryBuilder = queryBuilder.or('code.ilike.%$queryStr%,code.ilike.%$normalizedQuery%');
        } else {
          queryBuilder = queryBuilder.ilike('code', '%$queryStr%');
        }
      }

      final List<dynamic> list = await queryBuilder.limit(1000); 

      return list.map((m) {
        final rawCode = (m['code'] ?? '???').toString();
        // Normalize code for UI
        final code = rawCode.replaceAll(' ', '');
        return {
          'code': code,
          'name': (m['name'] ?? m['title'] ?? rawCode).toString(), 
        };
      }).toList();
    } catch (e) {
      debugPrint("course_metadata error: $e");
    }
    }

    return [];
  }
}
