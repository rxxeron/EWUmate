import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/course_model.dart';
import '../../core/utils/course_utils.dart';
import '../../core/services/azure_functions_service.dart';

import '../../features/calendar/academic_repository.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/schedule_cache_service.dart';
import '../../core/services/connectivity_service.dart';

class CourseRepository {
  final _supabase = Supabase.instance.client;
  final _academicRepo = AcademicRepository();

  // --- Schedule Generation via Azure Function ---

  Future<String?> triggerScheduleGeneration(String semester,
      List<String> courseCodes, Map<String, dynamic> filters) async {
    try {
      final result = await AzureFunctionsService().generateSchedules(
        semester: semester,
        courses: courseCodes,
        filters: filters,
      );
      return result['generationId'] as String?;
    } catch (e) {
      debugPrint('[CourseRepo] Schedule generation error: $e');
      return null;
    }
  }

  Stream<ScheduleGenerationResult> streamGeneratedSchedules(String generationId) {
    // Realtime stream for schedule_generations
    return _supabase
        .from('schedule_generations')
        .stream(primaryKey: ['id'])
        .eq('id', generationId)
        .map((data) => data.isNotEmpty
            ? _parseGenerationRecord(data.first)
            : ScheduleGenerationResult.empty());
  }

  Stream<ScheduleGenerationResult> streamLatestGeneratedSchedules() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(ScheduleGenerationResult.empty());

