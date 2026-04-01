import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final dept = row['department_name'] as String;
      if (!departments.containsKey(dept)) {
        departments[dept] = {
          'name': dept,
          'track': row['track'],
          'programs': <Map<String, String>>[],
        };
      }
      (departments[dept]!['programs'] as List).add({
        'id': row['program_code'] as String,
        'title': row['name'] as String,
      });
    }
    return departments.values.toList();
  }

  Future<List<String>> fetchSemesters() async {
    final data = await _client
        .from('semesters')
        .select('code')
        .order('created_at', ascending: false);
    var list = data.map((e) => e['code'] as String).toList();
    // Filter out duplicates that contain underscores
    return list.where((s) => !s.contains('_')).toList();
  }

  Future<void> saveProgram(
    String programCode,
    String department,
    String admittedSemester,
    String semType,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    await _client
        .from('profiles')
        .update({
          'program_code': programCode,
          'department_name': department,
          'admitted_semester': admittedSemester,
          'semester_type': semType,
          'track': semType,
        })
        .eq('id', user.id);

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

    final activeSem = await _client
        .from('semesters')
        .select('code')
        .eq('is_active', true)
        .maybeSingle();
    final profile = await _client
        .from('profiles')
        .select('semester_type')
        .eq('id', user.id)
        .maybeSingle();

    return {
      'track': profile?['semester_type'],
      'current_semester_code': activeSem?['code'],
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

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final user = _client.auth.currentUser;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .maybeSingle();
    return data ?? {};
  }

  Future<void> recalculateStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await Future.wait([
        _client.functions.invoke(
          'sync-academic-stats',
          body: {'user_id': user.id},
        ),
        _client.functions.invoke('sync-schedule', body: {'user_id': user.id}),
      ]);
    } catch (e) {
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

  Future<List<Map<String, dynamic>>> fetchCourseCatalog({
    String? semester,
    bool isCurrent = false,
    String searchQuery = '',
  }) async {
    if (isCurrent && semester != null) {
      final tableName = 'courses_${semester.toLowerCase()}';
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

    // 1. Prepare data for completed_courses
    final List<Map<String, dynamic>> completedRows = [];

    // Helper for basic grade point calculation (The Edge Function will final-verify this)
    double _simpleGradePoint(String grade) {
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
      if (semester == runningSemester)
        return; // Prevent saving ongoing active courses into completed histories
      courses.forEach((code, grade) {
        completedRows.add({
          'user_id': user.id,
          'course_code': code,
          'semester_code': semester,
          'grade': grade,
          'grade_point': _simpleGradePoint(grade),
          'credits':
              creditsMap[code] ?? 3.0, // Default to 3.0 if metadata is missing
        });
      });
    });

    // 2. Perform bulk upsert on completed_courses
    if (completedRows.isNotEmpty) {
      await _client
          .from('completed_courses')
          .upsert(
            completedRows,
            onConflict: 'user_id, course_code, semester_code',
          );
    }

    // 2.5 Insert ongoing active explicitly into enrollments
    if (enrolledCourseDetails != null && enrolledCourseDetails.isNotEmpty) {
      final List<Map<String, dynamic>> enrollmentRows = [];
      for (final detail in enrolledCourseDetails) {
        enrollmentRows.add({
          'user_id': user.id,
          'course_code': detail['code'],
          'section_id': detail['id'],
          'semester_code': runningSemester,
          'status': 'enrolled',
        });
      }
      // Insert new enrollments safely ignoring duplicates
      try {
        await _client
            .from('enrollments')
            .upsert(
              enrollmentRows,
              onConflict: 'user_id, course_code, semester_code',
            );
      } catch (e) {
      }
    }

    // 3. Update enrolled sections in profiles for the current semester
    if (enrolledIds.isNotEmpty) {
      await _client
          .from('profiles')
          .update({'enrolled_sections': enrolledIds})
          .eq('id', user.id);
    }

    // 4. Trigger recalculation via Edge Function
    await recalculateStats();
  }
}
