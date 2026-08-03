import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/supabase_provider.dart';
import '../../features/auth/auth_providers.dart';

part 'feature_flag_provider.g.dart';

@riverpod
Future<bool> isAdvisingOpen(IsAdvisingOpenRef ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return false;

  final supabase = ref.watch(supabaseClientProvider);
  try {
    // Map 'tri' -> 'tri_semester' to match DB Enum
    String track = profile.track ?? profile.semesterType;
    if (track == 'tri') track = 'tri_semester';
    if (track == 'bi') track = 'bi_semester';

    final res = await supabase
        .from('active_semester')
        .select('is_advising_open')
        .eq('track', track)
        .maybeSingle();
    
    if (res != null) {
      return res['is_advising_open'] ?? false;
    }
  } catch (_) {}
  return false;
}

@riverpod
Future<bool> isNextSemesterOpen(IsNextSemesterOpenRef ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return false;

  final supabase = ref.watch(supabaseClientProvider);
  try {
    // Map 'tri' -> 'tri_semester' to match DB Enum
    String track = profile.track ?? profile.semesterType;
    if (track == 'tri') track = 'tri_semester';
    if (track == 'bi') track = 'bi_semester';

    final res = await supabase
        .from('active_semester')
        .select('is_next_semester_open')
        .eq('track', track)
        .maybeSingle();
    
    if (res != null) {
      return res['is_next_semester_open'] ?? false;
    }
  } catch (_) {}
  return false;
}
