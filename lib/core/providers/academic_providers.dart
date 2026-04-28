import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ewumate_v2/core/repositories/progress_repository.dart';
import 'package:ewumate_v2/core/repositories/auth_repository.dart';
import 'package:ewumate_v2/core/repositories/profile_repository.dart';
import 'package:ewumate_v2/core/repositories/active_semester_repository.dart';
import 'package:ewumate_v2/core/models/academic_state.dart';

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
  final semesterData = await ref.watch(activeSemesterRepositoryProvider).getActiveSemester(track);

  return AcademicState.fromJson({
    ...semesterData,
    'track': track,
  });
});

final currentSemesterCodeProvider = FutureProvider<String?>((ref) async {
  final state = await ref.watch(academicStateProvider.future);
  return state?.currentSemesterCode;
});

final nextSemesterCodeProvider = FutureProvider<String?>((ref) async {
  final state = await ref.watch(academicStateProvider.future);
  return state?.nextSemesterCode;
});
