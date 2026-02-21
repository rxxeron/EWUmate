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
  static Future<List<Map<String, dynamic>>> parsePdf(
      List<int> bytes, String semesterCode) async {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();

    final List<Map<String, dynamic>> events = [];
    final lines = text.split('\n');

    // Simple state machine or regex to find table rows
    // The table format in PDF usually follows: Date | Day | Event
    // But extraction might put them on separate lines or join them.
    // Based on previous extraction, lines looked like:
    // January 06
    // Tuesday
    // University Reopens

    // We need to be smart. Let's look for Date patterns.
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      // print('Line $i: $line'); // Debug: Inspect line content

      // Check if line starts with a Month
      bool startsWithMonth = months.any((m) => line.startsWith(m));

      if (startsWithMonth) {
        // Potential start of a row
        // Structure might be:
        // Line 1: Date (January 06)
        // Line 2: Day (Tuesday)
        // Line 3...: Event (University Reopens)

        // However, PDF text extraction varies.
        // Let's assume the previous output structure:
        // Date and Day might be on same line or next.

        // Heuristic:
        // 1. Capture Date
        String dateString = line;

        // 2. Look ahead for Day
        // Days: Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
        // Also ranges: Sunday-Tuesday
        int j = i + 1;
        String? dayString;
        String eventString = "";

        if (j < lines.length) {
          String next = lines[j].trim();
          if (_isDay(next)) {
            dayString = next;
            j++; // Move past day
          }
        }

        // 3. Capture Event (until next date or end)
        while (j < lines.length) {
          String next = lines[j].trim();
          if (months.any((m) => next.startsWith(m))) {
            // Found next date, stop
            break;
          }
          // specific exclude keywords (page numbers, footers)
          if (next.contains('Page') || next.contains('Registrar')) {
            j++;
            continue;
          }

          if (eventString.isNotEmpty) eventString += " ";
          eventString += next;
          j++;
        }

        // Update main loop index to skip processed lines (j - 1 because loop does i++)
        // Actually we processed up to j-1. So i should become j-1.
        i = j - 1;

        if (dayString != null && eventString.isNotEmpty) {
          // Categorize
          String type = "Academic";
          if (eventString.toLowerCase().contains("holiday")) {
            type = "Holiday";
          }

          events.add({
            "date_string": dateString,
            "day": dayString,
            "title": eventString,
            "type": type,
            "semester": semesterCode
          });
        }
      }
    }

    return events;
  }

  static bool _isDay(String s) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    // Handle ranges like Sunday-Tuesday
    if (s.contains('-')) {
      final parts = s.split('-');
      return parts.any((p) => days.contains(p.trim()));
    }
    return days.contains(s);
  }
}
