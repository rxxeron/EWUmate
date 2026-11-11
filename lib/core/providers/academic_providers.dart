import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/repositories/active_semester_repository.dart';
import 'package:ewumate/core/services/cache_service.dart';
import 'package:ewumate/core/models/academic_state.dart';
import 'package:ewumate/core/providers/supabase_provider.dart';
import 'package:ewumate/core/utils/course_utils.dart';

final programDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, programCode) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.getProgramDetails(programCode);
});

final academicStateProvider = StreamProvider<AcademicState?>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield null;
    return;
  }

  final cacheService = ref.read(cacheServiceProvider);
  final cachedSem = cacheService.getMapData('dashboard_box', '${user.id}_academicState');

  // 1. Yield Cache Immediately if available (Frame 1)
  if (cachedSem != null) {
    yield AcademicState.fromJson(cachedSem);

    // If cache is fresh (< 1 day old), do not hit database
    final cacheUpdatedAtStr = cachedSem['_cache_updated_at'] as String?;
    if (cacheUpdatedAtStr != null) {
      final cachedTime = DateTime.tryParse(cacheUpdatedAtStr);
      if (cachedTime != null && DateTime.now().difference(cachedTime) < const Duration(days: 1)) {
        return;
      }
    }
  }

  try {
    // 2. Fetch fresh active semester concurrently
    final cachedProfile = cacheService.getCachedProfile(user.id);
    final knownTrack = CourseUtils.normalizeTrack(cachedProfile?['track'] ?? cachedSem?['track']);

    final profileFuture = ref.read(profileRepositoryProvider).getProfile(user.id).timeout(const Duration(seconds: 6));
    final semesterFuture = ref.read(activeSemesterRepositoryProvider).getActiveSemester(knownTrack).timeout(const Duration(seconds: 6));

    final results = await Future.wait<dynamic>([profileFuture, semesterFuture]);
    final profile = results[0];
    final semesterData = results[1] as Map<String, dynamic>;
    final track = CourseUtils.normalizeTrack(profile?.track ?? knownTrack);

    final stateDict = {
      ...semesterData,
      'track': track,
      '_cache_updated_at': DateTime.now().toIso8601String(),
    };
    cacheService.setMapData('dashboard_box', '${user.id}_academicState', stateDict);
    yield AcademicState.fromJson(stateDict);
  } catch (e) {
    // 3. Fallback check: if we have no cache yielded, report error
    if (cachedSem == null) {
      throw Exception("Could not load active semester from database: $e");
    }
  }
});

final currentSemesterCodeProvider = FutureProvider<String?>((ref) async {
  final asyncState = ref.watch(academicStateProvider);
  return asyncState.value?.currentSemesterCode;
});

final nextSemesterCodeProvider = FutureProvider<String?>((ref) async {
  final asyncState = ref.watch(academicStateProvider);
  return asyncState.value?.nextSemesterCode;
});

final semestersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(activeSemesterRepositoryProvider);
  final data = await repo.getAllSemesters();
  
  // Use a Set to ensure unique titles
  final titles = data.map((e) => e['title'].toString()).toSet().toList();
  
  return titles.map((t) => (title: t)).toList();
});

final facultySnapshotsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final res = await supabase.from('app_config').select('value').eq('key', 'faculty_snapshots').single();
  
  if (res['value'] != null && res['value']['snapshots'] != null) {
    return List<Map<String, dynamic>>.from(res['value']['snapshots']);
  }
  return [];
});
