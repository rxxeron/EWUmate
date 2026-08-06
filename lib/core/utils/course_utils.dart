class CourseUtils {
  /// Normalizes a course code by removing spaces and capital letters.
  static String normalize(String code) {
    return code.replaceAll(' ', '').toUpperCase();
  }

  /// Returns the curriculum equivalent of a code (3-digit <-> 7-prefixed 4-digit).
  static String getEquivalent(String code) {
    final base = normalize(code);
    final reg3 = RegExp(r'^([A-Z]{2,4})(\d{3})$');
    final reg4 = RegExp(r'^([A-Z]{2,4})7(\d{3})$');
    
    if (reg3.hasMatch(base)) {
      final match = reg3.firstMatch(base)!;
      return '${match.group(1)}7${match.group(2)}';
    } else if (reg4.hasMatch(base)) {
      final match = reg4.firstMatch(base)!;
      return '${match.group(1)}${match.group(2)}';
    }
    return base;
  }

  /// Checks if two course codes are functionally equivalent.
  static bool areEquivalent(String? code1, String? code2) {
    if (code1 == null || code2 == null) return false;
    final n1 = normalize(code1);
    final n2 = normalize(code2);
    if (n1 == n2) return true;
    
    final e1 = getEquivalent(n1);
    return e1 == n2 || getEquivalent(n2) == n1;
  }

  /// Centralized semester cleaning (removes spaces, underscores, and lowers case)
  static String cleanSemester(String code) {
    return code.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
  }

  /// Determines if a semester is chronologically before Spring 2025.
  static bool isSemesterBeforeSpring2025(String? semester) {
    if (semester == null || semester.isEmpty) return true; // Default to older curriculum
    final clean = cleanSemester(semester);
    final reg = RegExp(r'^([a-z]+)(\d{4})$');
    final match = reg.firstMatch(clean);
    if (match != null) {
      final year = int.tryParse(match.group(2)!) ?? 0;
      if (year < 2025) return true;
      if (year > 2025) return false;
      // If year is 2025, Spring 2025 and onwards is new curriculum.
      return false;
    }
    return true;
  }

  /// RESTORED: Resolves dynamic table names (e.g., calendar_spring2026_phrm_llb)
  static String semesterTable(String prefix, String semesterCode, {String? cycleType}) {
    final safeSem = cleanSemester(semesterCode);
    final table = '${prefix}_$safeSem';
    final isBi = cycleType == 'bi' || cycleType == 'bi_semester' || cycleType == 'phrm_llb' || cycleType == 'bi-semester';
    final programSpecifier = (prefix == 'calendar' && isBi) ? '_phrm_llb' : '';
    return '$table$programSpecifier';
  }

  /// RESTORED: Formats "Spring2026" to "Spring 2026"
  static String prettifySemesterCode(String code) {
    if (code.isEmpty) return code;
    // Heuristic: Split into letters and numbers
    final reg = RegExp(r'^([a-zA-Z]+)(\d{4})$');
    if (reg.hasMatch(code)) {
      final match = reg.firstMatch(code)!;
      final sem = match.group(1)!;
      final year = match.group(2)!;
      return "${sem[0].toUpperCase()}${sem.substring(1).toLowerCase()} $year";
    }
    return code;
  }

  /// RESTORED: Standard time conflict checker for onboarding
  static Map<String, dynamic>? hasTimeConflict(List<Map<String, dynamic>> enrolled, Map<String, dynamic> newCourse) {
    final newTimeStr = newCourse['time']?.toString() ?? '';
    if (newTimeStr.isEmpty || newTimeStr == 'TBA') return null;

    final newDaysTimes = _parseSchedule(newTimeStr);

    for (final course in enrolled) {
      final courseTimeStr = course['time']?.toString() ?? '';
      if (courseTimeStr.isEmpty || courseTimeStr == 'TBA') continue;

      final existingDaysTimes = _parseSchedule(courseTimeStr);

      for (final newDt in newDaysTimes) {
        for (final existingDt in existingDaysTimes) {
          if (newDt.day == existingDt.day) {
            // Check for time overlap
            if (newDt.start < existingDt.end && existingDt.start < newDt.end) {
              return course;
            }
          }
        }
      }
    }
    return null;
  }

  static List<_DayTime> _parseSchedule(String schedule) {
    final results = <_DayTime>[];
    final parts = schedule.split(' ');
    if (parts.length < 3) return results;

    final days = parts[0];
    final timeRange = parts.sublist(1).join(' ');

    final times = timeRange.split('-');
    if (times.length < 2) return results;

    final start = _parseTime(times[0]);
    final end = _parseTime(times[1]);

    for (var i = 0; i < days.length; i++) {
       results.add(_DayTime(days[i], start, end));
    }
    return results;
  }

  static double parseTimeToDouble(String timeStr) {
    final parts = timeStr.trim().split(' ');
    if (parts.length < 2) return 0.0;
    
    final hhmm = parts[0].split(':');
    double hour = double.tryParse(hhmm[0]) ?? 0.0;
    double min = hhmm.length > 1 ? (double.tryParse(hhmm[1]) ?? 0.0) : 0.0;
    final ampm = parts[1].toUpperCase();

    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;

    return hour + (min / 60.0);
  }

  /// Determines if a session is a Lab based on > 90 min duration for 100-400 level courses or PHRM...L.
  static bool isLab(String startTime, String endTime, [String? courseCode]) {
    if (courseCode != null && courseCode.isNotEmpty) {
      final codeUpper = courseCode.toUpperCase().replaceAll(' ', '');
      if (codeUpper.startsWith('PHRM') && codeUpper.endsWith('L')) {
        return true;
      }

      // Check course level number
      final match = RegExp(r'^\D*(\d{3,4})').firstMatch(codeUpper);
      if (match != null) {
        int levelNum = int.tryParse(match.group(1)!) ?? 0;
        if (levelNum >= 1000) {
          // 4-digit code e.g. CSE7101 -> 101 level
          levelNum = int.tryParse(match.group(1)!.substring(1)) ?? 0;
        }
        // Graduate level courses (500+) are Theory even with 3-hour slots
        if (levelNum >= 500) {
          return false;
        }
      }
    }
    if (startTime.isEmpty || endTime.isEmpty) return false;
    final start = parseTimeToDouble(startTime);
    final end = parseTimeToDouble(endTime);
    // 100-400 level courses: > 90 minutes (1.5 hours) is Lab
    return (end - start) > 1.501;
  }

  static double _parseTime(String timeStr) => parseTimeToDouble(timeStr);
}

class _DayTime {
  final String day;
  final double start;
  final double end;
  _DayTime(this.day, this.start, this.end);
}
