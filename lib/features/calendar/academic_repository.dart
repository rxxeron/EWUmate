import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/academic_event_model.dart';

class AcademicRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Determines current semester code from academic calendar collections
  Future<String> getCurrentSemesterCode() async {
    final now = DateTime.now();
    final year = now.year;

    // Ordered list of semesters to check
    final semestersToCheck = [
      'Fall${year - 1}', // Previous fall (in case we're in early Jan)
      'Spring$year',
      'Summer$year',
      'Fall$year',
    ];

    String? currentSemester;

    // Find the most recent semester whose "University Reopens" date has passed
    for (final code in semestersToCheck) {
      try {
        final events = await fetchHolidays(code);

        // Look for "University Reopens for X" event in this semester
        final reopenEvent = events.firstWhere(
          (e) =>
              e.title.contains("University Reopens for") ||
              e.title.contains("University Opens for"),
          orElse: () => AcademicEvent(date: '', title: ''),
        );

        if (reopenEvent.title.isNotEmpty) {
          final reopenDate = _parseDate(reopenEvent.date, reopenEvent.title);
          if (reopenDate != null && now.isAfter(reopenDate)) {
            // We've passed this reopening - extract the next semester
            final match = RegExp(r'(Spring|Summer|Fall)\s*(\d{4})')
                .firstMatch(reopenEvent.title);
            if (match != null) {
              currentSemester = '${match.group(1)}${match.group(2)}';
            }
          }
        }

        // Check "First Day of Classes" to confirm we're in this semester
        final firstDay = await getFirstDayOfClasses(code);
        if (firstDay != null && now.isAfter(firstDay)) {
          currentSemester = code;
        }
      } catch (e) {
        // Calendar doesn't exist for this semester, skip
      }
    }

    // Return detected semester or a default based on year
    return currentSemester ?? 'Spring2026';
  }

  Future<List<AcademicEvent>> fetchHolidays(String semesterCode) async {
    // Corrected to use exact casing (e.g. 'Spring2026') based on user screenshot
    // Collection name: `calendar_Spring2026`
    final collectionRef = _firestore.collection('calendar_$semesterCode');
    List<AcademicEvent> events = [];

    // Extract year from semesterCode for parsing dates (e.g. Spring2026 -> 2026)
    // int year = DateTime.now().year; -- logic moved to _parseDate fallback or explicit context

    try {
      // 1. Try Meta Doc
      final metaDoc = await collectionRef.doc('CALENDAR_META').get();
      if (metaDoc.exists) {
        final data = metaDoc.data();
        if (data != null &&
            data['allEvents'] != null &&
            data['allDates'] != null) {
          final List<dynamic> titles = data['allEvents'];
          final List<dynamic> dates = data['allDates'];

          for (int i = 0; i < titles.length; i++) {
            if (i < dates.length) {
              events.add(AcademicEvent(
                  date: dates[i].toString(), title: titles[i].toString()));
            }
          }
          return events;
        }
      }

      // 2. Fallback: Query individual docs
      final querySnapshot = await collectionRef.get();
      for (var doc in querySnapshot.docs) {
        if (doc.data()['type'] == 'CALENDAR_EVENT' ||
            doc.data().containsKey('event')) {
          // Provide year context to parsing if needed, but for now we rely on the event string
          // We might need to handle the date parsing smarter here or in _parseDate
          // The screenshot shows "date": "March 15".
          var eventData = doc.data();
          // map legacy fields if needed
          if (eventData['event'] != null && eventData['title'] == null) {
            eventData['title'] = eventData['event'];
          }
          // parse date with context
          AcademicEvent event = AcademicEvent.fromMap(eventData);
          // If parsing fails later, we fix _parseDate
          events.add(event);
        }
      }
    } catch (e) {
      debugPrint("Error fetching holidays for $semesterCode: $e");
    }

    return events;
  }

  Future<List<Map<String, dynamic>>> fetchExamSchedule(
      String semesterCode) async {
    // Corrected: `exams_Spring2026` (plural 'exams', CamelCase semester)
    final collectionName = 'exams_$semesterCode';
    final List<Map<String, dynamic>> exams = [];

    try {
      final snapshot = await _firestore.collection(collectionName).get();
      for (var doc in snapshot.docs) {
        exams.add(doc.data());
      }
    } catch (e) {
      debugPrint("Error fetching exams: $e");
    }
    return exams;
  }

  /// Fetches pre-generated personalized schedule from Cloud
  Future<Map<String, dynamic>?> fetchPersonalizedSchedule(
      String userId, String semesterCode) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedule')
          .doc(semesterCode)
          .get();

      if (!doc.exists) return null;
      return doc.data();
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
