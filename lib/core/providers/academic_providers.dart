import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/repositories/active_semester_repository.dart';
import 'package:ewumate/core/services/cache_service.dart';
import 'package:ewumate/core/models/academic_state.dart';

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
  
  try {
    final semesterData = await ref.watch(activeSemesterRepositoryProvider).getActiveSemester(track);
    final stateDict = {
      ...semesterData,
      'track': track,
    };
    ref.read(cacheServiceProvider).setMapData('dashboard_box', '${user.id}_academicState', stateDict);
    return AcademicState.fromJson(stateDict);
  } catch (e) {
    final cachedSem = ref.read(cacheServiceProvider).getMapData('dashboard_box', '${user.id}_academicState');
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
