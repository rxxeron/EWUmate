import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/repositories/course_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/academic_providers.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/models/course_metadata.dart';
import '../../../../core/utils/course_utils.dart';

final courseSearchQueryProvider = StateProvider<String>((ref) => '');

final courseBrowserTabProvider = StateProvider<String>((ref) => 'available');

class CourseBrowserFilter {
  final String? faculty;
  final String? credits;
  final List<String> days;

  CourseBrowserFilter({
    this.faculty,
    this.credits,
    this.days = const [],
  });

  CourseBrowserFilter copyWith({
    String? faculty,
    String? credits,
    List<String>? days,
    bool clearFaculty = false,
    bool clearCredits = false,
  }) {
    return CourseBrowserFilter(
      faculty: clearFaculty ? null : (faculty ?? this.faculty),
      credits: clearCredits ? null : (credits ?? this.credits),
      days: days ?? this.days,
    );
  }

  bool get isEmpty => faculty == null && credits == null && days.isEmpty;
}

final courseBrowserFilterProvider = StateProvider<CourseBrowserFilter>((ref) => CourseBrowserFilter());

class PaginatedCoursesNotifier extends AsyncNotifier<List<CourseMetadata>> {
  int _offset = 0;
  final int _limit = 50;
  bool _hasMore = true;

  @override
  Future<List<CourseMetadata>> build() async {
    _offset = 0;
    _hasMore = true;
    return ref.watch(courseRepositoryProvider).getAllCourses(offset: _offset, limit: _limit);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading || state.isRefreshing) return;

    state = const AsyncLoading<List<CourseMetadata>>().copyWithPrevious(state);
    
