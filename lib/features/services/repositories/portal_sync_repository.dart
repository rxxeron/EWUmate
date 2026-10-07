import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/course_utils.dart';
import '../../../../core/services/portal_service.dart';

final portalSyncRepositoryProvider = Provider<PortalSyncRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PortalSyncRepository(supabase);
});

class PortalSyncRepository {
  final SupabaseClient _supabase;

  PortalSyncRepository(this._supabase);

  /// Fetch human-readable course names for a given semester
  Future<Map<String, String>> fetchCourseNames(String activeSemCode) async {
    final Map<String, String> courseNames = {};
    try {
      final catalogRes = await _supabase
          .from('courses_$activeSemCode')
          .select('course_code, course_name');
      for (final row in catalogRes as List) {
        final code = (row['course_code'] ?? '').toString();
        final name = (row['course_name'] ?? '').toString();
        if (code.isNotEmpty && name.isNotEmpty) {
          courseNames[code] = name;
        }
      }
    } catch (_) {
      try {
        final metaRes = await _supabase.from('course_metadata').select('code, name');
        for (final row in metaRes as List) {
          final code = (row['code'] ?? '').toString();
          final name = (row['name'] ?? '').toString();
          if (code.isNotEmpty && name.isNotEmpty) {
            courseNames[code] = name;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[PortalSyncRepo] fetchCourseNames fallback failed: $e');
      }
    }
    return courseNames;
  }

  /// Syncs active semester schedule and enrollments using smart diff
  Future<void> syncActiveSchedule({
    required String userId,
    required String activeSemCode,
    required List<PortalEnrolledCourse> activeCourses,
    required Map<String, String> courseNames,
    required Map<String, dynamic> weeklyGrid,
  }) async {
    // 1. Fetch existing enrollments
    final existingEnrollmentsRes = await _supabase
        .from('enrollments')
        .select('id, course_code, section')
        .eq('user_id', userId)
        .eq('semester_code', activeSemCode);

    final Map<String, dynamic> existingByCode = {};
    for (final row in (existingEnrollmentsRes as List)) {
      final code = (row['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
      existingByCode[code] = row;
    }

    final Map<String, PortalEnrolledCourse> portalByCode = {};
    for (final c in activeCourses) {
      final clean = (c.courseCode.contains(' ') ? c.courseCode.split(' ')[0] : c.courseCode)
          .toUpperCase()
          .replaceAll(' ', '');
      portalByCode[clean] = c;
    }

    final Set<String> existingCodes = existingByCode.keys.toSet();
    final Set<String> portalCodes = portalByCode.keys.toSet();

    final Set<String> toRemove = existingCodes.difference(portalCodes);
    final Set<String> toAdd = portalCodes.difference(existingCodes);
    final Set<String> toCheck = existingCodes.intersection(portalCodes);

    // Remove dropped courses in a single batch query
    if (toRemove.isNotEmpty) {
      await _supabase
          .from('enrollments')
          .delete()
          .eq('user_id', userId)
          .eq('semester_code', activeSemCode)
          .inFilter('course_code', toRemove.toList());
    }

    // Insert brand new courses
    if (toAdd.isNotEmpty) {
      final newEnrollments = <Map<String, dynamic>>[];
      final newProgressRows = <Map<String, dynamic>>[];

      for (final addCode in toAdd) {
        final item = portalByCode[addCode]!;
        newEnrollments.add({
          'user_id': userId,
          'course_code': addCode,
          'section': item.section,
          'semester_code': activeSemCode,
          'status': 'enrolled',
        });

        newProgressRows.add({
          'user_id': userId,
          'course_code': addCode,
          'course_name': courseNames[addCode] ?? addCode,
          'section': item.section,
          'semester_code': activeSemCode,
        });
      }

      if (newEnrollments.isNotEmpty) {
        await _supabase.from('enrollments').insert(newEnrollments);
      }
      if (newProgressRows.isNotEmpty) {
        try {
          await _supabase.from('semester_course_marks').insert(newProgressRows);
        } catch (e) {
          if (kDebugMode) debugPrint('[PortalSyncRepo] semester_course_marks insert note: $e');
        }
      }
    }

    // Update section if section changed
    for (final code in toCheck) {
      final oldSec = (existingByCode[code]['section'] ?? '').toString().trim();
      final newSec = portalByCode[code]!.section.trim();
      if (oldSec != newSec) {
        await _supabase
            .from('enrollments')
            .update({'section': newSec})
            .eq('user_id', userId)
            .eq('semester_code', activeSemCode)
            .eq('course_code', code);

        await _supabase
            .from('semester_course_marks')
            .update({'section': newSec})
            .eq('user_id', userId)
            .eq('semester_code', activeSemCode)
            .eq('course_code', code);
      }
    }

    // Upsert weekly routine grid cache
    try {
      await _supabase.from('user_semester_states').upsert({
        'user_id': userId,
        'semester_code': activeSemCode,
        'weekly_grid_cache': weeklyGrid,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,semester_code');
    } catch (e) {
      if (kDebugMode) debugPrint('[PortalSyncRepo] user_semester_states weekly_grid error: $e');
    }
  }

  /// Syncs completed course records
  Future<void> syncAcademicHistory({
    required String userId,
    required List<Map<String, dynamic>> parsedGrades,
  }) async {
    final List<Map<String, dynamic>> completedRows = [];
    for (final c in parsedGrades) {
      completedRows.add({
        'user_id': userId,
        'course_code': c['course_code'],
        'grade': c['grade'],
        'grade_point': c['grade_point'],
        'credits': c['credits'],
        'semester_code': CourseUtils.cleanSemester(c['semester_code'] ?? ''),
      });
    }

    if (completedRows.isNotEmpty) {
      await _supabase.from('completed_courses').delete().eq('user_id', userId);
      await _supabase.from('completed_courses').insert(completedRows);
    }
  }

  /// Resolves profile program metadata and updates the profiles table
  Future<void> syncProfileMetadata({
    required String userId,
    required PortalStudentProfile profile,
  }) async {
    final cleanAdmittedSem = CourseUtils.cleanSemester(profile.admittedSemester);

    String resolvedProgramCode = profile.programCode.trim();
    String resolvedProgramName = profile.programName.trim();
    String resolvedDeptName = profile.departmentName.trim();

    try {
      final progsRes = await _supabase
          .from('programs')
          .select('program_code, name, department_name');
      final progs = List<Map<String, dynamic>>.from(progsRes as List);

      Map<String, dynamic>? match = progs.firstWhere(
        (p) => (p['program_code'] ?? '').toString().toUpperCase() == resolvedProgramCode.toUpperCase(),
        orElse: () => {},
      );

      if (match.isEmpty && resolvedProgramName.isNotEmpty) {
        match = progs.firstWhere(
          (p) {
            final pName = (p['name'] ?? '').toString().toLowerCase();
            final targetName = resolvedProgramName.toLowerCase();
            return pName.contains(targetName) || targetName.contains(pName);
          },
          orElse: () => {},
        );
      }

      if (match.isEmpty && resolvedProgramCode.isNotEmpty) {
        match = progs.firstWhere(
          (p) => (p['program_code'] ?? '').toString().toUpperCase().contains(resolvedProgramCode.toUpperCase()),
          orElse: () => {},
        );
      }

      if (match.isNotEmpty) {
        resolvedProgramCode = match['program_code']?.toString() ?? resolvedProgramCode;
        resolvedProgramName = match['name']?.toString() ?? resolvedProgramName;
        resolvedDeptName = match['department_name']?.toString() ?? resolvedDeptName;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PortalSyncRepo] Program matching note: $e');
    }

    final profilePayload = <String, dynamic>{
      'id': userId,
      'student_id': profile.studentId,
      'program_code': resolvedProgramCode.toUpperCase(),
      'program_name': resolvedProgramName,
      'department_name': resolvedDeptName,
      'onboarding_status': 'completed',
    };
    if (profile.fullName.isNotEmpty) {
      profilePayload['full_name'] = profile.fullName;
    }
    if (cleanAdmittedSem.isNotEmpty) {
      profilePayload['admitted_semester'] = cleanAdmittedSem;
    }
    await _supabase.from('profiles').upsert(profilePayload);
  }

  /// Sets onboarding status to completed
  Future<void> markOnboardingCompleted(String userId) async {
    await _supabase.from('profiles').update({
      'onboarding_status': 'completed',
    }).eq('id', userId);
  }
}
