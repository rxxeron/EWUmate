import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class OnboardingRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      debugPrint('[Onboarding] Fetching departments from metadata...');
      final data = await _supabase
          .from('metadata')
          .select('data')
          .eq('id', 'departments')
          .single()
          .timeout(const Duration(seconds: 5));

      final departmentsData = data['data'];
      if (departmentsData != null && departmentsData['list'] is List) {
        debugPrint('[Onboarding] Departments loaded from DB');
        return List<Map<String, dynamic>>.from(departmentsData['list']);
      }
    } catch (e) {
      debugPrint("Error fetching departments (using fallback): $e");
    }

    return [
      {
        "name": "Dept. of CSE",
        "programs": [
          {"id": "cse_eng", "name": "B.Sc. in Computer Science & Engineering"},
          {
            "id": "cse_ice",
            "name": "B.Sc. in Information & Communication Engineering"
          }
        ]
      },
      {
        "name": "Dept. of Business",
        "programs": [
          {"id": "bba", "name": "Bachelor of Business Administration"},
          {"id": "mba", "name": "Master of Business Administration"}
        ]
      },
      {
        "name": "Dept. of EEE",
        "programs": [
          {"id": "eee", "name": "B.Sc. in Electrical & Electronic Engineering"},
          {
            "id": "ete",
            "name": "B.Sc. in Electronics & Telecommunication Engineering"
          }
        ]
      },
      {
        "name": "Dept. of Pharmacy",
        "programs": [
          {"id": "pha_b", "name": "Bachelor of Pharmacy"},
          {"id": "pha_m", "name": "Master of Pharmacy"}
        ]
      },
      {
        "name": "Dept. of English",
        "programs": [
          {"id": "eng_ba", "name": "B.A. in English"}
        ]
      },
      {
        "name": "Dept. of Sociology",
        "programs": [
          {"id": "soc_bss", "name": "B.S.S. in Sociology"}
        ]
      },
      {
        "name": "Dept. of Economics",
        "programs": [
          {"id": "eco_bss", "name": "B.S.S. in Economics"}
        ]
      },
      {
        "name": "Dept. of GEB",
        "programs": [
          {"id": "geb", "name": "B.Sc. in Genetic Engineering & Biotechnology"}
        ]
      }
    ];
  }

  Future<void> saveProgram(
      String programId, String deptName, String admittedSemester) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'program_id': programId,
      'department': deptName,
      'admitted_semester': admittedSemester,
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

      for (var code in currentCourses.keys) {
        if (!coursesMap.containsKey(code)) {
          final detail = detailsMap[code];
          coursesMap[code] = {
            'courseCode': code,
            'courseName': detail?['name'] ?? code,
            'section': detail?['section'] ?? '',
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
      });
      debugPrint("Onboarding: Live courses initialized for $safeSem");
    }
  }

  Future<List<Map<String, dynamic>>> fetchCourseCatalog(
      {String? semester, bool isCurrent = false, String? searchQuery}) async {
    final queryStr = searchQuery?.toUpperCase().replaceAll(' ', '').trim();

    // CURRENT semester → query 'courses' table for sections with schedules
    if (isCurrent && semester != null) {
      try {
        var queryBuilder = _supabase.from('courses').select();
        if (queryStr != null && queryStr.isNotEmpty) {
          queryBuilder = queryBuilder.ilike('code', '%$queryStr%');
        }

        final List<dynamic> data = await queryBuilder
            .eq('semester', semester)
            .limit(100)
            .timeout(const Duration(seconds: 8));

        if (data.isNotEmpty) {
          final groups = <String, Map<String, dynamic>>{};

          for (var d in data) {
            final rawCode = d['code'] ?? "???";
            final code = rawCode.toString().replaceAll(' ', '');
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
            }

            if (!groups.containsKey(key)) {
              groups[key] = {
                'id': d['doc_id'] ?? d['id'].toString(),
                'allIds': [d['doc_id'] ?? d['id'].toString()],
                'code': code,
                'name':
                    (d['course_name'] ?? d['courseName'] ?? rawCode).toString(),
                'section': section,
                'schedules': [schedule],
              };
            } else {
              groups[key]!['allIds'].add(d['doc_id'] ?? d['id'].toString());
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
        }
      } catch (e) {
        debugPrint("Courses table error: $e");
      }
    }

    // PAST semesters (or fallback) → query 'course_metadata' directly
    try {
      debugPrint('[Onboarding] Loading courses from course_metadata...');
      var queryBuilder = _supabase.from('course_metadata').select();

      if (queryStr != null && queryStr.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('code', '%$queryStr%');
      }

      final List<dynamic> list =
          await queryBuilder.limit(200).timeout(const Duration(seconds: 8));
      debugPrint(
          '[Onboarding] Found ${list.length} courses in course_metadata');
      return list.map((m) {
        final rawCode = (m['code'] ?? '???').toString();
        final code = rawCode.replaceAll(' ', '');
        return {
          'code': code,
          'name': (m['name'] ?? rawCode).toString(),
        };
      }).toList();
    } catch (e) {
      debugPrint("course_metadata error: $e");
    }

    return [];
  }
}
