import 'package:flutter/foundation.dart';
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
      Map<String, dynamic>? cloudSchedule, {DateTime? startDate, Map<String, DateTime>? lastClassDates}) {
    final now = DateTime.now();
    DateTime targetDate = now;
 
    // 1. "8 PM Rule": If after 8 PM (20:00), show tomorrow
    if (now.hour >= AppConstants.eveningHourThreshold) {
      targetDate = now.add(const Duration(days: 1));
    }
 
    return getScheduleForDate(cloudSchedule, targetDate, startDate: startDate, lastClassDates: lastClassDates);
  }

  /// Generates schedule for a specific date using cloud data
  static Map<String, dynamic> getScheduleForDate(
      Map<String, dynamic>? cloudSchedule, DateTime targetDate, {DateTime? startDate, Map<String, dynamic>? lastClassDates}) {
    final displayDate = DateFormat(AppConstants.displayDateFormat).format(targetDate);

    if (cloudSchedule == null) {
      return _buildChillState('No schedule data available. Add courses to get started.', displayDate, targetDate);
    }

    if (startDate != null && targetDate.isBefore(startDate)) {
      final msg = 'Enjoy your break! Classes begin on ${DateFormat('MMMM d').format(startDate)}.';
      return _buildChillState(msg, displayDate, targetDate);
    }

    final dateStr = DateFormat(AppConstants.dateFormat).format(targetDate);
    final holiday = _checkHoliday(cloudSchedule, dateStr);
    if (holiday != null) {
      return {
        'status': 'holiday',
        'reason': holiday,
        'schedule': <ScheduleItem>[],
        'displayDate': displayDate,
        'targetDate': targetDate
      };
    }

    final targetDayName = _resolveDayName(cloudSchedule, targetDate, dateStr);
    List<ScheduleItem> daySchedule = _getClassesFromTemplate(cloudSchedule, targetDayName, targetDate, lastClassDates);
    daySchedule = _applyExceptions(cloudSchedule, daySchedule, dateStr, targetDate);

    _sortByTime(daySchedule);
    final filteredSchedule = _filterPastClasses(daySchedule, targetDate);

    if (filteredSchedule.isEmpty) {
      final reason = _getChillReason(cloudSchedule, startDate, targetDate);
      return _buildChillState(reason, displayDate, targetDate);
    }

    return {
      'status': 'normal',
      'reason': '',
      'schedule': filteredSchedule,
      'displayDate': displayDate,
      'targetDate': targetDate
    };
  }

  static Map<String, dynamic> _buildChillState(String reason, String displayDate, DateTime targetDate) {
    return {
      'status': 'chill',
      'reason': reason,
      'schedule': <ScheduleItem>[],
      'displayDate': displayDate,
      'targetDate': targetDate
    };
  }

  static String? _checkHoliday(Map<String, dynamic> cloudSchedule, String dateStr) {
    final holidays = cloudSchedule['holidays'] as List<dynamic>? ?? [];
    for (var h in holidays) {
      if (h['date'] == dateStr) return h['name']?.toString() ?? 'Holiday';
    }
    return null;
  }

  static String _resolveDayName(Map<String, dynamic> cloudSchedule, DateTime targetDate, String dateStr) {
    final daySwaps = (cloudSchedule['day_swaps'] ?? cloudSchedule['daySwaps']) as List<dynamic>? ?? [];
    String dayName = DateFormat('EEEE').format(targetDate);
    for (var swap in daySwaps) {
      if (swap['date'] == dateStr) return swap['actsAs']?.toString() ?? dayName;
    }
    return dayName;
  }

  static List<ScheduleItem> _getClassesFromTemplate(
      Map<String, dynamic> cloudSchedule, String dayName, DateTime targetDate, Map<String, dynamic>? lastClassDates) {
    final weeklyTemplateRaw = cloudSchedule['weekly_template'] ?? cloudSchedule['weeklyTemplate'];
    final weeklyTemplate = weeklyTemplateRaw is Map ? Map<String, dynamic>.from(weeklyTemplateRaw) : {};
    final dayClasses = weeklyTemplate[dayName] as List<dynamic>? ?? [];

    final List<ScheduleItem> list = [];
    for (var cls in dayClasses) {
      final code = cls['courseCode']?.toString() ?? '';
      if (lastClassDates != null && lastClassDates.containsKey(code)) {
        final lastDate = lastClassDates[code];
        if (lastDate is DateTime && targetDate.isAfter(lastDate)) continue;
      }

      final startTime = cls['startTime']?.toString() ?? '';
      list.add(ScheduleItem(
        id: "base_${code}_${dayName}_$startTime".replaceAll(' ', ''),
        courseCode: code,
        courseName: cls['courseName']?.toString() ?? '',
        sessionType: cls['type']?.toString() ?? 'Class',
        day: dayName,
        startTime: startTime,
        endTime: cls['endTime']?.toString() ?? '',
        room: cls['room']?.toString() ?? 'TBA',
        faculty: cls['faculty']?.toString() ?? '',
      ));
    }
    return list;
  }

  static List<ScheduleItem> _applyExceptions(Map<String, dynamic> cloudSchedule, List<ScheduleItem> daySchedule, String dateStr, DateTime targetDate) {
    final exceptions = cloudSchedule['exceptions'] as List<dynamic>? ?? [];
    final List<ScheduleItem> result = [];

    // 1. Process base classes and cancellations
    for (var item in daySchedule) {
      final matchingCancel = exceptions.where((ex) =>
          ex['date'] == dateStr &&
          ex['type'] == 'cancel' &&
          _compareCode(ex['course_code'] ?? ex['courseCode'], item.courseCode)).firstOrNull;

      if (matchingCancel != null) {
        result.add(item.copyWith(id: matchingCancel['id']?.toString() ?? item.id, isCancelled: true));
      } else {
        result.add(item);
      }
    }

    // 2. Add makeup classes
    for (var ex in exceptions) {
      if (ex['date'] == dateStr && ex['type'] == 'makeup') {
        final courseCode = (ex['course_code'] ?? ex['courseCode'] ?? 'Extra').toString();
        result.add(ScheduleItem(
          id: ex['id']?.toString() ?? "makeup_${courseCode}_$dateStr",
          courseCode: courseCode,
          courseName: (ex['course_name'] ?? ex['courseName'] ?? 'Makeup Class').toString(),
          sessionType: 'Makeup',
          day: DateFormat('EEEE').format(targetDate),
          startTime: (ex['start_time'] ?? ex['startTime'] ?? '').toString(),
          endTime: (ex['end_time'] ?? ex['endTime'] ?? '').toString(),
          room: (ex['room'] ?? 'TBA').toString(),
          faculty: (ex['faculty'] ?? '').toString(),
          isMakeup: true,
        ));
      }
    }
    return result;
  }

  static bool _compareCode(dynamic code1, String code2) {
    final c1 = code1?.toString().replaceAll(' ', '').toUpperCase() ?? '';
    final c2 = code2.replaceAll(' ', '').toUpperCase();
    return c1 == c2;
  }

  static void _sortByTime(List<ScheduleItem> list) {
    list.sort((a, b) => TimeUtils.parseTime(a.startTime).compareTo(TimeUtils.parseTime(b.startTime)));
  }

  static List<ScheduleItem> _filterPastClasses(List<ScheduleItem> list, DateTime targetDate) {
    final now = DateTime.now();
    final bool isToday = targetDate.year == now.year && targetDate.month == now.month && targetDate.day == now.day;
    if (!isToday) return list;

    final currentTimeVal = now.hour * 60 + now.minute;
    return list.where((s) => TimeUtils.parseTime(s.endTime) > currentTimeVal).toList();
  }

  static String _getChillReason(Map<String, dynamic> cloudSchedule, DateTime? startDate, DateTime targetDate) {
    final configRaw = cloudSchedule['config'];
    final config = configRaw is Map ? Map<String, dynamic>.from(configRaw) : {};
    final gradeStartStr = config['grade_submission_start'];
    DateTime? gradeStart;
    if (gradeStartStr != null) gradeStart = DateTime.parse(gradeStartStr);

    if (startDate != null && targetDate.difference(startDate).inDays < 7) {
      return "Classes have officially started, but you have no sessions scheduled for today! Enjoy the calm before the storm.";
    } 
    if (gradeStart != null && targetDate.isAfter(gradeStart.subtract(const Duration(days: 7)))) {
      return "No classes scheduled. Is the semester wrapping up? Good luck with your final results and preparations!";
    }
    return "No classes scheduled for today. Time to relax or catch up on tasks!";
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
    final holiday = holidays.where(
      (h) => h['date'] == dateStr,
    ).firstOrNull;

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
