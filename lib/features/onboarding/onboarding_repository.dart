import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/utils/course_utils.dart';
import '../auth/auth_providers.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(Supabase.instance.client, ref);
});

class OnboardingRepository {
  final SupabaseClient _client;
  final Ref _ref;

  OnboardingRepository(this._client, this._ref);

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    // In our live database schema, the programs logic has slightly shifted.
    // Fetch unique departments mapping to explicit tracks from the new tables.
    final data = await _client
        .from('programs')
        .select('department_name, track, program_code, name');

    // Group them uniquely into old shape
    final departments = <String, Map<String, dynamic>>{};
    for (var row in data) {
      final rawDept = row['department_name'] as String;
      final deptKey = rawDept.trim().toLowerCase();
      final deptDisplay = rawDept.trim();
      
      if (!departments.containsKey(deptKey)) {
        departments[deptKey] = {
          'name': deptDisplay,
          'track': row['track'],
          'programs': <Map<String, String>>[],
        };
      }
      (departments[deptKey]!['programs'] as List).add({
        'id': row['program_code'] as String,
        'title': row['name'] as String,
      });
    }
    return departments.values.toList();
  }

  Future<List<String>> fetchSemesters() async {
    final data = await _client
        .from('semesters')
        .select('code');
    
    var list = data.map((e) => e['code'] as String).where((s) => !s.contains('_')).toList();

    // Sort chronologically: Year first, then Spring (1) -> Summer (2) -> Fall (3)
    list.sort((a, b) {
      final reg = RegExp(r'^([a-zA-Z]+)(\d{4})$');
      final matchA = reg.firstMatch(a);
      final matchB = reg.firstMatch(b);

      if (matchA != null && matchB != null) {
        final yearA = int.parse(matchA.group(2)!);
        final yearB = int.parse(matchB.group(2)!);

        if (yearA != yearB) return yearA.compareTo(yearB);

        int getSeasonWeight(String s) {
          final season = s.toLowerCase();
          if (season.contains('spring')) return 1;
          if (season.contains('summer')) return 2;
          if (season.contains('fall')) return 3;
          return 4;
        }

        return getSeasonWeight(matchA.group(1)!).compareTo(
          getSeasonWeight(matchB.group(1)!),
        );
      }
      return a.compareTo(b);
    });

    return list.reversed.toList(); // Newest first
  }

  Future<void> saveProgram(
    String programId,
    String programName,
    String department,
    String admittedSemester,
    String semType,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final programCode = programId.toUpperCase();

    // 1. Fetch current profile to detect if program/dept/admitted_semester has changed
    final existing = await _client
        .from('profiles')
        .select('program_code, department_name, admitted_semester')
        .eq('id', user.id)
        .maybeSingle();

    bool hasChanged = false;
    if (existing != null) {
      final oldProg = existing['program_code']?.toString().toUpperCase();
      final oldDept = existing['department_name']?.toString();
      final oldAdm = CourseUtils.cleanSemester(existing['admitted_semester']?.toString() ?? '');
      
      final newProg = programCode.toUpperCase();
      final newAdm = CourseUtils.cleanSemester(admittedSemester ?? '');

      if (oldProg != newProg || oldDept != department || oldAdm != newAdm) {
        hasChanged = true;
      }
    }

    // 2. If program details changed, clear previous course history/enrollments for a fresh start
    if (hasChanged) {
      await Future.wait([
        _client.from('completed_courses').delete().eq('user_id', user.id),
        _client.from('enrollments').delete().eq('user_id', user.id),
        _client.from('semester_course_marks').delete().eq('user_id', user.id),
      ]);
    }

    // 3. Save the new program details
    final payload = {
      'id': user.id,
      'program_code': programCode,
      'program_name': programName,
      'department_name': department,
      'admitted_semester': admittedSemester, // Keep original for display but comparison is clean
      'semester_type': semType,
      'track': semType,
      'onboarding_status': 'course_history',
    };

    // Safety: If profile doesn't exist, provide basic fallback info to avoid constraint violations
    if (existing == null) {
      final meta = user.userMetadata;
      payload['full_name'] = meta?['full_name'] ?? meta?['name'] ?? meta?['displayName'] ?? 'Student';
      payload['nickname'] = payload['full_name'].toString().split(' ').first;
    }

    await _client.from('profiles').upsert(payload);

    _ref.invalidate(profileProvider);
  }

    Future<void> completeOnboarding() async {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
        .from('profiles')
        .update({'onboarding_status': 'completed'})
        .eq('id', user.id);

    _ref.invalidate(profileProvider);
  }

  // Stubs for Course History Screen refactor. Implement carefully later.
  Future<Map<String, dynamic>> getActiveSemesterConfig() async {
    final user = _client.auth.currentUser;
    if (user == null) return {'track': null, 'current_semester_code': null};

    // 1. Get the user's track from their profile
    final profile = await _client
        .from('profiles')
        .select('semester_type, track')
        .eq('id', user.id)
        .maybeSingle();
    
    final rawTrack = profile?['track'] ?? profile?['semester_type'] ?? 'tri_semester';
    String track = rawTrack.toString().toLowerCase();
    
    // NORMALIZE: Ensure track matches DB Enum ('tri' -> 'tri_semester')
    if (track == 'tri') track = 'tri_semester';
    if (track == 'bi') track = 'bi_semester';

    // 2. Get the active semester configuration for that track
    final activeSem = await _client
        .from('active_semester')
        .select('current_semester_code')
        .eq('track', track)
        .maybeSingle();

    return {
      'track': track,
      'current_semester_code': activeSem?['current_semester_code'],
    };
  }

  Future<List<String>> getAllSemesters({required String semesterType}) async {
    final data = await _client
        .from('semesters')
        .select('code')
        .order('created_at', ascending: true);
    var list = data.map((e) => e['code'] as String).toList();

    // Filter out duplicates that contain underscores (e.g. summer_2025)
    list = list.where((s) => !s.contains('_')).toList();

    if (semesterType == 'bi_semester') {
      list = list.where((s) => !s.toLowerCase().contains('summer')).toList();
    }

    // Sort chronologically: Year first, then Spring (1) -> Summer (2) -> Fall (3)
    list.sort((a, b) {
      final reg = RegExp(r'^([a-zA-Z]+)(\d{4})$');
      final matchA = reg.firstMatch(a);
      final matchB = reg.firstMatch(b);

      if (matchA != null && matchB != null) {
        final yearA = int.parse(matchA.group(2)!);
        final yearB = int.parse(matchB.group(2)!);

        if (yearA != yearB) return yearA.compareTo(yearB);

        int getSeasonWeight(String s) {
          final season = s.toLowerCase();
          if (season.contains('spring')) return 1;
          if (season.contains('summer')) return 2;
          if (season.contains('fall')) return 3;
          return 4;
        }

        return getSeasonWeight(
          matchA.group(1)!,
        ).compareTo(getSeasonWeight(matchB.group(1)!));
      }
      return a.compareTo(b); // Fallback
    });

    return list;
  }

  Future<void> saveProfileDetails({
    required String fullName,
    required String nickname,
    required String studentId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'nickname': nickname,
      'student_id': studentId,
    });

    _ref.invalidate(profileProvider);
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final user = _client.auth.currentUser;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .maybeSingle();
    return data ?? {};
  }

  Future<void> recalculateStats([String? semesterCode]) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      final syncScheduleBody = {
        'user_id': user.id,
      };
      if (semesterCode != null) {
        syncScheduleBody['semester_code'] = CourseUtils.cleanSemester(semesterCode);
      }

      await Future.wait([
        _client.functions.invoke(
          'sync-academic-stats',
          body: {'user_id': user.id},
        ),
        _client.functions.invoke(
          'sync-schedule',
          body: syncScheduleBody,
        ),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('[OnboardingRepo] Recalc/Sync Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCompletedCourses() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('completed_courses')
        .select('course_code, semester_code, grade')
        .eq('user_id', user.id);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchActiveEnrollments() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('enrollments')
        .select('course_code, section_id, section, semester_code')
        .eq('user_id', user.id);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchCourseCatalog({
    String? semester,
    bool isCurrent = false,
    String searchQuery = '',
  }) async {
    if (isCurrent && semester != null) {
      final safeSem = CourseUtils.cleanSemester(semester ?? '');
      final tableName = 'courses_$safeSem';
      try {
        var query = _client
            .from(tableName)
            .select(
              'id, course_code, course_name, credit_val, section_number, faculty_initials, schedule_data',
            );
        if (searchQuery.isNotEmpty) {
          query = query.or(
            'course_code.ilike.%$searchQuery%,course_name.ilike.%$searchQuery%',
          );
        }
        final data = await query;
        return (data as List)
            .map<Map<String, dynamic>>(
              (e) => {
                'id': e['id'],
                'code': e['course_code'],
                'name': e['course_name'],
                'credit_val': e['credit_val'],
                'section': e['section_number'],
                'faculty': e['faculty_initials'],
                'schedule': e['schedule_data'],
              },
            )
            .toList();
      } catch (e) {
        if (kDebugMode) debugPrint('[OnboardingRepo] Catalog table $tableName not found, falling back to metadata');
        // Fallback to metadata if term-specific catalog is not yet populated
        return fetchCourseCatalog(semester: semester, isCurrent: false, searchQuery: searchQuery);
      }
    } else {
      var query = _client
          .from('course_metadata')
          .select('code, name, credit_val');
      if (searchQuery.isNotEmpty) {
        query = query.or('code.ilike.%$searchQuery%,name.ilike.%$searchQuery%');
      }
      final data = await query;
      return (data as List)
          .map<Map<String, dynamic>>(
            (e) => {
              'code': e['code'],
              'name': e['name'],
              'credit_val': e['credit_val'],
            },
          )
          .toList();
    }
  }

  Future<void> saveCourseHistory(
    Map<String, Map<String, String>> history,
    List<String> enrolledIds,
    String runningSemester, {
    List<Map<String, dynamic>>? enrolledCourseDetails,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    final cleanRunningSemester = CourseUtils.cleanSemester(runningSemester);

    // Clean up existing data to reflect removals accurately
    await _client
        .from('completed_courses')
        .delete()
        .eq('user_id', user.id);
    
    await _client
        .from('enrollments')
        .delete()
        .eq('user_id', user.id)
        .eq('semester_code', cleanRunningSemester);

    // 1. Prepare data for completed_courses
    final List<Map<String, dynamic>> completedRows = [];

    // Helper for basic grade point calculation (The Edge Function will final-verify this)
    double simpleGradePoint(String grade) {
      switch (grade.toUpperCase()) {
        case 'A':
          return 4.0;
        case 'A-':
          return 3.7;
        case 'B+':
          return 3.3;
        case 'B':
          return 3.0;
        case 'B-':
          return 2.7;
        case 'C+':
          return 2.3;
        case 'C':
          return 2.0;
        case 'C-':
          return 1.7;
        case 'D+':
          return 1.3;
        case 'D':
          return 1.0;
        default:
          return 0.0;
      }
    }

    // Fetch metadata to get accurate credits
    final metadata = await _client
        .from('course_metadata')
        .select('code, credit_val');
    final Map<String, double> creditsMap = {
      for (var m in (metadata as List))
        (m['code'] as String): (m['credit_val'] as num).toDouble(),
    };
    
    history.forEach((semester, courses) {
      if (semester.replaceAll(' ', '') == cleanRunningSemester) return;
      courses.forEach((code, grade) {
        completedRows.add({
          'user_id': user.id,
          'course_code': code,
          'semester_code': semester,
          'grade': grade,
          'grade_point': simpleGradePoint(grade),
          'credits': creditsMap[code] ?? 3.0,
        });
      });
    });

    try {
      // 2. Perform bulk insert on completed_courses
      if (completedRows.isNotEmpty) {
        await _client.from('completed_courses').insert(completedRows);
      }

      // 2.5 Insert ongoing active explicitly into enrollments
      if (enrolledCourseDetails != null && enrolledCourseDetails.isNotEmpty) {
        final List<Map<String, dynamic>> enrollmentRows = [];
        for (final detail in enrolledCourseDetails) {
          final rawCode = detail['code'].toString();
          final cleanCode = rawCode.contains('_') ? rawCode.split('_')[0] : rawCode;
          final section = rawCode.contains('_Sec') ? rawCode.split('_Sec')[1] : (detail['section'] ?? '');
          
          if (detail['id'] == null) continue;
          
          enrollmentRows.add({
            'user_id': user.id,
            'course_code': cleanCode,
            'section_id': detail['id'],
            'section': section,
            'semester_code': cleanRunningSemester,
            'status': 'enrolled',
          });
        }
        if (enrollmentRows.isNotEmpty) {
          try {
            await _client.from('enrollments').insert(enrollmentRows);
          } catch (e) {
            throw Exception("Failed to save enrollments: $e");
          }
          
          // Initialize progress entries for each enrolled course
          final List<Map<String, dynamic>> progressRows = [];
          final Set<String> seenCodes = {}; // Prevention: UPSERT fails if input has duplicates
          
          for (final detail in enrolledCourseDetails) {
            final rawCode = detail['code'].toString();
            final cleanCode = rawCode.contains('_') ? rawCode.split('_')[0] : rawCode;
            final section = rawCode.contains('_Sec') ? rawCode.split('_Sec')[1] : (detail['section'] ?? '');
            
            if (seenCodes.contains(cleanCode)) continue;
            seenCodes.add(cleanCode);
            
            progressRows.add({
              'user_id': user.id,
              'course_code': cleanCode,
              'course_name': detail['name'] ?? '',
              'section': section,
              'semester_code': cleanRunningSemester,
            });
          }
          
          if (progressRows.isNotEmpty) {
            try {
              await _client.from('semester_course_marks').upsert(
                progressRows, 
                onConflict: 'user_id,course_code,semester_code'
              );
            } catch (e) {
              debugPrint("[OnboardingRepo] Progress Init Warning (Non-Fatal): $e");
              // We don't throw here to allow the user to finish onboarding even if progress rows fail
            }
          }
        }
      }

      // 3. Update enrolled sections in profiles
      await _client
          .from('profiles')
          .update({'enrolled_sections': enrolledIds})
          .eq('id', user.id);

      // 4. Trigger recalculation
      await recalculateStats(runningSemester);
    } catch (e) {
      debugPrint('[OnboardingRepo] Save History Error: $e');
      rethrow;
    }
  }
}
