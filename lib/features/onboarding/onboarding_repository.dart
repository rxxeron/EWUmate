import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../features/calendar/academic_repository.dart';
import '../../core/services/schedule_service.dart';
import '../../core/utils/course_utils.dart';

class OnboardingRepository {
  final _supabase = Supabase.instance.client;
  final _academicRepo = AcademicRepository();
  final _scheduleService = ScheduleService();

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      debugPrint('[Onboarding] Fetching structured departments...');
      final data = await _supabase
          .from('departments')
          .select('id, name, programs, semester_type')
          .timeout(const Duration(seconds: 5));

      if (data.isNotEmpty) {
        debugPrint('[Onboarding] Departments loaded from new structured DB');
        // Sort by name for better UX
        final List<Map<String, dynamic>> departments = List<Map<String, dynamic>>.from(data);
        departments.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        return departments;
      }
    } catch (e) {
      debugPrint("Error fetching structured departments (using fallback): $e");
    }

    return [
      {
        "name": "Dept. of Computer Science & Engineering",
        "programs": [
          {
            "id": "cse",
            "name": "B.Sc. in Computer Science & Engineering",
            "credits": 140
          },
          {
            "id": "ice",
            "name": "B.Sc. in Information & Communications Engineering",
            "credits": 140
          }
        ]
      },
      {
        "name": "Dept. of Electronics & Communications Engineering",
        "programs": [
          {
            "id": "ete",
            "name": "B.Sc. in Electronic & Telecommunication Engineering",
            "credits": 140
          }
        ]
      },
      {
        "name": "Dept. of Electrical & Electronic Engineering",
        "programs": [
          {
            "id": "eee",
            "name": "B.Sc. in Electrical & Electronic Engineering",
            "credits": 140
          }
        ]
      },
      {
        "name": "Dept. of Civil Engineering",
        "programs": [
          {
            "id": "ce",
            "name": "B.Sc. in Civil Engineering",
            "credits": 156.5
          }
        ]
      },
      {
        "name": "Dept. of Pharmacy",
        "programs": [
          {
            "id": "pharm",
            "name": "Bachelor of Pharmacy (B.Pharm) Professional",
            "credits": 158
          }
        ]
      },
      {
        "name": "Dept. of Genetic Engineering & Biotechnology",
        "programs": [
          {
            "id": "geb",
            "name": "B.Sc. in Genetic Engineering & Biotechnology",
            "credits": 133
          }
        ]
      },
      {
        "name": "Dept. of Mathematical & Physical Sciences",
        "programs": [
          {
            "id": "dsa",
            "name": "B.Sc. in Data Science & Analytics",
            "credits": 130
          },
          {
            "id": "math",
            "name": "B.Sc. (Hons) in Mathematics",
            "credits": 128
          }
        ]
      },
      {
        "name": "Dept. of Business Administration",
        "programs": [
          {
            "id": "bba",
            "name": "Bachelor of Business Administration",
            "credits": 123
          }
        ]
      },
      {
        "name": "Dept. of Economics",
        "programs": [
          {
            "id": "eco",
            "name": "B.S.S. (Hons) in Economics",
            "credits": 123
          }
        ]
      },
      {
        "name": "Dept. of English",
        "programs": [
          {
            "id": "eng",
            "name": "B.A. (Hons) in English",
            "credits": 123
          }
        ]
      },
      {
        "name": "Dept. of Sociology",
        "programs": [
          {
            "id": "soc",
            "name": "B.S.S. (Hons) in Sociology",
            "credits": 123
          }
        ]
      },
      {
        "name": "Dept. of Information Studies & Library Management",
        "programs": [
          {
            "id": "islm",
            "name": "B.S.S. in Info. Studies & Library Management",
            "credits": 123
          }
        ]
      },
      {
        "name": "Dept. of Law",
        "programs": [
          {
            "id": "law",
            "name": "LL.B. (Hons)",
            "credits": 135
          }
        ]
      },
      {
        "name": "Dept. of Social Relations",
        "programs": [
          {
            "id": "pphs",
            "name": "B.S.S. in Population and Public Health Sciences",
            "credits": 123
          }
        ]
      }
    ];
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
      debugPrint('[Onboarding Diagnostic] Semester: "$semester", isSemesterActive: $useDynamic');
    }

    if (useDynamic) {
      try {
        final config = await _academicRepo.getActiveSemesterConfig();
        final cycleType = config['semester_type']?.toString();
        
        final actualTable = CourseUtils.semesterTable('courses', semester!, cycleType: cycleType);
        debugPrint('[Onboarding Diagnostic] Querying dynamic table: "$actualTable"');
        
        var queryBuilder = _supabase.from(actualTable).select();

        if (queryStr != null && queryStr.isNotEmpty) {
          if (normalizedQuery != null) {
            queryBuilder = queryBuilder.or('code.ilike.%$queryStr%,code.ilike.%$normalizedQuery%');
          } else {
            queryBuilder = queryBuilder.ilike('code', '%$queryStr%');
          }
        }

        final List<dynamic> data = await queryBuilder
            .limit(500)
            .timeout(const Duration(seconds: 10));

        debugPrint('[Onboarding Diagnostic] Dynamic table query returned ${data.length} results.');

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
                'name': (d['course_name'] ?? d['courseName'] ?? rawCode).toString(),
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
        } else {
          // If active table is totally empty (e.g., scraper hasn't run yet for Summer 2025), fallback to course_metadata
          debugPrint('[Onboarding Diagnostic] Dynamic table "$actualTable" returned no results. Falling back to course_metadata.');
          useDynamic = false; // Trigger fallback
        }
      } catch (e) {
        debugPrint("[Onboarding Diagnostic] Dynamic table error: $e");
        useDynamic = false; // Trigger fallback on error too
      }
    }

    if (!useDynamic) {
      // FALLBACK: Use course_metadata for Past Semesters (or empty Active Semesters)
      try {
      debugPrint('[Onboarding Diagnostic] Falling back to course_metadata...');

      var queryBuilder = _supabase.from('course_metadata').select();

      if (queryStr != null && queryStr.isNotEmpty) {
        if (normalizedQuery != null) {
          queryBuilder = queryBuilder.or('code.ilike.%$queryStr%,code.ilike.%$normalizedQuery%');
        } else {
          queryBuilder = queryBuilder.ilike('code', '%$queryStr%');
        }
      }

      final List<dynamic> list = await queryBuilder.limit(1000); 

      debugPrint('[Onboarding Diagnostic] Found ${list.length} courses in course_metadata');

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
      debugPrint("[Onboarding Diagnostic] course_metadata error: $e");
    }
    }

    return [];
  }
}
