import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faculty_review.dart';
import '../providers/supabase_provider.dart';

final facultyReviewsRepositoryProvider = Provider<FacultyReviewsRepository>((ref) {
  return FacultyReviewsRepository(ref.watch(supabaseClientProvider));
});

final allCoursesCatalogProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final repo = ref.watch(facultyReviewsRepositoryProvider);
  return repo.getAllCourses();
});

final allSemestersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(facultyReviewsRepositoryProvider);
  return repo.getAllSemesters();
});

class FacultyReviewsRepository {
  final SupabaseClient _supabase;

  FacultyReviewsRepository(this._supabase);

  // Fetch all courses for relational picker dropdown
  Future<List<Map<String, String>>> getAllCourses() async {
    try {
      final res = await _supabase
          .from('course_metadata')
          .select('code, name')
          .order('code', ascending: true)
          .limit(2000);
      return (res as List).map((e) {
        return {
          'code': (e['code'] ?? '').toString().toUpperCase(),
          'name': (e['name'] ?? '').toString(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Fetch all semesters for relational picker dropdown
  Future<List<Map<String, dynamic>>> getAllSemesters() async {
    try {
      final res = await _supabase
          .from('semesters')
          .select('code, title, is_active')
          .order('portal_semester_id', ascending: false);
      return (res as List).map((e) {
        return {
          'code': (e['code'] ?? '').toString(),
          'title': (e['title'] ?? '').toString(),
          'is_active': e['is_active'] == true,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Fetch all approved reviews for a specific faculty member
  Future<List<FacultyReview>> getApprovedReviews(String initials) async {
    try {
      final normalized = initials.trim().toUpperCase();
      final data = await _supabase
          .from('faculty_reviews')
          .select('''
            id,
            faculty_initials,
            faculty_name,
            course_code,
            semester,
            semester_code,
            status,
            delivery_type,
            grade_received,
            clarity_rating,
            grading_fairness,
            exam_alignment,
            office_hours_accessibility,
            attendance_strictness,
            workload_level,
            slide_reliance,
            quiz_frequency,
            textbook_need,
            traits,
            exam_prep_tips,
            review_note,
            would_take_again,
            created_at,
            updated_at
          ''')
          .eq('status', 'approved')
          .ilike('faculty_initials', normalized)
          .order('created_at', ascending: false);

      return (data as List).map((e) => FacultyReview.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Fetch current user's review for this faculty and course (if any)
  Future<FacultyReview?> getUserReview({
    required String initials,
    required String courseCode,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final normalizedInitials = initials.trim().toUpperCase();
      final normalizedCourse = courseCode.trim().toUpperCase();

      final data = await _supabase
          .from('faculty_reviews')
          .select('''
            *,
            profiles:user_id(full_name, student_id)
          ''')
          .eq('user_id', user.id)
          .ilike('faculty_initials', normalizedInitials)
          .ilike('course_code', normalizedCourse)
          .maybeSingle();

      if (data == null) return null;
      return FacultyReview.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Fetch all of current user's reviews for this faculty member
  Future<List<FacultyReview>> getUserReviewsForFaculty(String initials) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final normalizedInitials = initials.trim().toUpperCase();
      final data = await _supabase
          .from('faculty_reviews')
          .select('''
            *,
            profiles:user_id(full_name, student_id)
          ''')
          .eq('user_id', user.id)
          .ilike('faculty_initials', normalizedInitials)
          .order('created_at', ascending: false);

      return (data as List).map((e) => FacultyReview.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Submit a new faculty review
  Future<void> submitReview(FacultyReview review) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to submit a review.');

    final data = review.toMap();
    data['user_id'] = user.id;
    data['status'] = 'pending';
    data['admin_rejection_note'] = null;

    await _supabase.from('faculty_reviews').upsert(
          data,
          onConflict: 'user_id,faculty_initials,course_code',
        );
  }

  // Edit and resubmit a rejected review (or update an existing one)
  Future<void> resubmitReview(FacultyReview review) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in.');

    final data = review.toMap();
    data['status'] = 'pending';
    data['admin_rejection_note'] = null;
    data['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('faculty_reviews')
        .update(data)
        .eq('id', review.id)
        .eq('user_id', user.id);
  }

  // Delete own review
  Future<void> deleteReview(String reviewId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('faculty_reviews')
        .delete()
        .eq('id', reviewId)
        .eq('user_id', user.id);
  }
}
