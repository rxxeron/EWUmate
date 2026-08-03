import 'package:intl/intl.dart';

import '../../core/utils/time_utils.dart';
import '../../core/utils/course_utils.dart';


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

  final String id;
  final bool isCancelled;
  final bool isMakeup;
  final bool isManual;
  final String? statusLabel;
 
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
     this.isManual = false,
     this.statusLabel,
   });
 
   ScheduleItem copyWith({String? id, bool? isCancelled, bool? isMakeup, bool? isManual, String? statusLabel}) {
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
       isManual: isManual ?? this.isManual,
       statusLabel: statusLabel ?? this.statusLabel,
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
    if (now.hour >= 20) {
      targetDate = now.add(const Duration(days: 1));
    }
 
    return getScheduleForDate(cloudSchedule, targetDate, startDate: startDate, lastClassDates: lastClassDates);
  }

  /// Generates schedule for a specific date using cloud data
  static Map<String, dynamic> getScheduleForDate(
      Map<String, dynamic>? cloudSchedule, DateTime targetDate, {DateTime? startDate, Map<String, dynamic>? lastClassDates}) {
    final displayDate = DateFormat('EEE, MMM d').format(targetDate);

    if (cloudSchedule == null) {
      return _buildChillState('No schedule data available. Add courses to get started.', displayDate, targetDate);
    }

    if (startDate != null && targetDate.isBefore(startDate)) {
      final msg = 'Enjoy your break! Classes begin on ${DateFormat('MMMM d').format(startDate)}.';
      return _buildChillState(msg, displayDate, targetDate);
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
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

      final startTime = (cls['startTime'] ?? cls['start_time'])?.toString() ?? '';
      final endTime = (cls['endTime'] ?? cls['end_time'])?.toString() ?? '';
        final isLab = CourseUtils.isLab(startTime, endTime, code);
          final backendType = cls['type']?.toString();

        list.add(ScheduleItem(
          id: "base_${code}_${dayName}_$startTime".replaceAll(' ', ''),
          courseCode: code,
          courseName: (cls['courseName'] ?? cls['course_name'])?.toString() ?? '',
          sessionType: backendType ?? (isLab ? 'Lab' : 'Theory'),
        day: dayName,
        startTime: startTime,
        endTime: endTime,
        room: (cls['room'] ?? cls['room_number'])?.toString() ?? 'TBA',
        faculty: cls['faculty']?.toString() ?? '',
      ));
    }
    return list;
  }

  static Map<String, dynamic> processDashboardData(Map<String, dynamic> data, {DateTime? classesEndDate, bool filterPast = true}) {
    final dateRaw = data['date'];
    final DateTime? targetDate = dateRaw is String 
        ? DateTime.tryParse(dateRaw) 
        : dateRaw as DateTime?;
    if (targetDate == null) {
       return _buildChillState('Loading your schedule...', 'Today', DateTime.now());
    }
    final displayDate = _formatDisplayDate(targetDate);

    // 0. Global Cutoff logic is now handled in the Repository per-course
    // to allow hybrid classes (some tracks over, others active).
    
    final List<ScheduleItem> schedule = [];
    final List<Map<String, dynamic>> template = List<Map<String, dynamic>>.from(data['template'] ?? []);
    final List<Map<String, dynamic>> exceptions = List<Map<String, dynamic>>.from(data['exceptions'] ?? []);
    final String status = data['status'] ?? 'normal';
    final String reason = data['reason'] ?? '';
    final String dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
    final String dayName = DateFormat('EEEE').format(targetDate);

    // 1. Process Makeup & Manual Classes (Highest Priority - even on holidays)
    for (var ex in exceptions) {
      final String type = ex['type']?.toString() ?? '';
      if (ex['date'] == dateStr && (type == 'makeup' || type == 'manual')) {
        final startTime = (ex['start_time'] ?? ex['startTime'] ?? 'TBA').toString();
        final endTime = (ex['end_time'] ?? ex['endTime'] ?? 'TBA').toString();
          final String overrideCode = (ex['course_code'] ?? ex['courseCode'] ?? 'Extra').toString();
          final isLabFallback = CourseUtils.isLab(startTime, endTime, overrideCode);
          final backendType = ex['session_type']?.toString() ?? ex['sessionType']?.toString();
          final isManual = type == 'manual';

          schedule.add(ScheduleItem(
            id: ex['id']?.toString() ?? "${type}_${overrideCode}_$dateStr",
            courseCode: overrideCode,
          courseName: (ex['course_name'] ?? ex['courseName'] ?? (type == 'makeup' ? 'Makeup Class' : 'Manual Entry')).toString(),
          sessionType: type == 'makeup' ? 'Makeup' : (backendType ?? (isLabFallback ? 'Lab' : 'Theory')),
          day: dayName,
          startTime: startTime,
          endTime: endTime,
          room: (ex['room'] ?? 'TBA').toString(),
          faculty: (ex['faculty'] ?? '').toString(),
          isMakeup: type == 'makeup',
          isManual: isManual,
          statusLabel: isManual ? 'MANUAL' : (type == 'makeup' ? 'MAKEUP' : 'EXTRA'),
        ));
      }
    }

    // 2. Process Template Classes (Only if NOT a holiday)
    if (status != 'holiday') {
      for (var cls in template) {
        final code = cls['courseCode']?.toString() ?? '';
        
        // Check for 'cancel' exception
        final cancelEx = exceptions.where((ex) => 
          ex['date'] == dateStr &&
          _compareCode(ex['course_code'] ?? ex['courseCode'], code) && 
          ex['type'] == 'cancel'
        ).firstOrNull;

        if (cancelEx != null) {
          schedule.add(ScheduleItem(
            id: cancelEx['id']?.toString() ?? "template_${code}_${cls['startTime']}".replaceAll(' ', ''),
            courseCode: code,
            courseName: cls['courseName']?.toString() ?? '',
            sessionType: cls['type']?.toString() ?? 'Theory',
            day: dayName,
            startTime: cls['startTime']?.toString() ?? 'TBA',
            endTime: cls['endTime']?.toString() ?? 'TBA',
            room: cls['room']?.toString() ?? 'TBA',
            faculty: cls['faculty']?.toString() ?? '',
            isCancelled: true,
            statusLabel: 'CANCELLED',
          ));
        } else {
          final startTime = (cls['startTime'] ?? cls['start_time'])?.toString() ?? 'TBA';
          final endTime = (cls['endTime'] ?? cls['end_time'])?.toString() ?? 'TBA';
          final isLabFallback = CourseUtils.isLab(startTime, endTime, code);
          final backendType = cls['type']?.toString();

          schedule.add(ScheduleItem(
            id: "template_${code}_$startTime".replaceAll(' ', ''),
            courseCode: code,
            courseName: (cls['courseName'] ?? cls['course_name'])?.toString() ?? '',
            sessionType: backendType ?? (isLabFallback ? 'Lab' : 'Theory'),
            day: dayName,
            startTime: startTime,
            endTime: endTime,
            room: (cls['room'] ?? cls['room_number'])?.toString() ?? 'TBA',
            faculty: cls['faculty']?.toString() ?? '',
          ));
        }
      }
    }

    _sortByTime(schedule);
    final filteredSchedule = filterPast ? _filterPastClasses(schedule, targetDate) : schedule;

    return {
      'status': status,
      'reason': reason, // Show the proper reason instead of hardcoded info
      'schedule': filteredSchedule,
      'displayDate': displayDate,
      'targetDate': targetDate
    };
  }

  static String _formatDisplayDate(DateTime date) {
    return DateFormat('EEEE, MMM d').format(date);
  }

  static List<ScheduleItem> _applyExceptions(Map<String, dynamic> cloudSchedule, List<ScheduleItem> daySchedule, String dateStr, DateTime targetDate) {
    // This is a helper for legacy getScheduleForDate
    final exceptions = (cloudSchedule['exceptions'] ?? []) as List<dynamic>;
    List<ScheduleItem> result = List.from(daySchedule);

    for (var ex in exceptions) {
      if (ex['date'] != dateStr) continue;

      if (ex['type'] == 'cancel') {
        result = result.map((item) {
          if (_compareCode(ex['course_code'] ?? ex['courseCode'], item.courseCode)) {
            return item.copyWith(isCancelled: true);
          }
          return item;
        }).toList();
      } else if (ex['type'] == 'makeup') {
        result.add(ScheduleItem(
          id: ex['id']?.toString() ?? "makeup_${ex['course_code']}_$dateStr",
          courseCode: (ex['course_code'] ?? ex['courseCode'] ?? 'Extra').toString(),
          courseName: (ex['course_name'] ?? ex['courseName'] ?? 'Makeup Class').toString(),
          sessionType: 'Makeup',
          day: DateFormat('EEEE').format(targetDate),
          startTime: (ex['start_time'] ?? ex['startTime'] ?? 'TBA').toString(),
          endTime: (ex['end_time'] ?? ex['endTime'] ?? 'TBA').toString(),
          room: (ex['room'] ?? 'TBA').toString(),
          faculty: (ex['faculty'] ?? '').toString(),
          isMakeup: true,
          statusLabel: 'MAKEUP',
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
    if (gradeStartStr != null) gradeStart = gradeStartStr is DateTime ? gradeStartStr : DateTime.tryParse(gradeStartStr.toString());

    if (startDate != null && targetDate.difference(startDate).inDays < 7) {
      return "Classes have officially started, but you have no sessions scheduled for today! Enjoy the calm before the storm.";
    } 
    if (gradeStart != null && targetDate.isAfter(gradeStart.subtract(const Duration(days: 7)))) {
      return "No classes scheduled. Is the semester wrapping up? Good luck with your final results and preparations!";
    }
    return "No classes scheduled for today. Time to relax or catch up on tasks!";
  }

  /// Legacy method - uses Map<String, dynamic> objects (kept for backward compatibility)
  static Map<String, dynamic> getScheduleForDisplay(
      List<Map<String, dynamic>> courses, List<dynamic> holidays) {
    final now = DateTime.now();
    DateTime targetDate = now;
    String status = 'normal';
    String reason = '';

    // 1. "8 PM Rule": If after 8 PM (20:00), show tomorrow
    if (now.hour >= 20) {
      targetDate = now.add(const Duration(days: 1));
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
    final displayDate =
        DateFormat('EEE, MMM d').format(targetDate);

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
      final sessionsForDay = course['sessions'].where((s) => s.day == dayLetter);

      for (var session in sessionsForDay) {
        daySchedule.add(ScheduleItem(
          id: "legacy_${course['code']}_${session.day}_${session.startTime}",
          courseCode: course['code'],
          courseName: course['courseName'],
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
