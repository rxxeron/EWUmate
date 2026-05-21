import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/repositories/active_semester_repository.dart';
import 'package:ewumate/core/services/cache_service.dart';
import 'package:ewumate/core/models/academic_state.dart';
import 'package:ewumate/core/providers/supabase_provider.dart';

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
  final cachedProfile = cacheService.getCachedProfile(user.id);

  // 1. Yield Cache Immediately (Frame 1)
  if (cachedSem != null) {
    yield AcademicState.fromJson(cachedSem);
  } else if (cachedProfile != null) {
    final track = cachedProfile['track'] ?? 'tri_semester';
    yield AcademicState(
      currentSemesterCode: 'Summer2026',
      nextSemesterCode: 'Fall2026',
      track: track,
      advisingEndDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  try {
    // 2. Try online fetch first with timeout
    final profile = await ref.watch(profileRepositoryProvider).getProfile(user.id).timeout(const Duration(seconds: 8));
    if (profile != null) {
      final track = profile.track ?? 'tri_semester';
      final semesterData = await ref.watch(activeSemesterRepositoryProvider).getActiveSemester(track).timeout(const Duration(seconds: 8));
      final stateDict = {
        ...semesterData,
        'track': track,
        '_cache_updated_at': DateTime.now().toIso8601String(),
      };
      cacheService.setMapData('dashboard_box', '${user.id}_academicState', stateDict);
      yield AcademicState.fromJson(stateDict);
    }
  } catch (e) {
    // 3. Fallback check: if we have no cache yielded, throw error
    if (cachedSem == null && cachedProfile == null) {
      throw Exception("Could not load active semester offline.");
    }
  }
});

final currentSemesterCodeProvider = FutureProvider<String?>((ref) async {
  final state = await ref.watch(academicStateProvider.future);
  return state?.currentSemesterCode;
});

final nextSemesterCodeProvider = FutureProvider<String?>((ref) async {
  final state = await ref.watch(academicStateProvider.future);
  return state?.nextSemesterCode;
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
