import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/academic_event_model.dart';
import '../../core/models/course_model.dart';
import '../../core/utils/course_utils.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/connectivity_service.dart';

class AcademicRepository {
  final _supabase = Supabase.instance.client;

  // Determines current semester code from active_semester table
  static Map<String, dynamic> _configCache = {
    'current_semester_code': 'Spring2026',
    'current_semester_start_date': '2026-01-18',
    'next_semester_code': 'Summer2026',
    'upcoming_semester_start_date': '2026-05-24'
  };

  Map<String, dynamic> getActiveSemesterConfigCache() => _configCache;

  Future<String> getCurrentSemesterCode() async {
    final active = await getActiveSemesterConfig();
    return active['current_semester_code'] ?? 'Spring2026';
  }

  Future<Map<String, dynamic>> getActiveSemesterConfig() async {
    // 1. Try cache first
    final cached = OfflineCacheService().getCachedAcademicConfig();
    if (cached != null) {
      _configCache = cached;
      // If we have cache, we can return it immediately and refresh in background
      _refreshConfigInBackground(); 
      return _configCache;
    }

    // 2. No cache, must wait for network if online
    if (await ConnectivityService().isOnline()) {
      try {
        final res = await _supabase
            .from('active_semester')
            .select()
            .eq('is_active', true)
            .maybeSingle();

        if (res != null) {
          _configCache = Map<String, dynamic>.from(res);
          await OfflineCacheService().cacheAcademicConfig(_configCache);
        }
      } catch (e) {
        debugPrint("Error fetching active semester config: $e");
      }
    }
    
    return _configCache;
  }

  void _refreshConfigInBackground() async {
    if (!(await ConnectivityService().isOnline())) return;
    try {
      final res = await _supabase
          .from('active_semester')
          .select()
          .eq('is_active', true)
          .maybeSingle();

      if (res != null) {
        final freshConfig = Map<String, dynamic>.from(res);
        if (freshConfig['active_semester'] != _configCache['active_semester']) {
           _configCache = freshConfig;
           await OfflineCacheService().cacheAcademicConfig(_configCache);
           debugPrint("[AcademicRepo] Config refreshed in background.");
        }
      }
    } catch (_) {}
  }

  Future<void> promoteSemester() async {
    try {
      await _supabase.rpc('promote_active_semester');
      await getActiveSemesterConfig(); // Refresh cache
    } catch (e) {
      debugPrint("Error promoting semester: $e");
    }
  }

  Future<List<String>> getActiveSemesterCodes() async {
    final config = await getActiveSemesterConfig();
    return [
      (config['current_semester_code'] ?? '').toString(),
      (config['next_semester_code'] ?? '').toString(),
    ].where((s) => s.isNotEmpty).toList();
  }

  Future<bool> isSemesterActive(String semesterCode) async {
    final actives = await getActiveSemesterCodes();
    final clean = semesterCode.replaceAll(' ', '');
    return actives.any((a) => a.replaceAll(' ', '') == clean);
  }

