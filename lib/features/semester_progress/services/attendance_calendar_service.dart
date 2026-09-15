import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/course_utils.dart';
import '../widgets/attendance_sessions_tab.dart';

class AttendanceCalendarResult {
  final List<AttendanceSession> sessions;
  final Map<String, String> markedDates;
  final Map<String, String> dateTypes;
  final bool typesChanged;

  AttendanceCalendarResult({
    required this.sessions,
    required this.markedDates,
    required this.dateTypes,
    required this.typesChanged,
  });
}

class AttendanceCalendarService {
  /// Generates the semester class session timeline by cross-referencing:
  /// 1. Semester start & end dates from active_semester
  /// 2. User's routine grid cache (class weekdays and session types)
  /// 3. University calendar holidays
  /// 4. User's cancellations and makeup sessions
  static Future<AttendanceCalendarResult> generateSessions({
    required String courseCode,
    required String semesterCode,
    required String? userTrack,
    required Map<String, dynamic> existingMarksData,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final resolvedTrack = userTrack == 'bi' ? 'bi_semester' : 'tri_semester';

    // 1. Fetch active semester start/end dates
    final activeSemRes = await Supabase.instance.client
        .from('active_semester')
        .select('classes_start_date, classes_end_date')
        .eq('track', resolvedTrack)
        .maybeSingle();

    DateTime? startDate = DateTime.tryParse(activeSemRes?['classes_start_date']?.toString() ?? '');
    DateTime? endDate = DateTime.tryParse(activeSemRes?['classes_end_date']?.toString() ?? '');
    startDate ??= DateTime.now().subtract(const Duration(days: 45));
    endDate ??= DateTime.now().add(const Duration(days: 45));

    // 2. Fetch weekly grid template to identify class weekdays
    final stateData = await Supabase.instance.client
        .from('user_semester_states')
        .select('weekly_grid_cache')
        .eq('user_id', user.id)
        .eq('semester_code', semesterCode)
        .maybeSingle();
    final grid = stateData?['weekly_grid_cache'] as Map<String, dynamic>? ?? {};

    final String currentCourseCodeNormalized = courseCode.toUpperCase().replaceAll(' ', '');

    final List<Map<String, String>> scheduledTemplates = [];
    final Map<String, int> weekdayMap = {
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
      'Sunday': DateTime.sunday,
    };

    for (final entry in grid.entries) {
      final day = entry.key;
      final dayClasses = entry.value;
      if (dayClasses is List) {
        for (final c in dayClasses) {
          final code = (c['courseCode'] ?? c['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
          if (code == currentCourseCodeNormalized) {
            final startTime = (c['startTime'] ?? c['start_time'] ?? '').toString();
            final endTime = (c['endTime'] ?? c['end_time'] ?? '').toString();
            final isLab = CourseUtils.isLab(startTime, endTime, code);
            final type = c['type']?.toString() ?? (isLab ? 'Lab' : 'Theory');
            scheduledTemplates.add({
              'day': day,
              'type': type,
            });
          }
        }
      }
    }

    // 3. Fetch academic calendar holidays
    final tableName = CourseUtils.semesterTable(
      'calendar',
      semesterCode,
      cycleType: resolvedTrack,
    );

    final Set<String> holidayDates = {};
    try {
      final calendarRes = await Supabase.instance.client.from(tableName).select();
      for (final ev in calendarRes) {
        final dateStr = (ev['event_date'] ?? ev['date'] ?? '').toString();
        final title = (ev['title'] ?? ev['name'] ?? '').toString().toLowerCase();
        final isHoliday = ev['is_holiday'] == true ||
            ev['type']?.toString().toLowerCase() == 'holiday' ||
            title.contains('holiday') ||
            title.contains('vacation') ||
            title.contains('break') ||
            title.contains('leave') ||
            title.contains('off day') ||
            title.contains('no classes');
        if (isHoliday && dateStr.isNotEmpty) {
          holidayDates.add(dateStr);
        }
      }
    } catch (e) {
      debugPrint('[Attendance] Calendar fetch failed or table does not exist: $e');
    }

    // 4. Fetch cancellations and makeups from schedule exceptions
    final Set<String> cancelledDates = {};
    final List<Map<String, dynamic>> courseMakeups = [];
    try {
      final exceptionsRes = await Supabase.instance.client
          .from('schedule_exceptions')
          .select()
          .eq('user_id', user.id)
          .eq('course_code', currentCourseCodeNormalized);
      for (final ex in exceptionsRes) {
        final dateStr = ex['date']?.toString();
        final type = ex['type']?.toString();
        if (dateStr != null && dateStr.isNotEmpty) {
          if (type == 'cancel') {
            cancelledDates.add(dateStr);
          } else if (type == 'makeup' || type == 'manual') {
            courseMakeups.add(ex);
          }
        }
      }
    } catch (e) {
      debugPrint('[Attendance] Exceptions fetch failed: $e');
    }

    // 5. Generate matching weekdays up to today's date
    final List<AttendanceSession> generatedSessions = [];
    final List<int> weekdaysInt = scheduledTemplates.map((t) => weekdayMap[t['day']!]!).toSet().toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime endLimit = endDate.isAfter(today) ? today : endDate;

    for (DateTime d = startDate; d.isBefore(endLimit) || d.isAtSameMomentAs(endLimit); d = d.add(const Duration(days: 1))) {
      if (weekdaysInt.contains(d.weekday)) {
        final dayName = DateFormat('EEEE').format(d);
        final dayTemplates = scheduledTemplates.where((t) => t['day'] == dayName).toList();
        for (final temp in dayTemplates) {
          generatedSessions.add(AttendanceSession(
            DateTime(d.year, d.month, d.day),
            temp['type'] ?? 'Theory',
          ));
        }
      }
    }

    // Load saved dates and types from DB
    final attendance = Map<String, dynamic>.from(existingMarksData['attendance'] ?? {});
    final datesRaw = Map<String, dynamic>.from(attendance['dates'] ?? {});
    final typesRaw = Map<String, dynamic>.from(attendance['types'] ?? {});
    final markedDates = Map<String, String>.from(datesRaw);
    final dateTypes = Map<String, String>.from(typesRaw);

    // Populate scheduled day types first
    for (final session in generatedSessions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
      final key = '${dateStr}_${session.type}';
      if (!dateTypes.containsKey(key)) {
        dateTypes[key] = session.type;
      }
      if (!dateTypes.containsKey(dateStr)) {
        dateTypes[dateStr] = session.type; // legacy fallback
      }
    }

    // Add makeup classes/manual entries that have occurred up to endLimit
    for (final makeup in courseMakeups) {
      final dateStr = makeup['date']?.toString() ?? '';
      final mDate = DateTime.tryParse(dateStr);
      if (mDate != null && (mDate.isBefore(endLimit) || mDate.isAtSameMomentAs(endLimit))) {
        final normalizedDate = DateTime(mDate.year, mDate.month, mDate.day);
        final sessionType = makeup['session_type']?.toString() ?? makeup['sessionType']?.toString() ?? 'Theory';

        final exists = generatedSessions.any((s) => s.date == normalizedDate && s.type == sessionType);
        if (!exists) {
          generatedSessions.add(AttendanceSession(normalizedDate, sessionType));
        }
        final key = '${dateStr}_$sessionType';
        dateTypes[key] = sessionType;
        dateTypes[dateStr] = sessionType; // legacy fallback
      }
    }

    // Sort generated list in reverse order (newest first)
    generatedSessions.sort((a, b) {
      final cmp = b.date.compareTo(a.date);
      if (cmp != 0) return cmp;
      return a.type.compareTo(b.type);
    });

    // Auto-mark holidays and cancellations if not already set by user
    for (final session in generatedSessions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
      final key = '${dateStr}_${session.type}';
      if (!markedDates.containsKey(key) && !markedDates.containsKey(dateStr)) {
        if (holidayDates.contains(dateStr)) {
          markedDates[key] = 'holiday';
        } else if (cancelledDates.contains(dateStr)) {
          markedDates[key] = 'cancelled';
        }
      }
    }

    // Check if type mappings changed
    bool typesChanged = false;
    for (final entry in dateTypes.entries) {
      if (typesRaw[entry.key]?.toString() != entry.value) {
        typesChanged = true;
        break;
      }
    }

    return AttendanceCalendarResult(
      sessions: generatedSessions,
      markedDates: markedDates,
      dateTypes: dateTypes,
      typesChanged: typesChanged,
    );
  }
}
