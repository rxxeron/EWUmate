import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/task.dart';
import '../../../core/providers/academic_providers.dart';
import '../../../core/repositories/task_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/local_notification_scheduler.dart';
import '../../../core/utils/course_utils.dart';
import '../../../core/utils/time_utils.dart';
import '../../auth/auth_providers.dart';
import '../../semester_progress/semester_progress_repository.dart';
import '../dashboard_logic.dart';
import '../dashboard_repository.dart';
import '../exception_repository.dart';

class DashboardState {
  Map<String, dynamic>? lastValidScheduleData;
  String semesterCode = '';
  bool loadingInit = true;
  bool isSavingAttendance = false;
  List<Map<String, dynamic>> pendingAttendanceItems = [];
  List<Map<String, dynamic>> tasks = [];
  Map<String, dynamic>? semConfig;
  Map<String, dynamic>? updateInfo;
  bool showAdvisingBanner = false;
  bool showUpdateBanner = false;
  bool isPlayStoreUser = false;
  String customApkUrl = '';
  bool showPortalSyncBanner = false;
}

class DashboardController {
  final SupabaseClient supabase = Supabase.instance.client;
  final DashboardState state = DashboardState();
  final VoidCallback onStateChanged;

  DashboardController({required this.onStateChanged});

  User? get user => supabase.auth.currentUser;