    return _supabase
        .from('schedule_generations')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) => data.isNotEmpty
            ? _parseGenerationRecord(data.first)
            : ScheduleGenerationResult.empty());
  }

  ScheduleGenerationResult _parseGenerationRecord(Map<String, dynamic> data) {
    return ScheduleGenerationResult(
      id: data['id'],
      status: data['status'] ?? 'pending',
      combinations: _parseCombinations(data),
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  List<List<Course>> _parseCombinations(Map<String, dynamic>? data) {
    if (data == null) return [];

    final combinations = List<dynamic>.from(data['combinations'] ?? []);
    List<List<Course>> resultSchedules = [];

    for (final scheduleItem in combinations) {
      if (scheduleItem is Map) {
        final sections = scheduleItem['sections'] as Map?;
        if (sections != null) {
          List<Course> schedule = [];
          final sectionsList = sections.values.toList();
          for (final courseData in sectionsList) {
            if (courseData is Map) {
              final mappedData = Map<String, dynamic>.from(courseData);
              schedule
                  .add(Course.fromSupabase(mappedData, mappedData['doc_id'] ?? mappedData['id'] ?? ''));
            }
          }
          if (schedule.isNotEmpty) {
            resultSchedules.add(schedule);
          }
        }
      }
    }
    return resultSchedules;
  }

  Future<void> clearAllGeneratedSchedules() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('schedule_generations')
        .delete()
        .eq('user_id', user.id);
  }

  // --- RESTORED METHODS ---

  Future<Map<String, dynamic>> fetchUserData() async {
    // 1. Get cached data immediately
    final cachedEnrolled = OfflineCacheService().getCachedEnrolledSections();
    final Map<String, dynamic> result = {'enrolled_sections': cachedEnrolled};

    final user = _supabase.auth.currentUser;
    if (user == null) return result;

    // 2. If we have cache, return it immediately and refresh in background
    if (cachedEnrolled.isNotEmpty) {
      _refreshUserDataInBackground(user.id);
      return result;
    }

    // 3. No cache, must wait for network if online
    if (await ConnectivityService().isOnline()) {
      try {
        final data = await _supabase.from('profiles').select().eq('id', user.id).single();
        final enrolled = ((data['enrolled_sections'] as List?) ?? []).map((e) => e.toString()).toList();
        
        // Cache to both Hive (new) and SharedPreferences (legacy/ProfileScreen compatibility)
        await OfflineCacheService().cacheAcademicProfile(data);
        await OfflineCacheService().cacheEnrolledSections(enrolled);
        await ScheduleCacheService().cacheStats(data); 
        
        return data;
      } catch (e) {
        debugPrint('[CourseRepo] Error fetching user data: $e');
      }
    }

    return result;
  }

  void _refreshUserDataInBackground(String userId) async {
    if (!(await ConnectivityService().isOnline())) return;
    try {
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      final enrolled = ((data['enrolled_sections'] as List?) ?? []).map((e) => e.toString()).toList();
      
      await OfflineCacheService().cacheAcademicProfile(data);
      await OfflineCacheService().cacheEnrolledSections(enrolled);
      await ScheduleCacheService().cacheStats(data);
      
      debugPrint('[CourseRepo] User Data refreshed in background.');
    } catch (_) {}
  }

  // Queue to prevent race conditions during rapid consecutive enroll/drop clicks
  bool _isToggling = false;
  final List<Function> _toggleQueue = [];

  Future<void> toggleEnrolled(String courseId, bool shouldEnroll,
      {String? semesterCode, String? courseName, String? courseCode}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Add this task to the queue
    _toggleQueue.add(() async {
      final profile = await fetchUserData();
      
      List<String> currentArr = List<String>.from(profile['enrolled_sections'] ?? []);
      List<String> nextArr = List<String>.from(profile['enrolled_sections_next'] ?? []);

      // Always clean up the requested course from BOTH arrays to prevent ghosting
      if (courseCode != null) {
          currentArr.removeWhere((id) => id.contains('_$courseCode') && id != courseId);
          nextArr.removeWhere((id) => id.contains('_$courseCode') && id != courseId);
      } else {
          currentArr.remove(courseId);
          nextArr.remove(courseId);
      }

      // If enrolling, push it to the explicitly targeted array
      // The browser is strictly locked to the Active Semester, so we ALWAYS write into currentArr.
      // Do NOT check isNextSemester because active_semester=Spring2026 and next_semester=Spring2026 will incorrectly trigger it.
      if (shouldEnroll) {
          if (!currentArr.contains(courseId)) currentArr.add(courseId);
      }

      // Clear DROPPED flag if user is enrolling — semester reactivation
      if (shouldEnroll && nextArr.length == 1 && nextArr.first == 'DROPPED') {
        nextArr.clear();
        debugPrint('[CourseRepo] Cleared DROPPED flag — semester reactivated');
      }

      debugPrint('[CourseRepo] Triggering DB Update. currentArr: ${currentArr.length}, nextArr: ${nextArr.length}');
      
      try {
        await _supabase
            .from('profiles')
            .update({
              'enrolled_sections': currentArr,
              'enrolled_sections_next': nextArr
            }).eq('id', user.id);
        debugPrint('[CourseRepo] DB Update successful');
      } catch (e) {
        debugPrint('[CourseRepo] DB Update FAILED: $e');
      }

      // Only trigger metrics sync for current semester
      if (semesterCode != null) {
        await _syncSemesterProgressAndSchedule(user.id, semesterCode, currentArr);
      }
    });

    // Execute queue sequentially if not already running
    if (!_isToggling) {
      _processToggleQueue();
    }
  }

  Future<void> _processToggleQueue() async {
    _isToggling = true;
    while (_toggleQueue.isNotEmpty) {
      final task = _toggleQueue.removeAt(0);
      try {
        await task();
      } catch (e) {
        debugPrint('[CourseRepo] Error in toggle queue: $e');
      }
    }
    _isToggling = false;
  }

  Future<void> _syncSemesterProgressAndSchedule(String userId, String semesterCode, List<String> enrolledIds) async {
    final safeSem = semesterCode.replaceAll(" ", "");
    final scheduleService = ScheduleService();

    // 1. Sync Weekly Schedule
    try {
      await scheduleService.syncUserSchedule(semesterCode, enrolledIds);
    } catch (e) {
      debugPrint('[CourseRepo] Warning: Failed to sync schedule: $e');
    }

    // 2. Sync Semester Progress
    try {
      final results = await _supabase
          .from('semester_progress')
          .select()
          .eq('user_id', userId)
          .eq('semester_code', safeSem)
          .maybeSingle();

      Map<String, dynamic> summary = results?['summary'] ?? {};
      Map<String, dynamic> coursesMap = summary['courses'] ?? {};

      // Get the full course details to rebuild the coursesMap
      final courses = await fetchCoursesByIds(semesterCode, enrolledIds);

      // Remove dropped courses
      final currentCodes = courses.map((c) => c.code).toSet();
      coursesMap.removeWhere((key, value) => !currentCodes.contains(key));

      // Add newly enrolled courses
      for (var course in courses) {
        if (!coursesMap.containsKey(course.code)) {
          // Find time string
          String timeStr = "TBA";
          if (course.sessions.isNotEmpty) {
            timeStr = course.sessions.map((s) => "${s.day} ${s.startTime}-${s.endTime}").join(", ");
          }
          coursesMap[course.code] = {
            'courseCode': course.code,
            'courseName': course.courseName,
            'section': course.section,
            'schedule': timeStr,
            'distribution': {},
            'obtained': {'quizzes': [], 'shortQuizzes': []},
            'quizStrategy': 'bestN',
          };
        }
      }

      summary['courses'] = coursesMap;

      await _supabase.from('semester_progress').upsert({
        'user_id': userId,
        'semester_code': safeSem,
        'summary': summary,
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, semester_code');
    } catch (e) {
      debugPrint('[CourseRepo] Error syncing progress: $e');
    }
  }

  Future<List<Course>> fetchCoursesByIds(
      String semester, List<String> docIds) async {
    if (docIds.isEmpty) return [];

    // 1. Try cache for each ID
    List<Course> cachedCourses = [];
    List<String> missingIds = [];
    
    for (var id in docIds) {
      final cached = OfflineCacheService().getCachedCourseDetails(id);
      if (cached != null) {
        cachedCourses.add(Course.fromSupabase(cached, id));
      } else {
        missingIds.add(id);
      }
    }

    if (missingIds.isEmpty) return cachedCourses;

    // 2. If offline, return what we have in cache
    if (!(await ConnectivityService().isOnline())) {
      debugPrint('[CourseRepo] Offline and missing some courses in cache. Returning partially cached list.');
      return cachedCourses;
    }

    try {
      // Always try the semester-specific table first
      final semesterTable = CourseUtils.semesterTable('courses', semester);

      var data = <Map<String, dynamic>>[];
      try {
        data = await _supabase
            .from(semesterTable)
            .select()
            .inFilter('doc_id', docIds);
      } catch (_) {
        // Table might not exist yet
      }

      // Fallback: try current semester table
      if (data.isEmpty) {
        final currentCode = await _academicRepo.getCurrentSemesterCode();
        final currentTable = CourseUtils.semesterTable('courses', currentCode);
        if (currentTable != semesterTable) {
          try {
            data = await _supabase
                .from(currentTable)
                .select()
                .inFilter('doc_id', docIds);
          } catch (_) {}
        }
      }

      // Last resort: course_metadata
      if (data.isEmpty) {
        // Try to extract codes from docIds if they look like semester_CODE_section
        final extractedCodes = docIds.map((id) {
          final parts = id.split('_');
          return parts.length > 1 ? parts[1] : id;
        }).toSet().toList();

        data = (await _supabase
            .from('course_metadata')
            .select()
            .inFilter('code', extractedCodes))
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      final results = data.map((d) {
        if (d.containsKey('name') && !d.containsKey('course_name')) {
          d['course_name'] = d['name'];
        }
        if (!d.containsKey('section')) d['section'] = 'N/A';
        if (!d.containsKey('sessions')) d['sessions'] = [];
        d['credits'] = d['credit_val'] ?? d['credits'] ?? 3.0;

        final id = d['doc_id'] ?? d['id'] ?? d['code'];
        // 2. Update cache
        OfflineCacheService().cacheCourseDetails(id.toString(), d);

        return Course.fromSupabase(d, id);
      }).toList();

      return [...cachedCourses, ...results];
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching courses by IDs: $e');
      return [];
    }
  }

  Future<Map<String, List<Course>>> fetchCourses(String semester, {bool allowMetadataFallback = true}) async {
    try {
      // Always try the semester-specific table first
      final semesterTable = CourseUtils.semesterTable('courses', semester);

      var data = <dynamic>[];
      try {
        data = await _supabase.from(semesterTable).select();
      } catch (_) {
        // Table might not exist yet
      }

      // Fallback to course_metadata if the semester table is empty and allowed
      if (data.isEmpty && allowMetadataFallback) {
        debugPrint('[CourseRepo] $semesterTable is empty. Falling back to course_metadata for $semester.');
        data = await _supabase.from('course_metadata').select();
      }
      
      if (data.isEmpty && !allowMetadataFallback) {
        return {}; // Return empty map if no sections found and no fallback allowed
      }

      final Map<String, List<Course>> groupedCourses = {};
      for (var dRaw in data) {
        final d = Map<String, dynamic>.from(dRaw as Map);
        if (d.containsKey('name') && !d.containsKey('course_name')) {
          d['course_name'] = d['name'];
        }
        if (!d.containsKey('section')) d['section'] = 'N/A';
        if (!d.containsKey('sessions')) d['sessions'] = [];
        d['credits'] = d['credit_val'] ?? d['credits'] ?? 3.0;

        final course = Course.fromSupabase(d, (d['doc_id'] ?? d['id'] ?? d['code']).toString());
        if (groupedCourses.containsKey(course.code)) {
          groupedCourses[course.code]!.add(course);
        } else {
          groupedCourses[course.code] = [course];
        }
      }
      return groupedCourses;
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching courses: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchAllCourseCodes() async {
    try {
      final data = await _supabase.from('course_metadata').select('code');

      return (data as List).map((item) => item['code'].toString()).toList();
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching all course codes: $e');
      rethrow;
    }
  }
}
