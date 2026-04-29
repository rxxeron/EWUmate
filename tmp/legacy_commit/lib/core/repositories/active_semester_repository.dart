import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

part 'active_semester_repository.g.dart';

class ActiveSemesterRepository {
  final SupabaseClient _supabase;

  ActiveSemesterRepository(this._supabase);

  Future<Map<String, dynamic>> getActiveSemester(String track) async {
    final response = await _supabase
        .from('active_semester')
        .select()
        .eq('track', track)
        .limit(1)
        .single();
    return response;
  }
}

@riverpod
ActiveSemesterRepository activeSemesterRepository(ActiveSemesterRepositoryRef ref) {
  return ActiveSemesterRepository(ref.watch(supabaseClientProvider));
}
