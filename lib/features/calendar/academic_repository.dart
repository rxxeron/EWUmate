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

  // Realtime stream of the active semester configuration
  Stream<Map<String, dynamic>> streamActiveSemesterConfig() {
    return _supabase
        .from('active_semester')
        .stream(primaryKey: ['id'])
        .map((data) {
          if (data.isNotEmpty) {
            final config = data.first;
            OfflineCacheService().cacheAcademicConfig(config);
            _configCache = config;
            return config;
          }
          return _configCache;
        });
  }

  Future<String> getCurrentSemesterCode() async {
    final active = await getActiveSemesterConfig();
    return active['current_semester_code'] ?? 'Spring2026';
  }

  Future<Map<String, dynamic>> getActiveSemesterConfig() async {
    final cached = OfflineCacheService().getCachedAcademicConfig();
    if (cached != null) {
      _configCache = cached;
      _refreshConfigInBackground(); 
      return _configCache;
    }

    if (await ConnectivityService().isOnline()) {
      await _fetchAndCacheActiveConfig().timeout(
        const Duration(seconds: 3),
        onTimeout: () => debugPrint("AcademicRepo: Config fetch timed out."),
      );
    }
    
    return _configCache;
  }

  Future<void> _fetchAndCacheActiveConfig() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Get user's profile info
      final profile = await _supabase
          .from('profiles')
          .select('department, semester_type')
          .eq('id', user.id)
          .maybeSingle();
 
      final deptName = profile?['department'] ?? '';
      String? semesterType = profile?['semester_type'];
      
      // 2. If semester_type not in profile (old user), fetch from departments
      if (semesterType == null && deptName.isNotEmpty) {
        final deptTable = await _supabase
            .from('departments')
            .select('semester_type')
            .eq('name', deptName)
            .maybeSingle();
        semesterType = deptTable?['semester_type'];
      }
      
      semesterType ??= 'tri';

      // 3. Fetch specific active record matching that semester_type
      final res = await _supabase
          .from('active_semester')
          .select()
          .eq('semester_type', semesterType)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (res != null) {
        _configCache = Map<String, dynamic>.from(res);
        await OfflineCacheService().cacheAcademicConfig(_configCache);
        debugPrint("AcademicRepo: Config cached for $deptName (Cycle: $semesterType)");
      }
    } catch (e) {
      debugPrint("Error fetching active semester config: $e");
    }
  }

  void _refreshConfigInBackground() async {
    if (!(await ConnectivityService().isOnline())) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final profile = await _supabase
          .from('profiles')
          .select('department, semester_type')
          .eq('id', user.id)
          .maybeSingle();
 
      final deptName = profile?['department'] ?? '';
      String? semesterType = profile?['semester_type'];
      
      if (semesterType == null && deptName.isNotEmpty) {
        final deptTable = await _supabase
            .from('departments')
            .select('semester_type')
            .eq('name', deptName)
            .maybeSingle();
        semesterType = deptTable?['semester_type'];
      }
      
      semesterType ??= 'tri';

      final res = await _supabase
          .from('active_semester')
          .select()
          .eq('semester_type', semesterType)
          .maybeSingle();

      if (res != null) {
        final freshConfig = Map<String, dynamic>.from(res);
        if (freshConfig['current_semester_code'] != _configCache['current_semester_code']) {
           _configCache = freshConfig;
           await OfflineCacheService().cacheAcademicConfig(_configCache);
           debugPrint("[AcademicRepo] Config refreshed in background for $semesterType cycle.");
        }
      }
    } catch (_) {}
  }

  Future<void> promoteSemester() async {
    if (!(await ConnectivityService().isOnline())) {
      debugPrint("[AcademicRepo] Offline: Skipping semester promotion RPC.");
      return;
    }
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

  /// Fetches the full list of semesters from the database (Spring 2020 -> Current)
  Future<List<String>> getAllSemesters() async {
    try {
      final res = await _supabase
          .from('semesters')
          .select('name')
          .order('year', ascending: true)
          .order('season', ascending: false); // Note: Fall > Summer > Spring alphabetically is tricky, but works for most EWU seasons

      final List<String> names = (res as List).map((s) => s['name'].toString()).toList();
      
      if (names.isNotEmpty) return names;
    } catch (e) {
      debugPrint("Error fetching semesters table: $e");
    }

    // Fallback if table is empty or fetch fails
    return [
      "Spring 2023", "Summer 2023", "Fall 2023",
      "Spring 2024", "Summer 2024", "Fall 2024",
      "Spring 2025", "Summer 2025", "Fall 2025",
      "Spring 2026"
    ];
  }

  Future<bool> isSemesterActive(String semesterCode) async {
    final actives = await getActiveSemesterCodes();
    final clean = semesterCode.replaceAll(' ', '');
    return actives.any((a) => a.replaceAll(' ', '') == clean);
  }

  Future<List<AcademicEvent>> fetchHolidays(String semesterCode) async {
    final semesterType = _configCache['semester_type'] ?? 'tri';
    final cacheKey = CourseUtils.safeCacheKey('holidays', semesterCode, cycleType: semesterType);
    
    final cached = OfflineCacheService().getCachedHolidays(cacheKey);
    if (cached.isNotEmpty) {
      return cached.map((e) => AcademicEvent.fromMap(e)).toList();
    }

    try {
      final isBi = semesterType == 'bi';
      final events = await _fetchHolidaysFromSupabase(semesterCode);
      
      // If Bi-semester, also fetch standard holidays if not already the same table
      if (isBi) {
        final stdEvents = await _fetchHolidaysFromSupabase(semesterCode, forceStandard: true);
        final seen = events.map((e) => "${e.date}_${e.title}").toSet();
        for (var e in stdEvents) {
          if (!seen.contains("${e.date}_${e.title}")) {
            events.add(e);
          }
        }
      }

      if (events.isNotEmpty) {
        await OfflineCacheService().cacheHolidays(cacheKey, events.map((e) => e.toMap()).toList());
      }
      return events;
    } catch (e) {
      debugPrint("Error fetching holidays for $semesterCode: $e");
      return [];
    }
  }

  Future<List<AcademicEvent>> _fetchHolidaysFromSupabase(String semesterCode, {bool forceStandard = false}) async {
    final cleanSem = semesterCode.replaceAll(' ', '').toLowerCase();
    
    // Check if we are in a bi-semester cycle from the cached config
    final semesterType = _configCache['semester_type']?.toString();
    final tableName = CourseUtils.semesterTable('calendar', semesterCode, cycleType: forceStandard ? null : semesterType);

    try {
      final data = await _supabase.from(tableName).select();
      return (data as List)
          .map((d) => AcademicEvent(
              date: (d['date'] ?? d['date_string'] ?? '').toString(),
              title: (d['name'] ?? d['event'] ?? d['title'] ?? '').toString()))
          .toList();
    } catch (e) {
      if (tableName.contains('_phrm_llb')) {
        // Fallback to standard if departmental table doesn't exist
        debugPrint("Dept calendar $tableName not found, falling back to standard.");
        return _fetchHolidaysFromSupabase(semesterCode, forceStandard: true); 
      }
      debugPrint("Error fetching holidays: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchExamSchedule(
      String semesterCode) async {
    final semesterType = _configCache['semester_type'] ?? 'tri';
    final cacheKey = CourseUtils.safeCacheKey('exams', semesterCode, cycleType: semesterType);

    // 1. Try cache first
    final cached = OfflineCacheService().getCachedSemesterSummaryMap(cacheKey);
    if (cached != null) {
      return (cached['exams'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    try {
      final semesterType = _configCache['semester_type']?.toString();
      final isBi = semesterType == 'bi';
      
      // Fetch data from standard table
      final standardTable = CourseUtils.semesterTable('exams', semesterCode);
      final stdData = await _supabase.from(standardTable).select();
      final List<Map<String, dynamic>> examList = List<Map<String, dynamic>>.from(stdData as List? ?? []);

      // If bi-semester, also fetch departmental exams and merge
      if (isBi) {
        final deptTable = CourseUtils.semesterTable('exams', semesterCode, cycleType: 'bi');
        try {
          final deptData = await _supabase.from(deptTable).select();
          final List<Map<String, dynamic>> deptList = List<Map<String, dynamic>>.from(deptData as List? ?? []);
          
          // Merge logic: Add if not already present (checking by course code)
          final seenCodes = examList.map((e) => e['code']?.toString()).toSet();
          for (var deptExam in deptList) {
             if (!seenCodes.contains(deptExam['code']?.toString())) {
               examList.add(deptExam);
             }
          }
        } catch (e) {
          debugPrint("Note: Dept exam table $deptTable might not exist yet: $e");
        }
      }

      // 2. Update cache
      if (examList.isNotEmpty) {
        await OfflineCacheService().cacheSemesterSummaryMap(cacheKey, {'exams': examList});
      }
      
      return examList;
    } catch (e) {
      debugPrint("Error fetching exams for $semesterCode: $e");
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
  Future<DateTime?> getFinalExamDate(String semesterCode, {String? courseCode}) async {
    String sem = semesterCode;
    
    // If course provided, determine which calendar to use based on course prefix
    if (courseCode != null) {
      final upper = courseCode.toUpperCase();
      if (upper.startsWith("PHRM") || upper.startsWith("LAW")) {
        sem = "${semesterCode}_phrm_llb";
      }
    }

    final event = await findEvent(sem, [
      "Final Examinations",
      "Final Exam",
      "Final Exams Begin",
    ]);
    if (event == null) return null;
    return parseDateForHolidays(event.date, semesterCode);
  }

  /// Gets the "Submission of Final Grades" date for a semester
  Future<DateTime?> getFinalGradeSubmissionDate(String semesterCode) async {
    String sem = semesterCode;
    // Grade submission ALWAYS follows the user's active cycle
    if (_configCache['semester_type'] == 'bi') {
      sem = "${semesterCode}_phrm_llb";
    }

    final event = await findEvent(sem, [
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

      // 2. Fallback to keyword search in the appropriate calendar
      String sem = currentSemesterCode;
      if (_configCache['semester_type'] == 'bi') {
        sem = "${currentSemesterCode}_phrm_llb";
      }

      final event = await findEvent(sem, [
        "Online Advising of Courses",
        "Online Advising",
        "Advising of Courses",
      ]);
      if (event == null && sem.contains('_phrm_llb')) {
        // Fallback to standard if department-specific event not found
        return getOnlineAdvisingDate(currentSemesterCode.replaceAll('_phrm_llb', ''));
      }

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
    String sem = currentSemesterCode;
    if (_configCache['semester_type'] == 'bi') {
      sem = "${currentSemesterCode}_phrm_llb";
    }

    final event = await findEvent(sem, [
      "Adding of Courses",
      "Add Courses",
      "Course Add",
    ]);
    if (event == null && sem.contains('_phrm_llb')) {
       return getAddingOfCoursesDate(currentSemesterCode.replaceAll('_phrm_llb', ''));
    }

    if (event == null) return null;
    return parseDateForHolidays(event.date, currentSemesterCode);
  }

  /// Determines the next semester code based on current
  /// Spring -> Summer, Summer -> Fall, Fall -> Spring (next year)
  /// EXCEPT for Bi-semester: Spring -> Fall (skipping Summer)
  String getNextSemesterCode(String currentCode) {
    final isBi = _configCache['semester_type'] == 'bi';
    
    // Parse current code (e.g., "Spring2026" or "Fall2026")
    final regExp = RegExp(r'(Spring|Summer|Fall)(\d{4})');
    final match = regExp.firstMatch(currentCode);
    if (match == null) {
      final year = DateTime.now().year;
      return isBi ? 'Fall$year' : 'Summer$year';
    }

    final season = match.group(1) ?? 'Spring';
    final yearStr = match.group(2);
    final year = yearStr != null ? int.parse(yearStr) : DateTime.now().year;

    switch (season) {
      case 'Spring':
        return isBi ? 'Fall$year' : 'Summer$year';
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
      final parts = dateStr.replaceAll(',', '').split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length < 2) return null;

      final extracted = _extractDateComponents(parts);
      int? day = extracted['day'];
      int? month = extracted['month'];
      int? year = extracted['year'];

      if (year == null && contextStr != null) {
        year = _inferYear(contextStr);
      }
      year ??= DateTime.now().year;

      if (day != null && month != null) {
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint("Date parse error: $e");
    }
    return null;
  }

  Map<String, int?> _extractDateComponents(List<String> parts) {
    const months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };

    int? day, month, year;
    for (var p in parts) {
      final lower = p.toLowerCase();
      if (months.containsKey(lower)) {
        month = months[lower];
      } else {
        final num = int.tryParse(p);
        if (num != null) {
          if (num > 31) {
            year = num;
          } else {
            day = num;
          }
        }
      }
    }
    return {'day': day, 'month': month, 'year': year};
  }

  int? _inferYear(String contextStr) {
    final yearMatch = RegExp(r'\d{4}').firstMatch(contextStr);
    return yearMatch != null ? int.parse(yearMatch.group(0)!) : null;
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
      final config = await getActiveSemesterConfig();
      final cycleType = config['semester_type']?.toString();

      final actualTable = isActive 
          ? CourseUtils.semesterTable('courses', semesterCode, cycleType: cycleType) 
          : 'courses';

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
