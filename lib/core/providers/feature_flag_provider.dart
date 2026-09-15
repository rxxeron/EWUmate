import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/supabase_provider.dart';
import '../../features/auth/auth_providers.dart';

part 'feature_flag_provider.g.dart';

/// Controls whether ads/banners are enabled for a given screen.
/// Currently disabled throughout the app.
final isAdEnabledForProvider = Provider.family<bool, String>((ref, screenName) {
  return false;
});

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

/// Fetches the admin-controlled promo banner config from app_config.
/// Expected JSON shape:
/// {
///   "is_active": true,
///   "image_url": "https://...",
///   "link_url": "https://...",
///   "title": "Optional label"
/// }
final promoBannerProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final res = await supabase
        .from('app_config')
        .select('value')
        .eq('key', 'promo_banner')
        .maybeSingle();

    if (res != null && res['value'] != null) {
      final val = res['value'];
      if (val is Map) return Map<String, dynamic>.from(val);
      if (val is String) {
        // Support JSON string values too
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
    }
  } catch (_) {}
  return null;
});

final isDonationPopupEnabledProvider = FutureProvider<bool>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final res = await supabase
        .from('app_config')
        .select('value')
        .eq('key', 'donation_popup')
        .maybeSingle();

    if (res != null && res['value'] != null) {
      final val = res['value'];
      if (val is Map) {
        return val['is_active'] == true;
      }
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map) {
            return decoded['is_active'] == true;
          }
        } catch (_) {}
      }
    }
  } catch (_) {}
  return false;
});
