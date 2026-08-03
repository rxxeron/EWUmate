import 'package:supabase_flutter/supabase_flutter.dart';

class ExceptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  /// Fetch all active exceptions for the user for the current semester
  Future<List<Map<String, dynamic>>> fetchExceptions() async {
    if (_uid == null) return [];
    try {
      final data = await _supabase
          .from('schedule_exceptions')
          .select()
          .eq('user_id', _uid!);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  /// Add a cancellation exception
  Future<void> addCancellation(String date, String courseCode, {bool pendingMakeup = false}) async {
    if (_uid == null) return;
    try {
      await _supabase.from('schedule_exceptions').insert({
        'user_id': _uid,
        'type': 'cancel',
        'date': date,
        'course_code': courseCode,
        'metadata': {'pendingMakeup': pendingMakeup},
      });
    } catch (e) {
    }
  }

  /// Add a makeup class exception
  Future<void> addMakeupClass({
    required String date,
    required String courseCode,
    required String courseName,
    required String startTime,
    required String endTime,
    required String room,
    String? faculty,
  }) async {
    if (_uid == null) return;
    try {
      await _supabase.from('schedule_exceptions').insert({
        'user_id': _uid,
        'type': 'makeup',
        'date': date,
        'course_code': courseCode,
        'course_name': courseName,
        'start_time': startTime,
        'end_time': endTime,
        'room': room,
        'faculty': faculty,
        'metadata': {},
      });
    } catch (e) {
    }
  }

  /// Add a manual schedule entry
  Future<void> addManualClass({
    required String date,
    required String courseCode,
    required String courseName,
    required String startTime,
    required String endTime,
    required String room,
    String? faculty,
  }) async {
    if (_uid == null) return;
    try {
      await _supabase.from('schedule_exceptions').insert({
        'user_id': _uid,
        'type': 'manual',
        'date': date,
        'course_code': courseCode,
        'course_name': courseName,
        'start_time': startTime,
        'end_time': endTime,
        'room': room,
        'faculty': faculty,
        'metadata': {},
      });
    } catch (e) {
    }
  }

  /// Mark a pending makeup as resolved (called when makeup is actually scheduled)
  Future<void> resolvePendingMakeup(String originalExceptionId) async {
    if (_uid == null) return;
    try {
      await _supabase.from('schedule_exceptions')
          .update({ 'metadata': {'pendingMakeup': false} })
          .eq('id', originalExceptionId);
    } catch (e) {
    }
  }

  /// Remove an exception completely (Undo cancel)
  Future<void> removeException(String id) async {
    if (_uid == null) return;
    try {
      await _supabase.from('schedule_exceptions').delete().eq('id', id);
    } catch (e) {
    }
  }

  /// Find a specific exception ID
  Future<String?> findExceptionId(String date, String courseCode, String type) async {
    if (_uid == null) return null;
    try {
      final data = await _supabase
          .from('schedule_exceptions')
          .select('id')
          .eq('user_id', _uid!)
          .eq('date', date)
          .eq('course_code', courseCode)
          .eq('type', type)
          .maybeSingle();

      return data?['id']?.toString();
    } catch (e) {
      return null;
    }
  }
}