  /// Loads Hive cache instantly then queries backend data
  Future<void> refreshDashboard({
    required WidgetRef ref,
    bool isSilent = false,
    DateTime? effectiveDate,
  }) async {
    final currentUser = user;
    if (currentUser == null) return;

    if (!isSilent && state.lastValidScheduleData != null) {
      ref.invalidate(academicStateProvider);
    }

    // PHASE 0: Instant Cache Load from Hive (Frame 0, < 5ms)
    if (state.lastValidScheduleData == null) {
      try {
        final now = DateTime.now();
        final targetDate = effectiveDate ??
            (now.hour >= 20
                ? DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
                : now);
        final targetDateStr = DateFormat('yyyy-MM-dd').format(targetDate);
        final dayName = DateFormat('EEEE').format(targetDate);

        final cacheService = ref.read(cacheServiceProvider);
        final cachedSemState = cacheService.getMapData('dashboard_box', '${currentUser.id}_academicState');
        final semCode = cachedSemState?['current_semester_code'] as String?;

        if (semCode != null && semCode.isNotEmpty) {
          final cleanSem = CourseUtils.cleanSemester(semCode);
          // 1. Try exact date match first
          final exactDateCache = cacheService.getCachedDashboardSchedule(currentUser.id, cleanSem, dateStr: targetDateStr);
          if (exactDateCache != null) {
            state.lastValidScheduleData = exactDateCache;
            state.semesterCode = semCode;
            state.loadingInit = false;
            onStateChanged();
          } else {
            // 2. Synthesize today's schedule from cached weekly_grid in 0ms!
            final generalCache = cacheService.getCachedDashboardSchedule(currentUser.id, cleanSem);
            if (generalCache != null && generalCache['weekly_grid'] is Map) {
              final grid = generalCache['weekly_grid'] as Map;
              final todayClasses = (grid[dayName] as List? ?? []);
              final synthesized = Map<String, dynamic>.from(generalCache);
              synthesized['date'] = targetDate;
              synthesized['dateStr'] = targetDateStr;
              synthesized['template'] = List<Map<String, dynamic>>.from(
                todayClasses.map((c) => c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{}),
              );
              synthesized['status'] = todayClasses.isEmpty ? 'chill' : 'normal';
              state.lastValidScheduleData = synthesized;
              state.semesterCode = semCode;
              state.loadingInit = false;
              onStateChanged();
            }
          }
        }

        // Fallback scan if academicState was never cached for this user
        if (state.lastValidScheduleData == null) {
          final box = Hive.box('dashboard_box');
          for (final key in box.keys) {
            if (key is String && key.startsWith('${currentUser.id}_') && key.endsWith('_schedule')) {
              final data = box.get(key);
              if (data != null) {
                final cached = Map<String, dynamic>.from(jsonDecode(data as String) as Map);
                final parts = key.split('_');
                state.lastValidScheduleData = cached;
                if (parts.length >= 3 && state.semesterCode.isEmpty) {
                  state.semesterCode = parts[1];
                }
                state.loadingInit = false;
                onStateChanged();
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[DashboardController] Fast cache load error: $e');
      }
    }

    try {
      final academicState = await ref.read(academicStateProvider.future);
      if (academicState == null) {
        state.loadingInit = false;
        onStateChanged();
        return;
      }

      final code = academicState.currentSemesterCode;
      final track = academicState.track;
      final nextSemesterCode = academicState.nextSemesterCode;

      final profile = ref.read(profileProvider).value;
      final cachedProfile = ref.read(cacheServiceProvider).getCachedProfile(currentUser.id);
      final profileUpdatedAt = profile?.updatedAt ?? (cachedProfile != null ? cachedProfile['updated_at'] : null);

      final now = DateTime.now();
      final targetDate = effectiveDate ??
          (now.hour >= 20
              ? DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
              : now);

      final scheduleData = await ref.read(dashboardRepositoryProvider).getSimplifiedDashboardData(
        code,
        targetDate,
        track: track,
        profileUpdatedAt: profileUpdatedAt,
      );

      state.lastValidScheduleData = scheduleData;
      state.semesterCode = code;
      state.semConfig = academicState.toJson();
      state.loadingInit = false;

      // Extract tasks from scheduleData
      final rawTasks = (scheduleData['tasks'] ?? scheduleData['upcoming_tasks']) as List? ?? [];
      state.tasks = rawTasks.map((t) {
        if (t is Map<String, dynamic>) return t;
        if (t is Map) return Map<String, dynamic>.from(t);
        if (t is Task) return t.toJson();
        return <String, dynamic>{};
      }).where((m) => m.isNotEmpty).toList();

      // Google Play In-App Update is handled automatically on launch via AppUpdateService
      state.showUpdateBanner = false;

      onStateChanged();

      // Background parallel routines

      loadPendingAttendance(ref: ref);
      checkAdvisingBanner(nextSemesterCode, scheduleData['advising_end']);
      checkPortalSyncGuide();
    } catch (e) {
      debugPrint('[DashboardController] Refresh error: $e');
      state.loadingInit = false;
      onStateChanged();
    }
  }

  /// Calculates unattended past classes and updates pending items
  Future<void> loadPendingAttendance({required WidgetRef ref}) async {
    final currentUser = user;
    if (currentUser == null || state.semesterCode.isEmpty) return;

    try {
      final profile = ref.read(profileProvider).value;
      final bool isBiSemester = CourseUtils.normalizeTrack(profile?.track) == 'bi_semester';
      final cacheService = ref.read(cacheServiceProvider);

      // Fast check: retrieve weeklyGrid and semConfig already in memory / cache
      Map<String, dynamic> grid = {};
      final cachedSchedule = state.lastValidScheduleData;
      if (cachedSchedule != null && cachedSchedule['weekly_grid'] is Map<String, dynamic>) {
        grid = cachedSchedule['weekly_grid'] as Map<String, dynamic>;
      }

      // If weeklyGrid was not preserved in scheduleData, check user_semester_states
      final Future<dynamic> gridFuture = grid.isNotEmpty
          ? Future.value({'weekly_grid_cache': grid})
          : supabase
              .from('user_semester_states')
              .select('weekly_grid_cache')
              .eq('user_id', currentUser.id)
              .eq('semester_code', state.semesterCode)
              .maybeSingle();

      // Read calendar holidays with local CacheService or Redis fallback
      final cleanSem = CourseUtils.cleanSemester(state.semesterCode).toLowerCase();
      final calendarTable = CourseUtils.semesterTable(
        'calendar',
        state.semesterCode,
        cycleType: isBiSemester ? 'bi_semester' : 'tri_semester',
      );

      final Future<dynamic> holidaysFuture = Future<dynamic>(() async {
        // Try Hive cache first
        final cachedHolidays = cacheService.getMapData('dashboard_box', '${cleanSem}_${isBiSemester ? "bi" : "tri"}_holidays');
        if (cachedHolidays != null && cachedHolidays['events'] is List) {
          final cachedAtStr = cachedHolidays['cached_at'] as String?;
          final cachedAt = cachedAtStr != null ? DateTime.tryParse(cachedAtStr) : null;
          if (cachedAt != null && DateTime.now().difference(cachedAt).inHours < 4) {
            return cachedHolidays['events'] as List;
          }
        }
        try {
          final res = await supabase.from(calendarTable).select().order('event_date');
          if (res.isNotEmpty) {
            cacheService.setMapData('dashboard_box', '${cleanSem}_${isBiSemester ? "bi" : "tri"}_holidays', {
              'events': res,
              'cached_at': DateTime.now().toIso8601String(),
            });
          }
          return res;
        } catch (_) {
          return (cachedHolidays?['events'] as List?) ?? <dynamic>[];
        }
      });

      final results = await Future.wait<dynamic>([
        gridFuture,
        holidaysFuture,
        ExceptionRepository().fetchExceptions(),
        ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(currentUser.id, state.semesterCode),
      ]);

      final rawGridRes = results[0];
      if (rawGridRes is Map) {
        final rawCache = rawGridRes['weekly_grid_cache'] ?? rawGridRes['weekly_grid'];
        if (rawCache is Map) {
          grid = Map<String, dynamic>.from(rawCache);
        }
      }
      final holidays = results[1] as List;
      final exceptions = results[2] as List;
      final progressData = results[3] as List<Map<String, dynamic>>;

      // Trigger background sync for local reminders (Checksum & date-aware, 0-cost if unchanged)
      final userProfile = cacheService.getCachedProfile(currentUser.id);
      final reminderSettings = userProfile?['reminder_settings'] as Map<String, dynamic>?;
      final cachedSemState = cacheService.getMapData('dashboard_box', '${currentUser.id}_academicState');
      final classesStartDate = state.semConfig?['classes_start_date'] ?? cachedSemState?['classes_start_date'];
      final classesEndDate = state.semConfig?['classes_end_date'] ?? cachedSemState?['classes_end_date'];

      ref.read(localNotificationSchedulerProvider).syncLocalReminders(
        userId: currentUser.id,
        semesterCode: state.semesterCode,
        calendar: {
          'events': holidays,
          'classes_start_date': classesStartDate,
          'classes_end_date': classesEndDate,
        },
        weeklyGrid: grid,
        exceptions: exceptions,
        userReminderSettings: reminderSettings,
      ).catchError((e) {
        if (kDebugMode) debugPrint('[DashboardController] Local reminder sync error: $e');
        return 0;
      });

      // Resolve classes_start_date & classes_end_date from Riverpod academicState / semConfig
      DateTime? startDate;
      DateTime? endDate;
      final semConfig = state.semConfig;
      if (semConfig != null) {
        startDate = DateTime.tryParse(semConfig['classes_start_date']?.toString() ?? '');
        endDate = DateTime.tryParse(semConfig['classes_end_date']?.toString() ?? '');
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lookbackLimit = today.subtract(const Duration(days: 14));
      if (startDate == null || startDate.isBefore(lookbackLimit)) {
        startDate = lookbackLimit;
      }
      endDate ??= today.add(const Duration(days: 14));

      final Set<String> holidayDates = {};
      for (final ev in holidays) {
        final dateStr = (ev['event_date'] ?? ev['date'] ?? '').toString();
        final title = (ev['title'] ?? ev['name'] ?? '').toString().toLowerCase();
        final isHoliday = ev['is_holiday'] == true ||
            ev['type']?.toString().toLowerCase() == 'holiday' ||
            title.contains('holiday') ||
            title.contains('vacation') ||
            title.contains('break') ||
            title.contains('leave') ||
            title.contains('off day') ||
            title.contains('day off') ||
            title.contains('no classes') ||
            title.contains('university closed') ||
            title.contains('closed') ||
            title.contains('eid') ||
            title.contains('puja');
        if (isHoliday && dateStr.isNotEmpty) {
          holidayDates.add(dateStr);
        }
      }

      final Map<String, List<Map<String, dynamic>>> exceptionsByCourse = {};
      for (final ex in exceptions) {
        final course = (ex['course_code'] ?? ex['courseCode'] ?? '').toString().toUpperCase().replaceAll(' ', '');
        exceptionsByCourse.putIfAbsent(course, () => []).add(Map<String, dynamic>.from(ex));
      }

      final Map<String, int> weekdayMap = {
        'Monday': DateTime.monday,
        'Tuesday': DateTime.tuesday,
        'Wednesday': DateTime.wednesday,
        'Thursday': DateTime.thursday,
        'Friday': DateTime.friday,
        'Saturday': DateTime.saturday,
        'Sunday': DateTime.sunday,
      };

      final DateTime endLimit = endDate.isAfter(today) ? today : endDate;

      final List<Map<String, dynamic>> pendingItems = [];

      for (final course in progressData) {
        final courseCode = (course['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
        if (courseCode.isEmpty) continue;

        final marksData = Map<String, dynamic>.from(course['marks_data'] ?? {});
        final attendance = Map<String, dynamic>.from(marksData['attendance'] ?? {});
        final dates = Map<String, dynamic>.from(attendance['dates'] ?? {});

        final courseExceptions = exceptionsByCourse[courseCode] ?? [];
        final Set<String> cancelledDates = {};
        final List<Map<String, dynamic>> makeups = [];

        for (final ex in courseExceptions) {
          final dateStr = ex['date']?.toString();
          final type = ex['type']?.toString();
          if (dateStr != null && dateStr.isNotEmpty) {
            if (type == 'cancel') {
              cancelledDates.add(dateStr);
            } else if (type == 'makeup' || type == 'manual') {
              makeups.add(ex);
            }
          }
        }

        final List<Map<String, dynamic>> scheduledTemplates = [];
        for (final entry in grid.entries) {
          final dayName = entry.key;
          final dayClasses = entry.value;
          if (dayClasses is List) {
            for (final c in dayClasses) {
              final code = (c['courseCode'] ?? c['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
              if (code == courseCode) {
                final startTime = (c['startTime'] ?? c['start_time'] ?? '').toString();
                final endTime = (c['endTime'] ?? c['end_time'] ?? '').toString();
                final isLab = CourseUtils.isLab(startTime, endTime, code);
                final type = c['type']?.toString() ?? (isLab ? 'Lab' : 'Theory');
                scheduledTemplates.add({
                  'day': dayName,
                  'type': type,
                  'start_time': startTime,
                  'end_time': endTime,
                });
              }
            }
          }
        }

        final List<int> weekdays = scheduledTemplates.map((t) => weekdayMap[t['day']!]!).toSet().toList();

        // 1. Regular sessions up to today
        for (DateTime d = startDate; d.isBefore(endLimit) || d.isAtSameMomentAs(endLimit); d = d.add(const Duration(days: 1))) {
          if (weekdays.contains(d.weekday)) {
            final dateStr = DateFormat('yyyy-MM-dd').format(d);
            if (holidayDates.contains(dateStr) || cancelledDates.contains(dateStr)) continue;

            final dayName = DateFormat('EEEE').format(d);
            final templates = scheduledTemplates.where((t) => t['day'] == dayName).toList();

            for (final temp in templates) {
              final sessionType = CourseUtils.normalizeSessionType(temp['type']?.toString());

              if (!CourseUtils.isSessionMarked(dates, dateStr, sessionType)) {
                // If today, check if class period ended
                if (d.year == today.year && d.month == today.month && d.day == today.day) {
                  final endTimeStr = temp['end_time'] ?? '';
                  if (endTimeStr.isNotEmpty) {
                    final endMinutes = TimeUtils.parseTime(endTimeStr);
                    final nowMinutes = now.hour * 60 + now.minute;
                    if (nowMinutes < endMinutes) continue; // Not passed yet
                  }
                }

                pendingItems.add({
                  'course_code': courseCode,
                  'course_map': course,
                  'date': d,
                  'dateStr': dateStr,
                  'session_type': sessionType,
                  'session_info': temp,
                });
              }
            }
          }
        }

        // 2. Makeups / manual entries
        for (final makeup in makeups) {
          final dateStr = makeup['date']?.toString() ?? '';
          final mDate = DateTime.tryParse(dateStr);
          if (mDate != null && (mDate.isBefore(endLimit) || mDate.isAtSameMomentAs(endLimit))) {
            final sessionType = CourseUtils.normalizeSessionType(makeup['session_type']?.toString() ?? makeup['sessionType']?.toString());

            if (!CourseUtils.isSessionMarked(dates, dateStr, sessionType)) {
              if (mDate.year == today.year && mDate.month == today.month && mDate.day == today.day) {
                final endTimeStr = (makeup['end_time'] ?? makeup['endTime'] ?? '').toString();
                if (endTimeStr.isNotEmpty) {
                  final endMinutes = TimeUtils.parseTime(endTimeStr);
                  final nowMinutes = now.hour * 60 + now.minute;
                  if (nowMinutes < endMinutes) continue;
                }
              }

              pendingItems.add({
                'course_code': courseCode,
                'course_map': course,
                'date': mDate,
                'dateStr': dateStr,
                'session_type': sessionType,
                'session_info': makeup,
              });
            }
          }
        }
      }

      pendingItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      state.pendingAttendanceItems = pendingItems;
      onStateChanged();
    } catch (e) {
      debugPrint('[DashboardController] Error loading pending attendance: $e');
    }
  }

  /// Marks a single pending attendance session
  Future<void> markSingleAttendance({
    required WidgetRef ref,
    required Map<String, dynamic> item,
    required String status,
  }) async {
    final currentUser = user;
    if (currentUser == null || state.semesterCode.isEmpty) return;

    state.isSavingAttendance = true;
    onStateChanged();

    try {
      final dateStr = item['dateStr'] as String;
      final sessionType = CourseUtils.normalizeSessionType(item['session_type'] as String?);
      final courseCode = (item['course_code'] as String).toUpperCase().replaceAll(' ', '');

      // Fresh lookup from SemesterProgressRepository to avoid stale course_map overwrite
      final progressData = await ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(
        currentUser.id,
        state.semesterCode,
      );

      final courseMap = progressData.firstWhere(
        (c) => CourseUtils.areEquivalent(c['course_code'], courseCode),
        orElse: () => item['course_map'] as Map<String, dynamic>? ?? <String, dynamic>{
          'course_code': courseCode,
          'semester_code': state.semesterCode,
        },
      );

      final updatedMap = Map<String, dynamic>.from(courseMap);
      final marksData = Map<String, dynamic>.from(updatedMap['marks_data'] ?? {});
      final attendance = Map<String, dynamic>.from(marksData['attendance'] ?? {});
      final dates = Map<String, dynamic>.from(attendance['dates'] ?? {});
      final types = Map<String, dynamic>.from(attendance['types'] ?? {});

      final key = '${dateStr}_$sessionType';
      dates[key] = status;
      types[key] = sessionType;
      dates[dateStr] = status; // legacy fallback
      types[dateStr] = sessionType;

      attendance['dates'] = dates;
      attendance['types'] = types;
      marksData['attendance'] = attendance;
      updatedMap['marks_data'] = marksData;

      await ref.read(semesterProgressRepositoryProvider).saveCourseMarks(
        currentUser.id,
        state.semesterCode,
        updatedMap,
      );

      // Keep pending attendance items up to date in case the user marks another session of the same course
      for (final pi in state.pendingAttendanceItems) {
        if (CourseUtils.areEquivalent(pi['course_code'], courseCode)) {
          pi['course_map'] = updatedMap;
        }
      }

      state.pendingAttendanceItems.removeWhere((i) =>
          CourseUtils.areEquivalent(i['course_code'], courseCode) &&
          i['dateStr'] == dateStr &&
          CourseUtils.normalizeSessionType(i['session_type'] as String?) == sessionType);
      state.isSavingAttendance = false;
      onStateChanged();

      ref.invalidate(semesterProgressDataProvider(state.semesterCode));
    } catch (e) {
      state.isSavingAttendance = false;
      onStateChanged();
      rethrow;
    }
  }

  /// Marks multiple attendance sessions at once
  Future<int> markMultipleAttendance({
    required WidgetRef ref,
    required List<Map<String, dynamic>> items,
    required String status,
  }) async {
    final currentUser = user;
    if (currentUser == null || state.semesterCode.isEmpty) return 0;

    state.isSavingAttendance = true;
    onStateChanged();

    try {
      final List<Future<void>> saveFutures = [];
      final List<String> codesDatesAndTypes = [];

      final progressData = await ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(currentUser.id, state.semesterCode);
      final Map<String, Map<String, dynamic>> accumulatedCourseUpdates = {};

      for (final item in items) {
        final courseCode = (item['course_code'] as String).toUpperCase().replaceAll(' ', '');
        final dateStr = item['dateStr'] as String;
        final sessionType = CourseUtils.normalizeSessionType(item['session_type'] as String?);

        if (!accumulatedCourseUpdates.containsKey(courseCode)) {
          final courseMap = progressData.firstWhere(
            (c) => CourseUtils.areEquivalent(c['course_code'], courseCode),
            orElse: () => <String, dynamic>{},
          );
          if (courseMap.isEmpty) continue;
          accumulatedCourseUpdates[courseCode] = Map<String, dynamic>.from(courseMap);
        }

        final updatedMap = accumulatedCourseUpdates[courseCode]!;
        if (updatedMap['marks_data'] == null) updatedMap['marks_data'] = <String, dynamic>{};
        final marksData = Map<String, dynamic>.from(updatedMap['marks_data']);
        if (marksData['attendance'] == null) marksData['attendance'] = <String, dynamic>{};
        final attendance = Map<String, dynamic>.from(marksData['attendance']);
        final dates = Map<String, dynamic>.from(attendance['dates'] ?? {});
        final types = Map<String, dynamic>.from(attendance['types'] ?? {});

        final key = '${dateStr}_$sessionType';
        dates[key] = status;
        types[key] = sessionType;
        dates[dateStr] = status;
        types[dateStr] = sessionType;

        attendance['dates'] = dates;
        attendance['types'] = types;
        marksData['attendance'] = attendance;
        updatedMap['marks_data'] = marksData;

        codesDatesAndTypes.add('${courseCode}_${dateStr}_$sessionType');
      }

      for (final entry in accumulatedCourseUpdates.entries) {
        saveFutures.add(
          ref.read(semesterProgressRepositoryProvider).saveCourseMarks(currentUser.id, state.semesterCode, entry.value),
        );
      }

      if (saveFutures.isNotEmpty) {
        await Future.wait(saveFutures);

        for (final pi in state.pendingAttendanceItems) {
          final pCode = (pi['course_code'] as String).toUpperCase().replaceAll(' ', '');
          if (accumulatedCourseUpdates.containsKey(pCode)) {
            pi['course_map'] = accumulatedCourseUpdates[pCode];
          }
        }

        state.pendingAttendanceItems.removeWhere((i) {
          final cCode = (i['course_code'] as String).toUpperCase().replaceAll(' ', '');
          final sType = CourseUtils.normalizeSessionType(i['session_type'] as String?);
          final key = '${cCode}_${i['dateStr']}_$sType';
          return codesDatesAndTypes.contains(key);
        });
        state.isSavingAttendance = false;
        onStateChanged();
        ref.invalidate(semesterProgressDataProvider(state.semesterCode));
      } else {
        state.isSavingAttendance = false;
        onStateChanged();
      }

      return codesDatesAndTypes.length;
    } catch (e) {
      state.isSavingAttendance = false;
      onStateChanged();
      rethrow;
    }
  }

  /// Marks attendance for the Hero NextClassCard
  Future<void> markAttendanceForNextClass({
    required WidgetRef ref,
    required ScheduleItem item,
  }) async {
    final currentUser = user;
    if (currentUser == null || state.semesterCode.isEmpty) return;

    final targetDateStr = state.lastValidScheduleData?['dateStr'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sessionType = CourseUtils.normalizeSessionType(item.sessionType);
    final courseCode = item.courseCode.toUpperCase().replaceAll(' ', '');

    final progressData = await ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(currentUser.id, state.semesterCode);
    final courseMap = progressData.firstWhere(
      (c) => CourseUtils.areEquivalent(c['course_code'], courseCode),
      orElse: () => <String, dynamic>{},
    );

    final updatedMap = courseMap.isNotEmpty
        ? Map<String, dynamic>.from(courseMap)
        : <String, dynamic>{
            'course_code': courseCode,
            'marks_data': <String, dynamic>{},
          };

    final marksData = Map<String, dynamic>.from(updatedMap['marks_data'] ?? {});
    final attendance = Map<String, dynamic>.from(marksData['attendance'] ?? {});
    final dates = Map<String, dynamic>.from(attendance['dates'] ?? {});
    final types = Map<String, dynamic>.from(attendance['types'] ?? {});

    final key = '${targetDateStr}_$sessionType';
    dates[key] = 'joined';
    types[key] = sessionType;
    dates[targetDateStr] = 'joined';
    types[targetDateStr] = sessionType;

    attendance['dates'] = dates;
    attendance['types'] = types;
    marksData['attendance'] = attendance;
    updatedMap['marks_data'] = marksData;

    await ref.read(semesterProgressRepositoryProvider).saveCourseMarks(currentUser.id, state.semesterCode, updatedMap);

    for (final pi in state.pendingAttendanceItems) {
      if (CourseUtils.areEquivalent(pi['course_code'], courseCode)) {
        pi['course_map'] = updatedMap;
      }
    }

    state.pendingAttendanceItems.removeWhere((i) =>
        CourseUtils.areEquivalent(i['course_code'], courseCode) &&
        i['dateStr'] == targetDateStr &&
        CourseUtils.normalizeSessionType(i['session_type'] as String?) == sessionType);
    onStateChanged();

    ref.invalidate(semesterProgressDataProvider(state.semesterCode));
  }

  Future<void> markTaskCompleted({
    required WidgetRef ref,
    required String taskId,
  }) async {
    final currentUser = user;
    if (currentUser == null) return;
    await ref.read(taskRepositoryProvider).updateTaskStatus(currentUser.id, taskId, true);
    state.tasks.removeWhere((t) => t['id']?.toString() == taskId);
    onStateChanged();
  }

  Future<void> markTaskMissed({
    required WidgetRef ref,
    required String taskId,
  }) async {
    final currentUser = user;
    if (currentUser == null) return;
    await ref.read(taskRepositoryProvider).updateTaskMissedStatus(currentUser.id, taskId, true);
    state.tasks.removeWhere((t) => t['id']?.toString() == taskId);
    onStateChanged();
  }

  void dismissUpdateBanner() {
    state.showUpdateBanner = false;
    onStateChanged();
  }

  Future<void> checkAdvisingBanner(String nextSemCode, dynamic advisingEndObj) async {
    if (advisingEndObj == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool('advising_banner_dismissed_$nextSemCode') ?? false;
      state.showAdvisingBanner = !isDismissed;
      onStateChanged();
    } catch (e) {
      debugPrint('[DashboardController] Advising check error: $e');
    }
  }

  Future<void> dismissAdvisingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('advising_banner_dismissed_${state.semesterCode}', true);
    state.showAdvisingBanner = false;
    onStateChanged();
  }

  Future<void> checkPortalSyncGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_portal_sync_guide_v1') ?? false;
    state.showPortalSyncBanner = !hasSeen;
    onStateChanged();
  }

  Future<void> dismissPortalSyncBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_portal_sync_guide_v1', true);
    state.showPortalSyncBanner = false;
    onStateChanged();
  }
}
