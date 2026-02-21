import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/semester_progress_models.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/connectivity_service.dart';

class SemesterProgressRepository {
  final _supabase = Supabase.instance.client;
  static final SemesterProgressRepository _instance = SemesterProgressRepository._internal();
  factory SemesterProgressRepository() => _instance;
  SemesterProgressRepository._internal();

  final _controller = StreamController<List<CourseMarks>>.broadcast();
  StreamSubscription? _subscription;
  String? _listeningSemester;

  String? get _uid => _supabase.auth.currentUser?.id;

  /// Streams all courses with marks for a given semester
  Stream<List<CourseMarks>> getSemesterProgressStream(String semesterCode) {
    final user = _supabase.auth.currentUser;
    
    // Initial fetch from cache
    _emitCachedProgress(semesterCode);

    if (user != null && (_subscription == null || _listeningSemester != semesterCode)) {
      _subscription?.cancel();
      _listeningSemester = semesterCode;
      
      _subscription = _supabase
          .from('semester_progress')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .listen((data) {
        final semesterData =
            data.where((d) => d['semester_code'] == semesterCode);
        if (semesterData.isEmpty) {
          if (!_controller.isClosed) _controller.add([]);
          return;
        }

        final summaryRaw = semesterData.first['summary'] as Map?;
        final Map<String, dynamic> summary = summaryRaw != null ? Map<String, dynamic>.from(summaryRaw) : {};
        final coursesRaw = summary['courses'] as Map?;
        final Map<String, dynamic> courses = coursesRaw != null ? Map<String, dynamic>.from(coursesRaw) : {};
        final remoteMarks = courses.entries.map((e) {
          final val = Map<String, dynamic>.from(e.value);
          val['courseCode'] = e.key;
          return CourseMarks.fromMap(val);
        }).toList();

        // Update cache with fresh data
        OfflineCacheService().cacheSemesterProgress(
            semesterCode, remoteMarks.map((m) => m.toMap()).toList());

        if (!_controller.isClosed) _controller.add(remoteMarks);
      }, onError: (e) {
        debugPrint("SemesterProgressStream Error: $e");
        _subscription?.cancel();
        _subscription = null;
      });
    }

    return _controller.stream;
  }

  void _emitCachedProgress(String semesterCode) {
    Future.microtask(() {
      if (!_controller.isClosed) {
        final cachedData =
            OfflineCacheService().getCachedSemesterProgress(semesterCode);
        final cachedMarks =
            cachedData.map((d) => CourseMarks.fromMap(d)).toList();
        _controller.add(cachedMarks);
      }
    });
  }

  /// Fetches all courses with marks for a given semester
  Future<List<CourseMarks>> fetchSemesterProgress(String semesterCode) async {
    if (_uid == null) return [];

    try {
      final data = await _supabase
          .from('semester_progress')
          .select('summary')
          .eq('user_id', _uid!)
          .eq('semester_code', semesterCode)
          .maybeSingle();

      if (data == null) return [];

      final summaryRaw = data['summary'] as Map?;
      final Map<String, dynamic> summary = summaryRaw != null ? Map<String, dynamic>.from(summaryRaw) : {};
      final coursesRaw = summary['courses'] as Map?;
      final Map<String, dynamic> courses = coursesRaw != null ? Map<String, dynamic>.from(coursesRaw) : {};

      return courses.entries.map((e) {
        final val = Map<String, dynamic>.from(e.value);
        val['courseCode'] = e.key;
        return CourseMarks.fromMap(val);
      }).toList();
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error fetching semester progress: $e');
      return [];
    }
  }

  /// Fetches cloud-generated semester summary (predictions, GPA)
  Future<Map<String, dynamic>?> fetchSemesterSummary(
    String semesterCode,
  ) async {
    // 1. Try cache first
    final cachedSummary =
        OfflineCacheService().getCachedSemesterSummaryMap(semesterCode);
    if (cachedSummary != null) return cachedSummary;

    if (_uid == null) return null;

    try {
      final data = await _supabase
          .from('semester_progress')
          .select('summary')
          .eq('user_id', _uid!)
          .eq('semester_code', semesterCode)
          .maybeSingle();

      final summaryRaw = data?['summary'] as Map?;
      final Map<String, dynamic>? summary = summaryRaw != null ? Map<String, dynamic>.from(summaryRaw) : null;
      if (summary != null) {
        // Update cache with fresh summary
        await OfflineCacheService()
            .cacheSemesterSummaryMap(semesterCode, summary);
      }
      return summary;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error fetching summary: $e');
      return null;
    }
  }

