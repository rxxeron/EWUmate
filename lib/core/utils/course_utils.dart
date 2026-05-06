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

  /// RESTORED: Resolves dynamic table names (e.g., calendar_spring2026_phrm_llb)
  static String semesterTable(String prefix, String semesterCode, {String? cycleType}) {
    final safeSem = cleanSemester(semesterCode);
    final table = '${prefix}_$safeSem';
    final isBi = cycleType == 'bi' || cycleType == 'bi_semester' || cycleType == 'phrm_llb' || cycleType == 'bi-semester';
    final programSpecifier = (isBi) ? '_phrm_llb' : '';
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

  /// Determines if a session is a Lab based on > 90 min duration or course code ending in L (PHRM).
  static bool isLab(String startTime, String endTime, [String? courseCode]) {
    if (courseCode != null && courseCode.isNotEmpty) {
      final codeUpper = courseCode.toUpperCase();
      if (codeUpper.startsWith('PHRM') && codeUpper.endsWith('L')) {
        return true;
      }
    }
    if (startTime.isEmpty || endTime.isEmpty) return false;
    final start = parseTimeToDouble(startTime);
    final end = parseTimeToDouble(endTime);
    // 90 minutes = 1.5 hours
    return (end - start) > 1.51; // .51 to avoid floating point precision issues for exactly 90
  }

  static double _parseTime(String timeStr) => parseTimeToDouble(timeStr);
}

class _DayTime {
  final String day;
  final double start;
  final double end;
  _DayTime(this.day, this.start, this.end);
}
