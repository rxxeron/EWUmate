import 'package:intl/intl.dart';
import '../../core/models/course_model.dart';
import '../../core/utils/time_utils.dart';
import '../../core/constants/app_constants.dart';

/// Represents a single schedule item for display on the dashboard
class ScheduleItem {
  final String courseCode;
  final String courseName;
  final String sessionType; // "Theory" or "Lab"
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final String faculty;

  final String id; // Unique ID (e.g. exception doc ID)
  final bool isCancelled;
  final bool isMakeup;

  ScheduleItem({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.sessionType,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.faculty,
    this.isCancelled = false,
    this.isMakeup = false,
  });

  ScheduleItem copyWith({String? id, bool? isCancelled, bool? isMakeup}) {
    return ScheduleItem(
      id: id ?? this.id,
      courseCode: courseCode,
      courseName: courseName,
      sessionType: sessionType,
      day: day,
      startTime: startTime,
      endTime: endTime,
      room: room,
      faculty: faculty,
      isCancelled: isCancelled ?? this.isCancelled,
      isMakeup: isMakeup ?? this.isMakeup,
    );
  }
}

class DashboardLogic {
  // Returns:
  // {
  //   'status': 'normal' | 'holiday' | 'chill',
  //   'reason': 'Holiday Name' or 'Quote',
  //   'schedule': [ScheduleItem, ScheduleItem, ...],
  //   'displayDate': 'Friday, Jan 17',
  //   'targetDate': DateTime object
  // }

  /// Uses Cloud-generated schedule data (preferred)
  static Map<String, dynamic> getScheduleFromCloud(
      Map<String, dynamic>? cloudSchedule) {
    final now = DateTime.now();
    DateTime targetDate = now;

    // 1. "8 PM Rule": If after 8 PM (20:00), show tomorrow
    if (now.hour >= AppConstants.eveningHourThreshold) {
      targetDate = now.add(const Duration(days: 1));
    }

    return getScheduleForDate(cloudSchedule, targetDate);
  }

  /// Generates schedule for a specific date using cloud data
  static Map<String, dynamic> getScheduleForDate(
      Map<String, dynamic>? cloudSchedule, DateTime targetDate) {
    final now = DateTime.now();
    String status = 'normal';
    String reason = '';

    final dateStr = DateFormat(AppConstants.dateFormat).format(targetDate);
    final displayDate =
        DateFormat(AppConstants.displayDateFormat).format(targetDate);

    if (cloudSchedule == null) {
      return {
        'status': 'chill',
        'reason': 'No schedule data available. Add courses to get started.',
        'schedule': <ScheduleItem>[],
        'displayDate': displayDate,
        'targetDate': targetDate
      };
    }

    // 2. Check for Holidays
    final holidays = cloudSchedule['holidays'] as List<dynamic>? ?? [];
    for (var h in holidays) {
      if (h['date'] == dateStr) {
        return {
          'status': 'holiday',
          'reason': h['name']?.toString() ?? 'Holiday',
          'schedule': <ScheduleItem>[],
          'displayDate': displayDate,
          'targetDate': targetDate
        };
      }
    }

    // 3. Check for Day Swaps
    final daySwaps = cloudSchedule['daySwaps'] as List<dynamic>? ?? [];
    String targetDayName =
        DateFormat('EEEE').format(targetDate); // e.g., "Monday"
    for (var swap in daySwaps) {
      if (swap['date'] == dateStr) {
        targetDayName = swap['actsAs']?.toString() ?? targetDayName;
        break;
      }
    }

    // 4. Get classes from weekly template for target day
    final weeklyTemplate =
        cloudSchedule['weeklyTemplate'] as Map<String, dynamic>? ?? {};
    final dayClasses = weeklyTemplate[targetDayName] as List<dynamic>? ?? [];

    List<ScheduleItem> daySchedule = [];
    for (var cls in dayClasses) {
      final code = cls['courseCode']?.toString() ?? '';
      final startTime = cls['startTime']?.toString() ?? '';
      daySchedule.add(ScheduleItem(
        id: "base_${code}_${targetDayName}_$startTime".replaceAll(' ', ''),
        courseCode: code,
        courseName: cls['courseName']?.toString() ?? '',
        sessionType: cls['type']?.toString() ?? 'Class',
        day: targetDayName,
        startTime: startTime,
        endTime: cls['endTime']?.toString() ?? '',
        room: cls['room']?.toString() ?? 'TBA',
        faculty: cls['faculty']?.toString() ?? '',
      ));
    }

    // 4.5 Check for Exceptions (Cancellations / Makeup)
    final exceptions = cloudSchedule['exceptions'] as List<dynamic>? ?? [];
    List<ScheduleItem> finalSchedule = [];

    for (var item in daySchedule) {
      bool isCancelled = false;
      final matchingException = exceptions.firstWhere(
        (ex) =>
            ex['date'] == dateStr &&
            (ex['courseCode'] ?? '')
                    .toString()
                    .replaceAll(' ', '')
                    .toUpperCase() ==
                item.courseCode.replaceAll(' ', '').toUpperCase(),
        orElse: () => null,
      );

      if (matchingException != null && matchingException['type'] == 'cancel') {
        isCancelled = true;
      }

      finalSchedule.add(item.copyWith(isCancelled: isCancelled));
    }
    daySchedule = finalSchedule;

    // Add makeup classes separately
    for (var ex in exceptions) {
      if (ex['date'] == dateStr && ex['type'] == 'makeup') {
        daySchedule.add(ScheduleItem(
          id: ex['id']?.toString() ?? "makeup_${ex['courseCode']}_$dateStr",
          courseCode: ex['courseCode'] ?? 'Extra',
          courseName: ex['courseName'] ?? 'Makeup Class',
          sessionType: 'Makeup',
          day: targetDayName,
          startTime: ex['startTime'] ?? '',
          endTime: ex['endTime'] ?? '',
          room: ex['room'] ?? 'TBA',
          faculty: ex['faculty'] ?? '',
          isMakeup: true,
        ));
      }
    }

    // After adding makeup, for cancellations we need the exception ID to allow "Undo"
    final finalSems = daySchedule.map((item) {
      if (item.isMakeup) return item;
      final matchingCancel = exceptions.firstWhere(
        (ex) =>
            ex['date'] == dateStr &&
            ex['type'] == 'cancel' &&
            (ex['courseCode'] ?? '')
                    .toString()
                    .replaceAll(' ', '')
                    .toUpperCase() ==
                item.courseCode.replaceAll(' ', '').toUpperCase(),
        orElse: () => null,
      );
      if (matchingCancel != null) {
        return item.copyWith(
          id: matchingCancel['id']?.toString() ?? item.id,
          isCancelled: true,
        );
      }
      return item;
    }).toList();
    daySchedule = finalSems;

    // 5. Sort by start time
    daySchedule.sort((a, b) {
      return TimeUtils.parseTime(a.startTime)
          .compareTo(TimeUtils.parseTime(b.startTime));
    });

    // 6. Hide Past Classes logic
    // Only applied if targetDate is TODAY and it is not a manual check for future
    bool kShowingToday = (targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day);

    if (kShowingToday) {
      final currentTimeVal = now.hour * 60 + now.minute;
      daySchedule = daySchedule.where((s) {
        final endVal = TimeUtils.parseTime(s.endTime);
        return endVal > currentTimeVal;
      }).toList();
    }

    // 7. Check "Chill Mode" (No classes today)
    if (daySchedule.isEmpty) {
      status = 'chill';
      reason = "No classes scheduled for this day.";
    }

    return {
      'status': status,
      'reason': reason,
      'schedule': daySchedule,
      'displayDate': displayDate,
      'targetDate': targetDate
    };
  }

