import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/academic_event_model.dart';

class AcademicRepository {
  final _supabase = Supabase.instance.client;

  // Determines current semester code from config table
  Future<String> getCurrentSemesterCode() async {
    try {
      final res = await _supabase
          .from('config')
          .select('value')
          .eq('key', 'currentSemester')
          .single();

      return res['value'] as String;
    } catch (e) {
      debugPrint("Error fetching current semester: $e");
      return 'Spring2026'; // Fallback
    }
  }

  Future<List<AcademicEvent>> fetchHolidays(String semesterCode) async {
    try {
      final data = await _supabase
          .from('calendar')
          .select()
          .eq('semester', semesterCode);

      return (data as List)
          .map((d) => AcademicEvent(
              date: d['date_string'] ?? d['date'],
              title: d['event'] ?? d['title']))
          .toList();
    } catch (e) {
      debugPrint("Error fetching holidays for $semesterCode: $e");
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> fetchExamSchedule(
      String semesterCode) async {
    try {
      final data =
          await _supabase.from('exams').select().eq('semester', semesterCode);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint("Error fetching exams: $e");
    }
    return [];
  }

  /// Fetches pre-generated personalized schedule from Cloud
  Future<Map<String, dynamic>?> fetchPersonalizedSchedule(
      String userId, String semesterCode) async {
    try {
      final data = await _supabase
          .from('user_schedules')
          .select()
          .eq('user_id', userId)
          .single();

      return data;
    } catch (e) {
      debugPrint("Error fetching personalized schedule: $e");
      return null;
    }
  }

  /// Finds an event by matching keywords in the title
  Future<AcademicEvent?> findEvent(
      String semesterCode, List<String> keywords) async {
    final events = await fetchHolidays(semesterCode);
    try {
      return events.firstWhere((e) => keywords
          .any((kw) => e.title.toLowerCase().contains(kw.toLowerCase())));
    } catch (e) {
      return null;
    }
  }

  /// Gets the "First Day of Classes" date for a semester
  Future<DateTime?> getFirstDayOfClasses(String semesterCode) async {
    final event = await findEvent(semesterCode, [
      "First Day of Classes",
      "Classes Begin",
      "Semester Begins",
    ]);
    if (event == null) return null;
    return _parseDate(event.date, semesterCode);
  }

  /// Gets the "Last Day of Classes" date for a semester
  Future<DateTime?> getLastDayOfClasses(String semesterCode) async {
    final event = await findEvent(semesterCode, [
      "Last Day of Classes",
      "Classes End",
      "End of Classes",
    ]);
    if (event == null) return null;
    return _parseDate(event.date, semesterCode);
  }

  /// Gets the "Final Examinations" start date for a semester
  Future<DateTime?> getFinalExamDate(String semesterCode) async {
    final event = await findEvent(semesterCode, [
      "Final Examinations",
      "Final Exam",
      "Final Exams Begin",
    ]);
    if (event == null) return null;
    return _parseDate(event.date, semesterCode);
  }

  /// Gets the "Submission of Final Grades" date for a semester
  Future<DateTime?> getFinalGradeSubmissionDate(String semesterCode) async {
    final event = await findEvent(semesterCode, [
      "Submission of Final Grades",
      "Final Grades Submission",
      "Grade Submission",
    ]);
    if (event == null) return null;
    return _parseDate(event.date, semesterCode);
  }

  /// Gets the "Online Advising of Courses" date for the NEXT semester
  Future<DateTime?> getOnlineAdvisingDate(String currentSemesterCode) async {
    final event = await findEvent(currentSemesterCode, [
      "Online Advising of Courses",
      "Online Advising",
      "Advising of Courses",
    ]);
    if (event == null) return null;
    return _parseDate(event.date, currentSemesterCode);
  }

  /// Gets the "Adding of Courses" date for the NEXT semester
  Future<DateTime?> getAddingOfCoursesDate(String currentSemesterCode) async {
    final event = await findEvent(currentSemesterCode, [
      "Adding of Courses",
      "Add Courses",
      "Course Add",
    ]);
    if (event == null) return null;
    return _parseDate(event.date, currentSemesterCode);
  }

  /// Determines the next semester code based on current
  /// Spring -> Summer, Summer -> Fall, Fall -> Spring (next year)
  String getNextSemesterCode(String currentCode) {
    // Parse current code (e.g., "Spring2026" or "Fall2026")
    final regExp = RegExp(r'(Spring|Summer|Fall)(\d{4})');
    final match = regExp.firstMatch(currentCode);
    if (match == null) {
      // Fallback
      final year = DateTime.now().year;
      return 'Summer$year';
    }

    final season = match.group(1) ?? 'Spring';
    final yearStr = match.group(2);
    final year = yearStr != null ? int.parse(yearStr) : DateTime.now().year;

    switch (season) {
      case 'Spring':
        return 'Summer$year';
      case 'Summer':
        return 'Fall$year';
      case 'Fall':
        return 'Spring${year + 1}';
      default:
        return 'Summer$year';
    }
  }

  /// Parses date strings like "14 April 2026" or "April 14, 2026" or "March 15"
  /// [contextStr] can be a semester code (Spring2026) to help infer year if missing
  DateTime? _parseDate(String dateStr, [String? contextStr]) {
    try {
      final months = {
        'january': 1,
        'february': 2,
        'march': 3,
        'april': 4,
        'may': 5,
        'june': 6,
        'july': 7,
        'august': 8,
        'september': 9,
        'october': 10,
        'november': 11,
        'december': 12,
      };

      final parts = dateStr
          .replaceAll(',', '')
          .split(' ')
          .where((p) => p.isNotEmpty)
          .toList();

      // Need at least day and month
      if (parts.length < 2) return null;

      int? day, month, year;

      for (var p in parts) {
        final lower = p.toLowerCase();
        if (months.containsKey(lower)) {
          month = months[lower];
        } else if (int.tryParse(p) != null) {
          final num = int.parse(p);
          if (num > 31) {
            year = num;
          } else {
            day = num;
          }
        }
      }

      // If year is missing, try to infer from context (e.g. Spring2026)
      if (year == null && contextStr != null) {
        final yearMatch = RegExp(r'\d{4}').firstMatch(contextStr);
        if (yearMatch != null) {
          year = int.parse(yearMatch.group(0)!);
        }
      }

      // Default to current year if still missing (fallback)
      year ??= DateTime.now().year;

      if (day != null && month != null) {
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint("Date parse error: $e");
    }
    return null;
  }
}