  /// Fetches marks for a single course
  Future<void> _updateSummary(
      String semesterCode, Map<String, dynamic> summary) async {
    if (_uid == null) return;

    // Local update
    final coursesRaw = summary['courses'] as Map?;
    final Map<String, dynamic> courses = coursesRaw != null ? Map<String, dynamic>.from(coursesRaw) : {};
    final marksList = courses.entries.map((e) {
      final val = Map<String, dynamic>.from(e.value);
      val['courseCode'] = e.key;
      return CourseMarks.fromMap(val);
    }).toList();
    
    await OfflineCacheService().cacheSemesterProgress(
      semesterCode, 
      marksList.map((m) => m.toMap()).toList()
    );
    // Also cache the full summary map
    await OfflineCacheService().cacheSemesterSummaryMap(semesterCode, summary);
    _emitCachedProgress(semesterCode); // Notify UI immediately

    // Sync if online
    if (await ConnectivityService().isOnline()) {
      try {
        await _supabase.from('semester_progress').upsert({
          'user_id': _uid!,
          'semester_code': semesterCode,
          'summary': summary,
          'last_updated': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, semester_code');
      } catch (e) {
        debugPrint("Error syncing semester progress to Supabase: $e");
      }
    } else {
      debugPrint("Offline: Progress saved locally, will sync when online.");
    }
  }

  Future<CourseMarks?> fetchCourseMarks(
    String semesterCode,
    String courseCode,
  ) async {
    // Try cache first
    final cachedProgress = OfflineCacheService().getCachedSemesterProgress(semesterCode);
    final cachedCourse = cachedProgress.firstWhere(
      (m) => m['courseCode'] == courseCode,
      orElse: () => {},
    );
    
    if (cachedCourse.isNotEmpty) {
      return CourseMarks.fromMap(cachedCourse);
    }

    if (_uid == null) return null;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final coursesRaw = summary['courses'] as Map?;
      final Map<String, dynamic> courses = coursesRaw != null ? Map<String, dynamic>.from(coursesRaw) : {};

      if (!courses.containsKey(courseCode)) return null;

      final data = Map<String, dynamic>.from(courses[courseCode]);
      data['courseCode'] = courseCode;
      return CourseMarks.fromMap(data);
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error fetching course marks: $e');
      return null;
    }
  }

  Future<void> initializeCourse(
    String semesterCode,
    String courseCode, {
    String? courseName,
  }) async {
    if (_uid == null) return;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});

