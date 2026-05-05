import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/repositories/course_repository.dart';
import '../../../core/repositories/schedule_repository.dart';
import '../../../core/repositories/progress_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/models/course_metadata.dart';
import '../../../core/models/active_semester.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/providers/academic_providers.dart';

final activeSemesterProvider = FutureProvider<ActiveSemester?>((ref) async {
  final academicState = await ref.watch(academicStateProvider.future);
  if (academicState == null) return null;
  
  // Convert AcademicState to ActiveSemester for compatibility with existing UI
  return ActiveSemester(
    track: academicState.track,
    currentSemesterCode: academicState.currentSemesterCode,
    nextSemesterCode: academicState.nextSemesterCode,
    advisingStartDate: academicState.advisingStartDate,
    advisingEndDate: academicState.advisingEndDate,
    classesStartDate: academicState.classesStartDate,
    upcomingClassesStartDate: academicState.upcomingClassesStartDate,
    semesterSwitchDate: academicState.semesterSwitchDate,
  );
});

final excludedCourseCodesProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  final activeSem = await ref.watch(activeSemesterProvider.future);
  final currentSemCode = activeSem?.currentSemesterCode;
  
  if (currentSemCode == null) return {};

  // 1. Get past completed courses from semester summaries
  final summaries = await ref.watch(allSemesterSummariesProvider.future);
  final Set<String> codes = {};
  
  for (final summary in summaries) {
    for (final course in summary.courses) {
      String? code;
      if (course is Map) {
        code = (course['code'] ?? course['course_code'])?.toString();
      } else if (course is String) {
        code = course;
      }
      
      if (code != null) {
        // Normalize: remove spaces and uppercase
        codes.add(code.replaceAll(' ', '').toUpperCase());
      }
    }
  }

  // 2. Get current enrolled courses
  final enrollments = await ref.watch(scheduleRepositoryProvider)
      .getEnrollments(user.id, currentSemCode);
      
  for (final enr in enrollments) {
    codes.add(enr.courseCode.replaceAll(' ', '').toUpperCase());
  }

  return codes;
});

final availableAdvisingCoursesProvider = FutureProvider<List<CourseMetadata>>((ref) async {
  final activeSem = await ref.watch(activeSemesterProvider.future);
  final nextSemCode = activeSem?.nextSemesterCode;
  
  if (nextSemCode == null) return [];
  
  final semCourses = await ref.watch(semesterCoursesProvider(nextSemCode).future);
  final excluded = await ref.watch(excludedCourseCodesProvider.future);

  if (excluded.isEmpty) return semCourses;

  return semCourses.where((c) {
    final normalized = c.code.replaceAll(' ', '').toUpperCase();
    return !excluded.contains(normalized);
  }).toList();
});

final savedSchedulesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return ref.watch(scheduleRepositoryProvider).getSavedSchedules(user.id);
});

final pastGenerationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final res = await supabase
        .from('schedule_generations')
        .select('id, created_at, status, count, courses')
        .eq('user_id', user.id)
        .gte('created_at', sevenDaysAgo.toIso8601String())
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  } catch (e) {
    return [];
  }
});

final courseFacultiesProvider = FutureProvider.autoDispose.family<List<String>, String>((ref, String courseCode) async {
  final activeSem = await ref.watch(activeSemesterProvider.future);
  final semCode = activeSem?.nextSemesterCode;
  if (semCode == null) return [];
  
  final safeSem = semCode.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
  final tableName = 'courses_$safeSem';
  
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final cleanCode = courseCode.replaceAll(' ', '').toUpperCase();
    final res = await supabase.from(tableName).select('faculty_initials').eq('course_code', cleanCode);
    final Set<String> initials = {};
    for (final r in res as List) {
       final f = r['faculty_initials']?.toString().toUpperCase().trim();
       if (f != null && f.isNotEmpty && f != 'TBA') {
          initials.add(f);
       }
    }
    final list = initials.toList()..sort();
    return list;
  } catch(e) {
     return [];
  }
});

final generationTrackerProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, genId) async* {
  final supabase = ref.watch(supabaseClientProvider);
  
  // Try to use Supabase Realtime Stream
  try {
    final stream = supabase
        .from('schedule_generations')
        .stream(primaryKey: ['id'])
        .eq('id', genId)
        .map((event) => event.isEmpty ? null : event.first);
        
    yield* stream;
  } catch (e) {
    // Fallback to manual polling every 2 seconds if Stream fails (e.g. Realtime not enabled)
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      final res = await supabase
          .from('schedule_generations')
          .select()
          .eq('id', genId)
          .maybeSingle();
      
      yield res;
      
      // Stop polling if complete or failed
      if (res != null && (res['status'] == 'completed' || res['status'] == 'failed')) {
        break;
      }
    }
  }
});
