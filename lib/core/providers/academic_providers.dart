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

final academicStateProvider = FutureProvider<AcademicState?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final profile = await ref.watch(profileRepositoryProvider).getProfile(user.id);
  if (profile == null) return null;

  final track = profile.track ?? 'tri_semester';
  
  final cachedSem = ref.read(cacheServiceProvider).getMapData('dashboard_box', '${user.id}_academicState');
  if (cachedSem != null) {
    final updatedAtStr = cachedSem['_cache_updated_at'] as String?;
    if (updatedAtStr != null) {
      final updatedAt = DateTime.tryParse(updatedAtStr);
      if (updatedAt != null && DateTime.now().difference(updatedAt).inHours < 24) {
        return AcademicState.fromJson(cachedSem);
      }
    }
  }

  try {
    final semesterData = await ref.watch(activeSemesterRepositoryProvider).getActiveSemester(track);
    final stateDict = {
      ...semesterData,
      'track': track,
      '_cache_updated_at': DateTime.now().toIso8601String(),
    };
    ref.read(cacheServiceProvider).setMapData('dashboard_box', '${user.id}_academicState', stateDict);
    return AcademicState.fromJson(stateDict);
  } catch (e) {
    if (cachedSem != null) {
      return AcademicState.fromJson(cachedSem);
    }
    throw Exception("Could not load active semester offline.");
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