  Future<List<AcademicEvent>> fetchHolidays(String semesterCode) async {
    final cleanSem = semesterCode.replaceAll(' ', '');
    // 1. Try cache first
    final cached = OfflineCacheService().getCachedHolidays(cleanSem);
    if (cached.isNotEmpty) {
      return cached.map((e) => AcademicEvent.fromMap(e)).toList();
    }

    try {
      // Table names are lowercase in Postgres (e.g. calendar_spring2026)
      final tableName = 'calendar_${cleanSem.toLowerCase()}';
      final data = await _supabase
          .from(tableName)
          .select();

      final events = (data as List)
          .map((d) => AcademicEvent(
              date: d['date'] ?? d['date_string'] ?? '',
              title: d['name'] ?? d['event'] ?? d['title'] ?? ''))
          .toList();

      // 2. Update cache
      await OfflineCacheService().cacheHolidays(cleanSem, events.map((e) => e.toMap()).toList());

      return events;
    } catch (e) {
      debugPrint("Error fetching holidays for $semesterCode: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchExamSchedule(
      String semesterCode) async {
    // 1. Try cache first
    final cached = OfflineCacheService().getCachedSemesterSummaryMap("${semesterCode}_exams");
    if (cached != null) {
      return (cached['exams'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final data =
          await _supabase.from(CourseUtils.semesterTable('exams', semesterCode)).select();
      
      final examList = List<Map<String, dynamic>>.from(data as List? ?? []);
      // 2. Update cache
      await OfflineCacheService().cacheSemesterSummaryMap("${semesterCode}_exams", {'exams': examList});
      
      return examList;
    } catch (e) {
      debugPrint("Error fetching exams: $e");
      return [];
    }
  }


  /// Fetches pre-generated personalized schedule from Cloud
  Future<Map<String, dynamic>?> fetchPersonalizedSchedule(
      String userId, String semesterCode) async {
    try {
      final data = await _supabase
          .from('user_schedules')
          .select()
          .eq('user_id', userId)
          .single();

      return data;
    } catch (e) {
      debugPrint("Error fetching personalized schedule: $e");
      return null;
    }
  }

  /// Finds an event by matching keywords in the title
  Future<AcademicEvent?> findEvent(
      String semesterCode, List<String> keywords) async {
    final events = await fetchHolidays(semesterCode);
    try {
      return events.firstWhere((e) => keywords
          .any((kw) => e.title.toLowerCase().contains(kw.toLowerCase())));
    } catch (e) {
      return null;
    }
  }

  /// Gets the "First Day of Classes" date for a semester
  Future<DateTime?> getFirstDayOfClasses(String semesterCode) async {
    final event = await findEvent(semesterCode, [
      "First Day of Classes",
      "Classes Begin",
      "Semester Begins",
    ]);
    if (event == null) return null;
    return parseDateForHolidays(event.date, semesterCode);
  }

  /// Gets the "Last Day of Classes" date for a semester
  Future<DateTime?> getLastDayOfClasses(String semesterCode) async {
    final event = await findEvent(semesterCode, [
      "Last Day of Classes",
      "Classes End",
      "End of Classes",
    ]);
    if (event == null) return null;
    return parseDateForHolidays(event.date, semesterCode);
  }

  /// Gets the "Final Examinations" start date for a semester
  Future<DateTime?> getFinalExamDate(String semesterCode) async {
    final event = await findEvent(semesterCode, [
      "Final Examinations",
      "Final Exam",
      "Final Exams Begin",
    ]);
    if (event == null) return null;
    return parseDateForHolidays(event.date, semesterCode);
  }

  /// Gets the "Submission of Final Grades" date for a semester
  Future<DateTime?> getFinalGradeSubmissionDate(String semesterCode) async {
    final event = await findEvent(semesterCode, [
      "Submission of Final Grades",
      "Final Grades Submission",
      "Grade Submission",
    ]);
    if (event == null) return null;
    return parseDateForHolidays(event.date, semesterCode);
  }

  /// Gets the "Online Advising of Courses" date for the NEXT semester
  Future<DateTime?> getOnlineAdvisingDate(String currentSemesterCode) async {
    try {
      // 1. Try to fetch from consolidated active_semester table first
      final config = await getActiveSemesterConfig();
      if (config['advising_start_date'] != null) {
        return DateTime.parse(config['advising_start_date'] as String);
      }

      // 2. Fallback to keyword search in calendar
      final event = await findEvent(currentSemesterCode, [
        "Online Advising of Courses",
        "Online Advising",
        "Advising of Courses",
      ]);
      if (event == null) return null;
      return parseDateForHolidays(event.date, currentSemesterCode);
    } catch (e) {
      debugPrint("Error fetching advising date: $e");
      return null;
    }
  }

  /// Gets the grade submission window from active_semester table
  Future<Map<String, DateTime?>> getGradeSubmissionWindow() async {
    try {
      final config = await getActiveSemesterConfig();
      return {
        'start': config['grade_submission_start'] != null 
            ? DateTime.parse(config['grade_submission_start'] as String) 
            : null,
        'deadline': config['grade_submission_deadline'] != null 
            ? DateTime.parse(config['grade_submission_deadline'] as String) 
            : null,
      };
    } catch (e) {
      debugPrint("Error fetching grade submission window: $e");
      return {'start': null, 'deadline': null};
    }
  }

  /// Gets the "Adding of Courses" date for the NEXT semester
  Future<DateTime?> getAddingOfCoursesDate(String currentSemesterCode) async {
    final event = await findEvent(currentSemesterCode, [
      "Adding of Courses",
      "Add Courses",
      "Course Add",
    ]);
    if (event == null) return null;
    return parseDateForHolidays(event.date, currentSemesterCode);
  }

  /// Determines the next semester code based on current
  /// Spring -> Summer, Summer -> Fall, Fall -> Spring (next year)
  String getNextSemesterCode(String currentCode) {
    // Parse current code (e.g., "Spring2026" or "Fall2026")
    final regExp = RegExp(r'(Spring|Summer|Fall)(\d{4})');
    final match = regExp.firstMatch(currentCode);
    if (match == null) {
      // Fallback
      final year = DateTime.now().year;
      return 'Summer$year';
    }

    final season = match.group(1) ?? 'Spring';
    final yearStr = match.group(2);
    final year = yearStr != null ? int.parse(yearStr) : DateTime.now().year;

    switch (season) {
      case 'Spring':
        return 'Summer$year';
      case 'Summer':
        return 'Fall$year';
      case 'Fall':
        return 'Spring${year + 1}';
      default:
        return 'Summer$year';
    }
  }

  /// Parses date strings like "14 April 2026" or "April 14, 2026" or "March 15"
  /// [contextStr] can be a semester code (Spring2026) to help infer year if missing
  DateTime? parseDateForHolidays(String dateStr, [String? contextStr]) {
    try {
      final months = {
        'january': 1,
        'february': 2,
        'march': 3,
        'april': 4,
        'may': 5,
        'june': 6,
        'july': 7,
        'august': 8,
        'september': 9,
        'october': 10,
        'november': 11,
        'december': 12,
      };

      final parts = dateStr
          .replaceAll(',', '')
          .split(' ')
          .where((p) => p.isNotEmpty)
          .toList();

      // Need at least day and month
      if (parts.length < 2) return null;

      int? day, month, year;

      for (var p in parts) {
        final lower = p.toLowerCase();
        if (months.containsKey(lower)) {
          month = months[lower];
        } else if (int.tryParse(p) != null) {
          final num = int.parse(p);
          if (num > 31) {
            year = num;
          } else {
            day = num;
          }
        }
      }

      // If year is missing, try to infer from context (e.g. Spring2026)
      if (year == null && contextStr != null) {
        final yearMatch = RegExp(r'\d{4}').firstMatch(contextStr);
        if (yearMatch != null) {
          year = int.parse(yearMatch.group(0)!);
        }
      }

      // Default to current year if still missing (fallback)
      year ??= DateTime.now().year;

      if (day != null && month != null) {
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint("Date parse error: $e");
    }
    return null;
  }

  /// Fetches enrolled courses for the given semester by checking user profile
  Future<List<Course>> fetchEnrolledCourses(String semesterCode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // 1. Get enrolled IDs from profile
      final res = await _supabase
          .from('profiles')
          .select('enrolled_sections')
          .eq('id', user.id)
          .single();
      
      final enrolledIds = List<String>.from(res['enrolled_sections'] ?? []);
      if (enrolledIds.isEmpty) return [];

      // 2. Fetch course details from the correct semester table
      final isActive = await isSemesterActive(semesterCode);
      final actualTable = isActive ? CourseUtils.semesterTable('courses', semesterCode) : 'courses';

      final data = await _supabase
          .from(actualTable)
          .select()
          .inFilter('doc_id', enrolledIds);

      return (data as List)
          .map<Course>((d) => Course.fromSupabase(
                Map<String, dynamic>.from(d),
                (d['doc_id'] ?? d['id'] ?? '').toString(),
              ))
          .toList();
    } catch (e) {
      debugPrint("Error fetching enrolled courses for $semesterCode: $e");
      return [];
    }
  }
}