  /// Legacy method - uses Course objects (kept for backward compatibility)
  static Map<String, dynamic> getScheduleForDisplay(
      List<Course> courses, List<dynamic> holidays) {
    final now = DateTime.now();
    DateTime targetDate = now;
    String status = 'normal';
    String reason = '';

    // 1. "8 PM Rule": If after 8 PM (20:00), show tomorrow
    if (now.hour >= AppConstants.eveningHourThreshold) {
      targetDate = now.add(const Duration(days: 1));
    }

    final dateStr = DateFormat(AppConstants.dateFormat).format(targetDate);
    final displayDate =
        DateFormat(AppConstants.displayDateFormat).format(targetDate);

    // 2. Check for Holidays
    final holiday = holidays.firstWhere(
      (h) => h['date'] == dateStr,
      orElse: () => null,
    );

    if (holiday != null) {
      return {
        'status': 'holiday',
        'reason': holiday['name'],
        'schedule': <ScheduleItem>[],
        'displayDate': displayDate,
        'targetDate': targetDate
      };
    }

    // 3. Get day letter for target date
    final dayOfWeek = targetDate.weekday; // 1=Mon, 2=Tue, ..., 7=Sun
    final dayLetter = TimeUtils.getDayLetter(dayOfWeek);

    // 4. Extract sessions for this day from all enrolled courses
    List<ScheduleItem> daySchedule = [];

    for (var course in courses) {
      final sessionsForDay = course.sessions.where((s) => s.day == dayLetter);

      for (var session in sessionsForDay) {
        daySchedule.add(ScheduleItem(
          id: "legacy_${course.code}_${session.day}_${session.startTime}",
          courseCode: course.code,
          courseName: course.courseName,
          sessionType: session.type,
          day: session.day,
          startTime: session.startTime,
          endTime: session.endTime,
          room: session.room,
          faculty: session.faculty,
        ));
      }
    }

    // 5. Sort by start time
    daySchedule.sort((a, b) {
      return TimeUtils.parseTime(a.startTime)
          .compareTo(TimeUtils.parseTime(b.startTime));
    });

    // 6. Hide Past Classes logic
    bool kShowingToday =
        (targetDate.difference(now).inDays == 0 && targetDate.day == now.day);

    if (kShowingToday) {
      final currentTimeVal = now.hour * 60 + now.minute;
      daySchedule = daySchedule.where((s) {
        final endVal = TimeUtils.parseTime(s.endTime);
        return endVal > currentTimeVal;
      }).toList();
    }

    // 7. Check "Chill Mode" (No classes today)
    if (daySchedule.isEmpty) {
      status = 'chill';
      reason =
          "Prepare yourself in this free time with a chill mind. Rest and prepare for the future.";
    }

    return {
      'status': status,
      'reason': reason,
      'schedule': daySchedule,
      'displayDate': displayDate,
      'targetDate': targetDate
    };
  }
}
