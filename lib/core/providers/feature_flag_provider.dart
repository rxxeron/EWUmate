import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final adSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final res = await supabase
        .from('app_config')
        .select('value')
        .eq('key', 'ad_settings')
        .maybeSingle();
    
    if (res != null && res['value'] != null) {
      final val = res['value'];
      if (val is Map) {
        return Map<String, dynamic>.from(val);
      }
    }
  } catch (_) {}
  return {};
});

final isAdsEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(adSettingsProvider);
  return settingsAsync.maybeWhen(
    data: (settings) => settings['is_enabled'] ?? true,
    orElse: () => true,
  );
});

final isAdEnabledForProvider = Provider.family<bool, String>((ref, key) {
  final settingsAsync = ref.watch(adSettingsProvider);
  return settingsAsync.maybeWhen(
    data: (settings) {
      // 1. Global master check
      final globalEnabled = settings['is_enabled'] ?? true;
      if (!globalEnabled) return false;

      // 2. Type format checks
      if (key == 'banner' && !(settings['banner_enabled'] ?? true)) return false;
      if (key == 'native' && !(settings['native_enabled'] ?? true)) return false;
      if (key == 'interstitial' && !(settings['interstitial_enabled'] ?? true)) return false;

      // 3. Screen placement checks
      final screens = settings['screens'];
      if (screens is Map) {
        if (screens.containsKey(key)) {
          return screens[key] ?? true;
        }
      }

      return true; // ON by default if key doesn't exist
    },
    orElse: () => true, // ON by default while loading/error
  );
});