      if (!courses.containsKey(courseCode)) {
        courses[courseCode] = {
          'courseCode': courseCode,
          'courseName': courseName ?? courseCode,
          'distribution': {},
          'obtained': {'quizzes': [], 'shortQuizzes': []},
          'quizStrategy': 'bestN',
        };
        summary['courses'] = courses;
        await _updateSummary(semesterCode, summary);
      }
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error initializing course: $e');
    }
  }

  /// Saves or updates mark distribution for a course
  Future<bool> saveMarkDistribution(
    String semesterCode,
    String courseCode,
    MarkDistribution distribution, {
    String? courseName,
  }) async {
    if (_uid == null) return false;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});

      courseData['distribution'] = distribution.toMap();
      if (courseName != null) courseData['courseName'] = courseName;

      courses[courseCode] = courseData;
      summary['courses'] = courses;
      await _updateSummary(semesterCode, summary);
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error saving distribution: $e');
      return false;
    }
  }

  Future<bool> saveObtainedMark(
    String semesterCode,
    String courseCode,
    String category,
    double value,
  ) async {
    if (_uid == null) return false;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});
      final obtained = Map<String, dynamic>.from(courseData['obtained'] ?? {});

      obtained[category] = value;
      courseData['obtained'] = obtained;
      courses[courseCode] = courseData;
      summary['courses'] = courses;
      await _updateSummary(semesterCode, summary);
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error saving obtained mark: $e');
      return false;
    }
  }

  /// Adds a new quiz mark to the list
  Future<bool> addQuizMark(
    String semesterCode,
    String courseCode,
    double mark,
  ) async {
    if (_uid == null) return false;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});
      final obtained = Map<String, dynamic>.from(courseData['obtained'] ?? {});
      final quizzes = List<double>.from(obtained['quizzes'] ?? []);

      quizzes.add(mark);
      obtained['quizzes'] = quizzes;
      courseData['obtained'] = obtained;
      courses[courseCode] = courseData;
      summary['courses'] = courses;
      await _updateSummary(semesterCode, summary);
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error adding quiz mark: $e');
      return false;
    }
  }

  Future<bool> addShortQuizMark(
    String semesterCode,
    String courseCode,
    double mark,
  ) async {
    if (_uid == null) return false;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});
      final obtained = Map<String, dynamic>.from(courseData['obtained'] ?? {});
      final shortQuizzes = List<double>.from(obtained['shortQuizzes'] ?? []);

      shortQuizzes.add(mark);
      obtained['shortQuizzes'] = shortQuizzes;
      courseData['obtained'] = obtained;
      courses[courseCode] = courseData;
      summary['courses'] = courses;
      await _updateSummary(semesterCode, summary);
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error adding short quiz mark: $e');
      return false;
    }
  }

  Future<bool> saveStrategies(
    String semesterCode,
    String courseCode, {
    required String strategy,
    required int quizN,
    required int shortQuizN,
  }) async {
    if (_uid == null) return false;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});

      courseData['quizStrategy'] = strategy;
      courseData['quizN'] = quizN;
      courseData['shortQuizN'] = shortQuizN;

      courses[courseCode] = courseData;
      summary['courses'] = courses;
      await _updateSummary(semesterCode, summary);
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error saving strategies: $e');
      return false;
    }
  }

  Future<bool> updateQuizMark(
    String semesterCode,
    String courseCode,
    int index,
    double mark,
  ) async {
    if (_uid == null) return false;
    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});
      final obtained = Map<String, dynamic>.from(courseData['obtained'] ?? {});
      final quizzes = List<double>.from(obtained['quizzes'] ?? []);

      if (index >= 0 && index < quizzes.length) {
        quizzes[index] = mark;
        obtained['quizzes'] = quizzes;
        courseData['obtained'] = obtained;
        courses[courseCode] = courseData;
        summary['courses'] = courses;
        await _updateSummary(semesterCode, summary);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error updating quiz mark: $e');
      return false;
    }
  }

  Future<bool> updateShortQuizMark(
    String semesterCode,
    String courseCode,
    int index,
    double mark,
  ) async {
    if (_uid == null) return false;
    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});
      final obtained = Map<String, dynamic>.from(courseData['obtained'] ?? {});
      final shortQuizzes = List<double>.from(obtained['shortQuizzes'] ?? []);

      if (index >= 0 && index < shortQuizzes.length) {
        shortQuizzes[index] = mark;
        obtained['shortQuizzes'] = shortQuizzes;
        courseData['obtained'] = obtained;
        courses[courseCode] = courseData;
        summary['courses'] = courses;
        await _updateSummary(semesterCode, summary);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error updating short quiz mark: $e');
      return false;
    }
  }

  /// Deletes a quiz mark by index
  Future<bool> deleteQuizMark(
    String semesterCode,
    String courseCode,
    int index,
  ) async {
    if (_uid == null) return false;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});
      final obtained = Map<String, dynamic>.from(courseData['obtained'] ?? {});
      final quizzes = List<dynamic>.from(obtained['quizzes'] ?? []);

      if (index >= 0 && index < quizzes.length) {
        quizzes.removeAt(index);
        obtained['quizzes'] = quizzes;
        courseData['obtained'] = obtained;
        courses[courseCode] = courseData;
        summary['courses'] = courses;
        await _updateSummary(semesterCode, summary);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error deleting quiz mark: $e');
      return false;
    }
  }

  Future<bool> deleteShortQuizMark(
    String semesterCode,
    String courseCode,
    int index,
  ) async {
    if (_uid == null) return false;

    try {
      final summary = await fetchSemesterSummary(semesterCode) ?? {};
      final courses = Map<String, dynamic>.from(summary['courses'] ?? {});
      final courseData = Map<String, dynamic>.from(courses[courseCode] ?? {});
      final obtained = Map<String, dynamic>.from(courseData['obtained'] ?? {});
      final shortQuizzes = List<dynamic>.from(obtained['shortQuizzes'] ?? []);

      if (index >= 0 && index < shortQuizzes.length) {
        shortQuizzes.removeAt(index);
        obtained['shortQuizzes'] = shortQuizzes;
        courseData['obtained'] = obtained;
        courses[courseCode] = courseData;
        summary['courses'] = courses;
        await _updateSummary(semesterCode, summary);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error deleting short quiz mark: $e');
      return false;
    }
  }
}
