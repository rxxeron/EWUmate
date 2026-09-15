import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/task.dart';
import '../../../core/providers/academic_providers.dart';
import '../../../core/repositories/task_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/utils/course_utils.dart';
import '../../../core/utils/refresh_utils.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/utils/version_utils.dart';
import '../../auth/auth_providers.dart';
import '../../semester_progress/semester_progress_repository.dart';
import '../dashboard_logic.dart';
import '../dashboard_repository.dart';

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
      RefreshUtils.refreshAcademicData(ref);
    }

    // PHASE 0: Instant Cache Load from Hive
    if (state.lastValidScheduleData == null) {
      try {
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
      } catch (e) {
        debugPrint('[DashboardController] Cache scan error: $e');
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

      final results = await Future.wait<dynamic>([
        ref.read(dashboardRepositoryProvider).getSimplifiedDashboardData(
          code,
          targetDate,
          track: track,
          profileUpdatedAt: profileUpdatedAt,
        ),
        Future<List<dynamic>>(() async {
          try {
            return await supabase
                .from('enrollments')
                .select('courses(code, title)')
                .eq('user_id', currentUser.id)
                .eq('semester_code', code);
          } catch (e) {
            return [];
          }
        }),
        PackageInfo.fromPlatform().catchError(
          (_) => PackageInfo(
            appName: '',
            packageName: '',
            version: '',
            buildNumber: '',
          ),
        ),
      ]);

      final scheduleData = results[0] as Map<String, dynamic>;
      final versionInfo = results[2] as PackageInfo;

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
      updateHomeWidget(scheduleData);
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
      final bool isBiSemester = profile?.track == 'bi';

      final results = await Future.wait<dynamic>([
        supabase
            .from('user_semester_states')
            .select('weekly_grid_cache')
            .eq('user_id', currentUser.id)
            .eq('semester_code', state.semesterCode)
            .maybeSingle(),
        supabase
            .from('active_semester')
            .select('classes_start_date, classes_end_date')
            .eq('track', isBiSemester ? 'bi_semester' : 'tri_semester')
            .maybeSingle(),
        supabase
            .from(CourseUtils.semesterTable(
              'calendar',
              state.semesterCode,
              cycleType: isBiSemester ? 'bi_semester' : 'tri_semester',
            ))
            .select()
            .catchError((_) => []),
        supabase
            .from('schedule_exceptions')
            .select()
            .eq('user_id', currentUser.id),
        ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(currentUser.id, state.semesterCode),
      ]);

      final grid = (results[0] as Map<String, dynamic>?)?['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
      final activeSem = results[1] as Map<String, dynamic>?;
      final holidays = results[2] as List;
      final exceptions = results[3] as List;
      final progressData = results[4] as List<Map<String, dynamic>>;

      DateTime? startDate = DateTime.tryParse(activeSem?['classes_start_date']?.toString() ?? '');
      DateTime? endDate = DateTime.tryParse(activeSem?['classes_end_date']?.toString() ?? '');
      startDate ??= DateTime.now().subtract(const Duration(days: 45));
      endDate ??= DateTime.now().add(const Duration(days: 45));

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
            title.contains('no classes');
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

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
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
              final sessionType = temp['type'] ?? 'Theory';
              final key = '${dateStr}_$sessionType';

              if (!dates.containsKey(key) && !dates.containsKey(dateStr)) {
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
            final sessionType = makeup['session_type']?.toString() ?? makeup['sessionType']?.toString() ?? 'Theory';
            final key = '${dateStr}_$sessionType';

            if (!dates.containsKey(key) && !dates.containsKey(dateStr)) {
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
      final courseMap = item['course_map'] as Map<String, dynamic>;
      final dateStr = item['dateStr'] as String;
      final sessionType = item['session_type'] as String;

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

      await ref.read(semesterProgressRepositoryProvider).saveCourseMarks(currentUser.id, state.semesterCode, updatedMap);

      state.pendingAttendanceItems.removeWhere((i) =>
          i['course_code'] == item['course_code'] &&
          i['dateStr'] == dateStr &&
          i['session_type'] == sessionType);
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
        final sessionType = item['session_type'] as String;

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
        state.pendingAttendanceItems.removeWhere((i) {
          final key = '${(i['course_code'] as String).toUpperCase().replaceAll(' ', '')}_${i['dateStr']}_${i['session_type']}';
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

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sessionType = item.sessionType;
    final courseCode = item.courseCode.toUpperCase().replaceAll(' ', '');

    final progressData = await ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(currentUser.id, state.semesterCode);
    final courseMap = progressData.firstWhere(
      (c) => CourseUtils.areEquivalent(c['course_code'], courseCode),
      orElse: () => <String, dynamic>{},
    );

    if (courseMap.isNotEmpty) {
      final updatedMap = Map<String, dynamic>.from(courseMap);
      final marksData = Map<String, dynamic>.from(updatedMap['marks_data'] ?? {});
      final attendance = Map<String, dynamic>.from(marksData['attendance'] ?? {});
      final dates = Map<String, dynamic>.from(attendance['dates'] ?? {});
      final types = Map<String, dynamic>.from(attendance['types'] ?? {});

      final key = '${dateStr}_$sessionType';
      dates[key] = 'joined';
      types[key] = sessionType;
      dates[dateStr] = 'joined';
      types[dateStr] = sessionType;

      attendance['dates'] = dates;
      attendance['types'] = types;
      marksData['attendance'] = attendance;
      updatedMap['marks_data'] = marksData;

      await ref.read(semesterProgressRepositoryProvider).saveCourseMarks(currentUser.id, state.semesterCode, updatedMap);

      state.pendingAttendanceItems.removeWhere((i) =>
          i['course_code'] == courseCode &&
          i['dateStr'] == dateStr &&
          i['session_type'] == sessionType);
      onStateChanged();

      ref.invalidate(semesterProgressDataProvider(state.semesterCode));
    }
  }

  /// Synchronizes today's next class and schedule to HomeWidget
  Future<void> updateHomeWidget(Map<String, dynamic> rawData) async {
    try {
      final processed = DashboardLogic.processDashboardData(rawData);
      final nextClass = processed['next_class'] as ScheduleItem?;

      if (nextClass != null) {
        await HomeWidget.saveWidgetData<String>('widget_course_code', nextClass.courseCode);
        await HomeWidget.saveWidgetData<String>('widget_course_title', nextClass.courseName);
        await HomeWidget.saveWidgetData<String>('widget_start_time', nextClass.startTime);
        await HomeWidget.saveWidgetData<String>('widget_room', nextClass.room);
        await HomeWidget.saveWidgetData<String>('widget_status', 'UPCOMING');
      } else {
        await HomeWidget.saveWidgetData<String>('widget_status', 'NO_CLASSES');
      }
      await HomeWidget.updateWidget(name: 'EWUmateWidgetProvider', iOSName: 'EWUmateWidget');

      final Map<String, dynamic> encodableData = {
        'status': processed['status'],
        'reason': processed['reason'],
        'displayDate': processed['displayDate'],
        'schedule': (processed['schedule'] as List? ?? []).map((item) {
          if (item is ScheduleItem) {
            return {
              'courseCode': item.courseCode,
              'courseName': item.courseName,
              'sessionType': item.sessionType,
              'startTime': item.startTime,
              'endTime': item.endTime,
              'room': item.room,
              'faculty': item.faculty,
              'isCancelled': item.isCancelled,
              'isMakeup': item.isMakeup,
            };
          }
          return item;
        }).toList(),
      };

      await HomeWidget.saveWidgetData('schedule_json', jsonEncode(encodableData));
      await HomeWidget.updateWidget(androidName: 'ScheduleWidgetProvider');
    } catch (e) {
      debugPrint('[DashboardController] HomeWidget sync error: $e');
    }
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
