import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

part 'active_semester_repository.g.dart';

class ActiveSemesterRepository {
  final SupabaseClient _supabase;

  ActiveSemesterRepository(this._supabase);

  Future<Map<String, dynamic>> getActiveSemester(String track) async {
    // NORMALIZE: Ensure track matches DB Enum ('tri' -> 'tri_semester')
    String normalizedTrack = track;
    if (normalizedTrack == 'tri') normalizedTrack = 'tri_semester';
    if (normalizedTrack == 'bi') normalizedTrack = 'bi_semester';

    final response = await _supabase
        .from('active_semester')
        .select()
        .eq('track', normalizedTrack)
        .limit(1)
        .single();
    return response;
  }
}

@riverpod
ActiveSemesterRepository activeSemesterRepository(ActiveSemesterRepositoryRef ref) {
  return ActiveSemesterRepository(ref.watch(supabaseClientProvider));
}
