import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enrollment.dart';
import '../models/calendar_event.dart';
import '../models/schedule_exception.dart';
import '../providers/supabase_provider.dart';

class ScheduleRepository {
  final SupabaseClient _supabase;

  ScheduleRepository(this._supabase);

  Future<List<Enrollment>> getEnrollments(
    String userId,
    String semesterCode,
  ) async {
    final response = await _supabase
        .from('enrollments')
        .select()
        .eq('user_id', userId)
        .eq('semester_code', semesterCode);

    return (response as List).map((e) => Enrollment.fromJson(e)).toList();
  }

  /// Dynamically queries the calendar table for the specific semester
  Future<List<CalendarEvent>> getCalendarEvents(
    String tableSuffix,
    String track,
  ) async {
    try {
      final tableName = 'calendar_$tableSuffix';

      final response = await _supabase.from(tableName).select().inFilter(
        'target_track',
        [track, 'all'],
      ); // assuming 'all' might be used

      return (response as List).map((e) => CalendarEvent.fromJson(e)).toList();
    } catch (e) {
      // Fallback if table doesn't exist yet
      return [];
    }
  }

  Future<List<ScheduleException>> getScheduleExceptions(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _supabase
        .from('schedule_exceptions')
        .select()
        .eq('user_id', userId)
        .gte('date', from.toIso8601String())
        .lte('date', to.toIso8601String());

    return (response as List)
        .map((e) => ScheduleException.fromJson(e))
        .toList();
  }

  Future<void> saveSchedule({
    required String userId,
    required String semesterCode,
    required Map<String, dynamic> combinationData,
  }) async {
    await _supabase.from('user_drafts').upsert({
      'user_id': userId,
      'semester_code': semesterCode,
      'combination_data': combinationData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSavedSchedules(String userId) async {
    try {
      final response = await _supabase
          .from('user_drafts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) print("DEBUG: Error fetching saved schedules: $e");
      rethrow;
    }
  }

  Future<void> deleteDraft(String userId, String semesterCode) async {
    await _supabase
        .from('user_drafts')
        .delete()
        .eq('user_id', userId)
        .eq('semester_code', semesterCode);
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(supabaseClientProvider));
});
