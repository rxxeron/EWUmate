import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/course_repository.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/academic_providers.dart';
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
  
  final data = await supabase
      .from('enrollments')
      .select('course_code')
      .eq('user_id', user.id)
      .eq('semester_code', activeSem);
      
  return (data as List).map((e) => e['course_code'] as String).toList();
});

final browserAvailableCoursesProvider = FutureProvider<List<CourseMetadata>>((ref) async {
  final activeSem = await ref.watch(currentSemCodeProvider.future);
  if (activeSem.isEmpty) return [];
  
  return ref.watch(semesterCoursesProvider(activeSem).future);
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
