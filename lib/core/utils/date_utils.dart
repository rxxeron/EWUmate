/// Utility class for date-related operations
class DateUtils {
  static const Map<String, int> _months = {
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

  /// Parses a date string (e.g., "24 April 2026", "January 15, 2026")
  /// Returns DateTime or null if parsing fails
  static DateTime? parseDate(String dateStr) {
    try {
      final parts = dateStr
          .replaceAll(',', '')
          .split(' ')
          .where((p) => p.isNotEmpty)
          .toList();

      int? day, month, year;

      for (var p in parts) {
        final lower = p.toLowerCase();
        if (_months.containsKey(lower)) {
          month = _months[lower];
        } else if (int.tryParse(p) != null) {
          final num = int.parse(p);
          if (num > 31) {
            year = num;
          } else {
            day = num;
          }
        }
      }

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    } catch (_) {
      // Return null on any error
    }
    return null;
  }

  /// Parses event date string (similar to parseDate but handles various formats)
  static DateTime? parseEventDate(String dateStr) {
    return parseDate(dateStr);
  }
}
