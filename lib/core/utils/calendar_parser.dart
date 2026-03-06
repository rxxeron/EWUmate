import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';

class CalendarParser {
  /// Parses the PDF bytes and returns a list of events matching the database structure.
  ///
  /// Returns List of Maps with keys:
  /// - date_string: The raw date string (e.g., "January 06", "January 11-13")
  /// - day: The day of the week (e.g., "Tuesday")
  /// - title: The event title
  /// - type: "Holiday" or "Academic"
  /// - semester: The semester code (e.g. "Spring2026")
  static Future<List<Map<String, dynamic>>> parsePdf(List<int> bytes, String semesterCode) async {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final String text = PdfTextExtractor(document).extractText();
    document.dispose();

    final List<Map<String, dynamic>> events = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || !_startsWithMonth(line)) {
        continue;
      }

      final row = _parseRow(lines, i, semesterCode);
      if (row.event != null) {
        events.add(row.event!);
        i = row.nextIndex - 1;
      }
    }

    return events;
  }

  static bool _startsWithMonth(String line) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months.any((m) => line.startsWith(m));
  }

  static _RowResult _parseRow(List<String> lines, int startIndex, String semesterCode) {
    final dateString = lines[startIndex].trim();
    String? dayString;
    String eventTitle = "";
    int j = startIndex + 1;

    // 1. Look ahead for Day
    if (j < lines.length) {
      final next = lines[j].trim();
      if (_isDay(next)) {
        dayString = next;
        j++;
      }
    }

    // 2. Capture Event
    while (j < lines.length) {
      final next = lines[j].trim();
      if (_startsWithMonth(next)) break;
      if (next.contains('Page') || next.contains('Registrar')) {
        j++;
        continue;
      }

      if (eventTitle.isNotEmpty) eventTitle += " ";
      eventTitle += next;
      j++;
    }

    Map<String, dynamic>? event;
    if (dayString != null && eventTitle.isNotEmpty) {
      event = {
        "date_string": dateString,
        "day": dayString,
        "title": eventTitle,
        "type": eventTitle.toLowerCase().contains("holiday") ? "Holiday" : "Academic",
        "semester": semesterCode
      };
    }

    return _RowResult(event, j);
  }

  static bool _isDay(String s) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    if (s.contains('-')) {
      return s.split('-').any((p) => days.contains(p.trim()));
    }
    return days.contains(s);
  }
}

class _RowResult {
  final Map<String, dynamic>? event;
  final int nextIndex;
  _RowResult(this.event, this.nextIndex);
}
}
