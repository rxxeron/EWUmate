import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/repositories/course_repository.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/academic_providers.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/models/course_metadata.dart';

final courseSearchQueryProvider = StateProvider<String>((ref) => '');

final courseBrowserTabProvider = StateProvider<String>((ref) => 'available');

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
  
  try {
    final data = await supabase
        .from('enrollments')
        .select('course_code')
        .eq('user_id', user.id)
        .eq('semester_code', activeSem);
        
    final res = (data as List).map((e) => e['course_code'] as String).toList();
    // Cache it
    cache.setMapData('dashboard_box', 'enrollment_codes_${user.id}_$activeSem', {'codes': res});
    return res;
  } catch (e) {
    if (kDebugMode) debugPrint('[CourseBrowser] Enrollment fetch failed, using cache: $e');
    final cached = cache.getMapData('dashboard_box', 'enrollment_codes_${user.id}_$activeSem');
    if (cached != null && cached['codes'] != null) {
      return List<String>.from(cached['codes']);
    }
    return [];
  }
});

final browserAvailableCoursesProvider = FutureProvider<List<CourseMetadata>>((ref) async {
  final activeSem = await ref.watch(currentSemCodeProvider.future);
  if (activeSem.isEmpty) return [];
  
  final cache = ref.watch(cacheServiceProvider);
  
  try {
    final res = await ref.watch(semesterCoursesProvider(activeSem).future);
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
