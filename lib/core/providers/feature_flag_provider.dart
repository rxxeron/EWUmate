import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/supabase_provider.dart';

part 'feature_flag_provider.g.dart';

@riverpod
Future<bool> isAdvisingOpen(IsAdvisingOpenRef ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final res = await supabase
        .from('app_config')
        .select('value')
        .eq('key', 'advising_status')
        .maybeSingle();
    
    if (res != null && res['value'] != null) {
      return res['value']['is_open'] ?? false;
    }
  } catch (_) {}
  return false;
}

@riverpod
Future<bool> isNextSemesterOpen(IsNextSemesterOpenRef ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final res = await supabase
        .from('app_config')
        .select('value')
        .eq('key', 'next_semester_status')
        .maybeSingle();
    
    if (res != null && res['value'] != null) {
      return res['value']['is_open'] ?? false;
    }
  } catch (_) {}
  return false;
}
