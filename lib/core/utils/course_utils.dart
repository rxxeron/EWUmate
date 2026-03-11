import 'package:flutter/foundation.dart';
import '../models/course_model.dart';

class CourseUtils {
  /// Matches course codes like ENG101 (metadata) and ENG7101 (faculty data).
  /// Typically, 4-digit codes starting with 7 or 9 are used to represent 3-digit courses
  /// in certain departmental systems.
  static bool areCodesMatching(String codeA, String codeB) {
    if (codeA == codeB) return true;

    final normalizedA = normalizeCode(codeA);
    final normalizedB = normalizeCode(codeB);

    return normalizedA == normalizedB;
  }

  /// Normalizes a course code to a 3-digit equivalent if possible.
  /// Example: ENG7101 -> ENG101, CSE9211 -> CSE211
  static String normalizeCode(String code) {
    final clean = code.replaceAll(' ', '').toUpperCase();
    
    // Pattern: [Letters][Digits]
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(clean);
    if (match == null) return clean;

    final letters = match.group(1)!;
    final digits = match.group(2)!;

    if (digits.length == 4) {
      // If 4 digits, try dropping the first one if it's a known prefix (7, 9, etc.)
      // or just generally dropping it if the user suggests 4->3 mapping is common.
      // Based on user feedback: ENG7101 matches ENG101.
      return letters + digits.substring(1);
    }

    return clean;
  }

  /// Checks if a course section is available (not full and not 0/0 capacity).
  static bool isAvailable(String? capacity) {
    if (capacity == null || capacity == "0/0") return false;
    try {
      final parts = capacity.split('/');
      if (parts.length == 2) {
        final enr = int.parse(parts[0]);
        final tot = int.parse(parts[1]);
        return tot > 0 && enr < tot;
      }
    } catch (_) {}
    return false;
  }

  /// Builds a safe, lowercase table name for semester-specific tables.
  ///
  /// Usage:
  ///   CourseUtils.semesterTable('courses', 'Spring 2026')
  ///   // → 'courses_spring2026'
  ///
  ///   CourseUtils.semesterTable('exams', 'Summer 2026')
  ///   // → 'exams_summer2026'
  ///
  /// This is the SINGLE SOURCE OF TRUTH for table name generation.
  /// All repositories MUST use this instead of manual string interpolation.
  static String semesterTable(String prefix, String semesterCode, {String? cycleType}) {
    final safeSem = semesterCode.toLowerCase().replaceAll(' ', '');
    String table = '${prefix}_$safeSem';
    if (cycleType == 'bi') {
      table = '${table}_phrm_llb';
    }
    return table;
  }

  /// Builds a safe, lowercase cache key for Hive.
  /// Optionally includes cycleType (tri/bi) to separate departmental data.
  static String safeCacheKey(String prefix, String semesterCode, {String? cycleType}) {
    final safeSem = semesterCode.toLowerCase().replaceAll(' ', '');
    if (cycleType != null && cycleType.isNotEmpty) {
      return '${prefix}_${safeSem}_$cycleType';
    }
    return '${prefix}_$safeSem';
  }

  /// Parses a time string like "10:10 AM" into total minutes from midnight
  static int _parseTime(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    if (timeStr.isEmpty || timeStr == "TBA") return 0;

    int hour = 0, minute = 0;
    bool isPM = timeStr.contains("PM");

    final cleanStr = timeStr.replaceAll(RegExp(r'[A-Z\s]'), ''); // Remove PM/AM and spaces
    final parts = cleanStr.split(':');

    if (parts.isNotEmpty) hour = int.tryParse(parts[0]) ?? 0;
    if (parts.length > 1) minute = int.tryParse(parts[1]) ?? 0;

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0; // Midnight edge cases, though rare in scheduling

    return (hour * 60) + minute;
  }

  /// Determines if enrolling in `newCourse` causes a time overlap with any `Course` in `enrolledCourses`
  static Course? hasTimeConflict(List<Course> enrolledCourses, Course newCourse) {
    if (newCourse.sessions.isEmpty) return null; // TBA or unscheduled courses don't conflict

    for (var existing in enrolledCourses) {
      if (existing.sessions.isEmpty) continue;

      for (var existingSession in existing.sessions) {
        for (var newSession in newCourse.sessions) {
          // Check if they land on the same day(s). e.g., 'MW' and 'M' have an intersection
          bool daysOverlap = false;
          for (int i = 0; i < existingSession.day.length; i++) {
             if (newSession.day.contains(existingSession.day[i])) {
                 daysOverlap = true;
                 break;
             }
          }

          if (daysOverlap) {
            int existingStart = _parseTime(existingSession.startTime);
            int existingEnd = _parseTime(existingSession.endTime);
            int newStart = _parseTime(newSession.startTime);
            int newEnd = _parseTime(newSession.endTime);
            
            // Standard time overlap check: A overlaps B if A starts before B ends AND A ends after B starts
            if (existingStart < newEnd && existingEnd > newStart) {
               return existing; // Return the specific course causing the conflict
            }
          }
        }
      }
    }
    return null;
  }
}
