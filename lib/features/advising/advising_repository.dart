import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/course_model.dart';
import '../../core/utils/course_utils.dart';

import '../../features/calendar/academic_repository.dart';
import '../../core/services/schedule_service.dart';

class AdvisingRepository {
  final _supabase = Supabase.instance.client;
  final _academicRepo = AcademicRepository();
  final _scheduleService = ScheduleService();

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<void> saveGeneratedPlan({
    required String semester,
    required List<String> inputCodes,
    required List<List<dynamic>> combinations,
  }) async {
    if (_uid == null) return;

    try {
      final simplifiedCombinations = combinations.map((combo) {
        return combo.map((section) => section['id']).toList();
      }).toList();

      await _supabase.from('schedule_generations').insert({
        'user_id': _uid,
        'semester': semester,
        'courses': inputCodes,
        'combinations': simplifiedCombinations,
        'count': combinations.length,
        'status': 'completed',
      });
    } catch (e) {
      debugPrint('Error saving plan: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getParamsStream(String semester) {
    if (_uid == null) return const Stream.empty();

    return _supabase
        .from('schedule_generations')
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid!)
        .map((data) {
          final list = data
              .where((d) => d['semester'] == semester)
              .map((d) => Map<String, dynamic>.from(d))
              .toList();
          list.sort((a, b) => b['created_at'].compareTo(a['created_at']));
          return list;
        });
  }

  Future<List<Course>> validateSchedule(
      String semester, List<String> sectionIds) async {
    if (sectionIds.isEmpty) return [];

    try {
      final freshCourses = <Course>[];
      // Always try the semester-specific table first (it may exist even if not "active")
      final semesterTable = CourseUtils.semesterTable('courses', semester);

      var data = <Map<String, dynamic>>[];
      try {
        data = await _supabase
            .from(semesterTable)
            .select()
            .inFilter('doc_id', sectionIds);
      } catch (_) {
        // Table might not exist, that's ok
      }

      // Fallback: try current semester table if the target returned empty
      if (data.isEmpty) {
        final currentCode = await _academicRepo.getCurrentSemesterCode();
        final currentTable = CourseUtils.semesterTable('courses', currentCode);
        if (currentTable != semesterTable) {
          debugPrint('[Advising] validateSchedule: $semesterTable returned empty, trying $currentTable');
          data = await _supabase
              .from(currentTable)
              .select()
              .inFilter('doc_id', sectionIds);
        }
      }

      for (var item in data) {
        freshCourses
            .add(Course.fromSupabase(item, item['doc_id'] ?? item['id']?.toString() ?? ''));
      }
      return freshCourses;
    } catch (e) {
      debugPrint('Error validating schedule: $e');
      return [];
    }
  }

  Future<void> saveFavoriteSchedule(String semester, List<String> sectionIds,
      {String? note}) async {
    if (_uid == null) return;
    debugPrint('[Advising] saveFavoriteSchedule: semester=$semester, ids=$sectionIds');

    try {
      final res = await _supabase
          .from('profiles')
          .select('favorite_schedules')
          .eq('id', _uid!)
          .single();
      final favorites = List<dynamic>.from(res['favorite_schedules'] ?? []);
      debugPrint('[Advising] Current favorites count: ${favorites.length}');

      favorites.add({
        'semester': semester,
        'sectionIds': sectionIds,
        'note': note ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _supabase
          .from('profiles')
          .update({'favorite_schedules': favorites}).eq('id', _uid!);
      debugPrint('[Advising] Save successful! New count: ${favorites.length}');
    } catch (e) {
      debugPrint("Error saving favorite: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getFavoriteSchedulesStream(
      String semester) {
    if (_uid == null) return const Stream.empty();

    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', _uid!)
        .map((data) {
          if (data.isEmpty) return [];
          final favorites =
              List<dynamic>.from(data.first['favorite_schedules'] ?? []);
          return favorites.where((f) => f['semester'] == semester).map((f) {
            final Map<String, dynamic> m = Map<String, dynamic>.from(f);
            // Ensure it has an ID for removal
            if (!m.containsKey('id')) m['id'] = m['createdAt'];
            return m;
          }).toList()
            ..sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
        });
  }

  Future<void> deleteFavoriteSchedule(String docId) async {
    if (_uid == null) return;
    try {
      final res = await _supabase
          .from('profiles')
          .select('favorite_schedules')
          .eq('id', _uid!)
          .single();
      final favorites = List<dynamic>.from(res['favorite_schedules'] ?? []);

      favorites
          .removeWhere((f) => (f['id'] == docId || f['createdAt'] == docId));

      await _supabase
          .from('profiles')
          .update({'favorite_schedules': favorites}).eq('id', _uid!);
    } catch (e) {
      debugPrint("Error deleting favorite: $e");
    }
  }

  Future<void> clearAllFavoriteSchedules(String semester) async {
    if (_uid == null) return;
    try {
      final res = await _supabase
          .from('profiles')
          .select('favorite_schedules')
          .eq('id', _uid!)
          .single();
      final favorites = List<dynamic>.from(res['favorite_schedules'] ?? []);

      favorites.removeWhere((f) => f['semester'] == semester);

      await _supabase
          .from('profiles')
          .update({'favorite_schedules': favorites}).eq('id', _uid!);
    } catch (e) {
      debugPrint("Error clearing favorites: $e");
    }
  }

  Future<void> saveManualPlan(String semester, List<String> sectionIds) async {
    if (_uid == null) return;
    try {
      final res = await _supabase
          .from('profiles')
          .select('planner')
          .eq('id', _uid!)
          .single();
      final planner = Map<String, dynamic>.from(res['planner'] ?? {});
      planner[semester.replaceAll(' ', '')] = sectionIds;
      await _supabase
          .from('profiles')
          .update({'planner': planner}).eq('id', _uid!);
    } catch (e) {
      debugPrint("Error saving planner: $e");
    }
  }

  Future<List<String>> getManualPlanIds(String semester) async {
    if (_uid == null) return [];
    try {
      final res = await _supabase
          .from('profiles')
          .select('planner')
          .eq('id', _uid!)
          .single();
      final planner = Map<String, dynamic>.from(res['planner'] ?? {});
      return List<String>.from(planner[semester.replaceAll(' ', '')] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<void> finalizeEnrollment(String semester) async {
    if (_uid == null) return;
    final planIds = await getManualPlanIds(semester);
    if (planIds.isEmpty) return;

    await _supabase.from('profiles').update({
      'enrolled_sections': planIds,
    }).eq('id', _uid!);

    // Trigger schedule sync
    await _scheduleService.syncUserSchedule(semester, planIds);
  }
}