    try {
      _offset += _limit;
      final activeSem = await ref.read(currentSemesterCodeProvider.future);
      if (activeSem == null) return;
      
      final newPage = await ref.read(courseRepositoryProvider).getSemesterCourses(activeSem);
      
      if (newPage.length < _limit) {
        _hasMore = false;
      }

      state = AsyncData([...state.value ?? [], ...newPage]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  bool get hasMore => _hasMore;
}

final paginatedCoursesProvider = AsyncNotifierProvider<PaginatedCoursesNotifier, List<CourseMetadata>>(
  PaginatedCoursesNotifier.new,
);

final courseSearchResultProvider = FutureProvider<List<CourseMetadata>>((ref) async {
  final query = ref.watch(courseSearchQueryProvider);
  final repo = ref.watch(courseRepositoryProvider);
  
  if (query.isEmpty) return [];
  return repo.searchCourses(query);
});

final currentSemCodeProvider = FutureProvider<String>((ref) async {
  final state = await ref.watch(academicStateProvider.future);
  return state?.currentSemesterCode ?? '';
});

final nextSemCodeProvider = FutureProvider<String>((ref) async {
  final state = await ref.watch(academicStateProvider.future);
  return state?.nextSemesterCode ?? '';
});

final userEnrollmentsProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final activeSem = await ref.watch(currentSemCodeProvider.future);
  if (activeSem.isEmpty) return [];

  final supabase = ref.watch(supabaseClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  final safeSem = CourseUtils.cleanSemester(activeSem);
  final spaceSem = activeSem.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
  
  try {
    // 1. Fetch from Enrollments
    final enrollData = await supabase
        .from('enrollments')
        .select('course_code')
        .eq('user_id', user.id)
        .inFilter('semester_code', [activeSem, safeSem, spaceSem, activeSem.toLowerCase(), activeSem.replaceAll(' ', '')]);
        
    final enrolled = (enrollData as List).map((e) => e['course_code'] as String).toList();

    // 2. Fetch from Marks (to include manual entries)
    final marksData = await supabase
        .from('semester_course_marks')
        .select('course_code')
        .eq('user_id', user.id)
        .inFilter('semester_code', [activeSem, safeSem, spaceSem, activeSem.toLowerCase(), activeSem.replaceAll(' ', '')]);
    
    final marked = (marksData as List).map((e) => e['course_code'] as String).toList();

    // Merge and deduplicate
    final res = {...enrolled, ...marked}.toList();
    
    // Cache it
    cache.setMapData('dashboard_box', 'enrollment_codes_${user.id}_$activeSem', {'codes': res});
    return res;
  } catch (e) {
    if (kDebugMode) debugPrint('[CourseBrowser] Enrollment fetch failed, using cache: $e');
    final cached = cache.getMapData('dashboard_box', 'enrollment_codes_${user.id}_$activeSem');
    if (cached != null && cached['codes'] != null) {
      final List<String> codes = List<String>.from(cached['codes']);
      if (codes.isNotEmpty) return codes;
    }

    try {
      final sched = cache.getCachedDashboardSchedule(user.id, safeSem) 
          ?? cache.getCachedDashboardSchedule(user.id, activeSem)
          ?? cache.getCachedDashboardSchedule(user.id, activeSem.toLowerCase())
          ?? cache.getCachedDashboardSchedule(user.id, activeSem.replaceAll(' ', ''));
      if (sched != null) {
        final List<dynamic> template = sched['template'] as List? ?? [];
        final List<dynamic> exceptions = sched['exceptions'] as List? ?? [];
        
        final Set<String> codes = {};
        for (var cls in template) {
          if (cls is Map) {
            final String? code = (cls['courseCode'] ?? cls['course_code'])?.toString();
            if (code != null && code.trim().isNotEmpty) {
              codes.add(code.trim().toUpperCase());
            }
          }
        }
        for (var ex in exceptions) {
          if (ex is Map) {
            final String? code = (ex['course_code'] ?? ex['courseCode'])?.toString();
            if (code != null && code.trim().isNotEmpty) {
              codes.add(code.trim().toUpperCase());
            }
          }
        }
        if (codes.isNotEmpty) {
          final List<String> uniqueCodes = codes.toList()..sort();
          if (kDebugMode) debugPrint('[CourseBrowser] Offline Fallback: Extracted course codes from cached schedule: $uniqueCodes');
          return uniqueCodes;
        }
      }
    } catch (innerEx) {
      if (kDebugMode) debugPrint('[CourseBrowser] Secondary fallback extraction error: $innerEx');
    }
    return [];
  }
});

final browserAvailableCoursesProvider = FutureProvider<List<CourseMetadata>>((ref) async {
  final activeSem = await ref.watch(currentSemCodeProvider.future);
  if (activeSem.isEmpty) return [];
  
  final completedCourseCodesStr = ref.watch(userProfileProvider.select((profileAsync) {
    return profileAsync.maybeWhen(
      data: (profile) {
        if (profile == null) return '';
        final history = profile.pastHistory;
        final codes = history.where((item) {
          if (item is! Map) return false;
          final grade = (item['grade'] as String?)?.toUpperCase() ?? '';
          // Only exclude if they have a real passing grade
          // If it's W, F, R, or empty, they might need to retake it
          return grade.isNotEmpty && 
                 grade != 'W' && 
                 grade != 'F' && 
                 grade != 'R' && 
                 grade != 'I' &&
                 grade != 'X';
        }).map((item) => (item['course_code'] as String?)?.toUpperCase() ?? '').toList();
        codes.sort();
        return codes.join(',');
      },
      orElse: () => '',
    );
  }));
  final completedCourseCodes = completedCourseCodesStr.split(',').where((e) => e.isNotEmpty).toSet();

  final cache = ref.watch(cacheServiceProvider);
  
  try {
    final allCourses = await ref.watch(semesterCoursesProvider(activeSem).future);
    
    // Filter out successfully completed courses
    final res = allCourses.where((course) {
      return !completedCourseCodes.contains(course.code.toUpperCase());
    }).toList();

    // Cache it
    cache.setMapData('dashboard_box', 'available_courses_$activeSem', 
      {'data': res.map((e) => e.toJson()).toList()});
    return res;
  } catch (e) {
    if (kDebugMode) debugPrint('[CourseBrowser] Available courses fallback: $e');
    final cached = cache.getMapData('dashboard_box', 'available_courses_$activeSem');
    if (cached != null && cached['data'] != null) {
      return (cached['data'] as List).map((e) => CourseMetadata.fromJson(e)).toList();
    }
    return [];
  }
});

final filteredAvailableCoursesProvider = Provider<AsyncValue<List<CourseMetadata>>>((ref) {
  final availableAsync = ref.watch(browserAvailableCoursesProvider);
  final filter = ref.watch(courseBrowserFilterProvider);

  if (filter.isEmpty) return availableAsync;

  return availableAsync.whenData((courses) {
    return courses.where((course) {
      // 1. Filter by Credits
      if (filter.credits != null && filter.credits!.isNotEmpty) {
        if (course.creditVal.toString() != filter.credits && 
            !course.creditVal.toString().startsWith(filter.credits!)) {
          return false;
        }
      }
      
      // Note: Faculty and Day filtering often requires reaching into Sections,
      // but for the high-level Metadata list, we primarily filter by what's available in the table.
      // If we need deep section filtering, we'd need to fetch sections for all courses first (expensive).
      // For now, we'll implement Metadata-level filtering.
      
      return true;
    }).toList();
  });
});

final userEnrollmentDetailsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final activeSem = await ref.watch(currentSemCodeProvider.future);
  if (activeSem.isEmpty) return [];

  final supabase = ref.watch(supabaseClientProvider);
  
  final data = await supabase
      .from('enrollments')
      .select()
      .eq('user_id', user.id)
      .eq('semester_code', activeSem);
      
  return (data as List).cast<Map<String, dynamic>>();
});
