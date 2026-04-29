/// Utility class for time-related operations
class TimeUtils {
  /// Parses a time string (e.g., "8:30 AM", "2:00 PM") to minutes since midnight
  /// Returns minutes (0-1439) or 24*60 (1440) for invalid input
  static int parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 24 * 60;

    try {
      final lower = timeStr.toLowerCase().trim();
      final isPm = lower.contains('pm');
      final isAm = lower.contains('am');

      final clean = lower.replaceAll(RegExp(r'[a-z]'), '').trim();
      final parts = clean.split(':');

      int h = int.parse(parts[0]);
      final int m = (parts.length > 1) ? int.parse(parts[1]) : 0;

      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;

      return h * 60 + m;
    } catch (e) {
      return 24 * 60;
    }
  }

  /// Converts weekday (1=Monday, 2=Tuesday, ..., 7=Sunday) to single-letter code
  /// Returns: 'M', 'T', 'W', 'R', 'F', 'A', 'S' or empty string for invalid
  static String getDayLetter(int weekday) {
    switch (weekday) {
      case 1:
        return 'M'; // Monday
      case 2:
        return 'T'; // Tuesday
      case 3:
        return 'W'; // Wednesday
      case 4:
        return 'R'; // Thursday
      case 5:
        return 'F'; // Friday
      case 6:
        return 'A'; // Saturday
      case 7:
        return 'S'; // Sunday
      default:
        return '';
    }
  }

  /// Extracts the numeric part of a time string (e.g. "08:30" from "08:30 AM").
  static String extractTimeNumber(String timeStr) {
    if (timeStr.isEmpty) return "--";
    return timeStr.split(" ").first;
  }

  /// Extracts the AM/PM part of a time string.
  static String extractAmPm(String timeStr) {
    if (timeStr.isEmpty) return "";
    final upper = timeStr.toUpperCase();
    if (upper.contains("PM")) return "PM";
    if (upper.contains("AM")) return "AM";
    return "";
  }

  /// Returns a greeting based on the current time.
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return "Good Night";
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }
}
