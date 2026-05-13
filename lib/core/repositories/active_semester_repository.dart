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

  Future<List<Map<String, dynamic>>> getAllSemesters() async {
    final response = await _supabase
        .from('semesters')
        .select('title')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

@riverpod
ActiveSemesterRepository activeSemesterRepository(ActiveSemesterRepositoryRef ref) {
  return ActiveSemesterRepository(ref.watch(supabaseClientProvider));
}
