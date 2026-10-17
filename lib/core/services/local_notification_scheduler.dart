import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../utils/time_utils.dart';
import 'routine_cache_service.dart';

final localNotificationSchedulerProvider = Provider<LocalNotificationScheduler>((ref) {
  final scheduler = LocalNotificationScheduler(ref);
  return scheduler;
});

class LocalNotificationScheduler {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String channelId = 'ewumate_high_priority_reminders_v2';
  static const String channelName = 'Task Reminders (V2)';
  static const String channelDesc = 'Notifications for class and task timing';

  static const String _scheduledKeysBoxKey = 'active_scheduled_keys';
  static const String _deliveredKeysBoxKey = 'delivered_alert_keys';

  bool _tzInitialized = false;

  LocalNotificationScheduler(this._ref) {
    _initTimezone();
  }

  void _initTimezone() {
    if (!_tzInitialized) {
      try {
        tz.initializeTimeZones();
        _tzInitialized = true;
      } catch (e) {
        if (kDebugMode) debugPrint('[LocalNotificationScheduler] Timezone init error: $e');
      }
    }
  }

  /// Deterministic Notification ID from alertKey
  int getNotificationId(String alertKey) {
    return alertKey.hashCode.abs() % 2147483647;
  }

  /// Checks if an alert key was scheduled or recently triggered locally (Anti-Duplication)
  bool isRecentlyScheduledOrDelivered(String alertKey) {
    if (alertKey.isEmpty) return false;
    try {
      if (!Hive.isBoxOpen('routine_cache_box')) return false;
      final box = Hive.box('routine_cache_box');

      // Check delivered keys (within last 45 minutes)
      final delivered = box.get(_deliveredKeysBoxKey) as Map<dynamic, dynamic>? ?? {};
      final deliveredTimeStr = delivered[alertKey] as String?;
      if (deliveredTimeStr != null) {
        final dt = DateTime.tryParse(deliveredTimeStr);
        if (dt != null && DateTime.now().difference(dt).inMinutes < 45) {
          return true;
        }
      }

      // Check active scheduled keys
      final scheduled = box.get(_scheduledKeysBoxKey) as Map<dynamic, dynamic>? ?? {};
      if (scheduled.containsKey(alertKey)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Records an alert key as delivered locally and syncs to Supabase log
  Future<void> markAlertDelivered(String alertKey) async {
    try {
      if (!Hive.isBoxOpen('routine_cache_box')) return;
      final box = Hive.box('routine_cache_box');
      final delivered = Map<String, dynamic>.from(box.get(_deliveredKeysBoxKey) as Map? ?? {});
      final nowStr = DateTime.now().toIso8601String();
      delivered[alertKey] = nowStr;

      // Clean up entries older than 24 hours
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      delivered.removeWhere((k, v) {
        final dt = DateTime.tryParse(v.toString());
        return dt == null || dt.isBefore(cutoff);
      });

      await box.put(_deliveredKeysBoxKey, delivered);

      // Update Supabase local_notification_logs status to 'delivered'
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final deviceId = getDeviceId();
        _supabase.from('local_notification_logs').upsert({
          'user_id': userId,
          'device_id': deviceId,
          'alert_key': alertKey,
          'status': 'delivered',
          'dispatched_at': nowStr,
          'updated_at': nowStr,
        }, onConflict: 'user_id,device_id,alert_key').then((_) {}).catchError((_) {});
      }
    } catch (_) {}
  }

  /// Records an alert key as failed when error occurs during scheduling or trigger
  Future<void> logAlertFailed(String alertKey, String errorMessage) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final deviceId = getDeviceId();
      final nowStr = DateTime.now().toIso8601String();
      _supabase.from('local_notification_logs').upsert({
        'user_id': userId,
        'device_id': deviceId,
        'alert_key': alertKey,
        'status': 'failed',
        'error_message': errorMessage,
        'updated_at': nowStr,
      }, onConflict: 'user_id,device_id,alert_key').then((_) {}).catchError((_) {});
    } catch (_) {}
  }

  /// Cancels all pending notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      if (Hive.isBoxOpen('routine_cache_box')) {
        await Hive.box('routine_cache_box').delete(_scheduledKeysBoxKey);
      }
      if (kDebugMode) debugPrint('[LocalNotificationScheduler] Cancelled all pending notifications.');
    } catch (e) {
      if (kDebugMode) debugPrint('[LocalNotificationScheduler] Error cancelling notifications: $e');
    }
  }

  /// Format remaining minutes to human readable string matching alert-scheduler
  String _formatRemainingTime(int minutes) {
    if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
    return '$hours hour${hours == 1 ? '' : 's'} $remainingMins minute${remainingMins == 1 ? '' : 's'}';
  }

  /// Synchronizes local class reminders for the rolling 7-day window.
  /// Uses the 3 pillars and verifies checksum. If unchanged, skips re-scheduling.
  Future<int> syncLocalReminders({
    required String userId,
    required String semesterCode,
    required Map<String, dynamic> calendar,
    required Map<String, dynamic> weeklyGrid,
    required List<dynamic> exceptions,
    Map<String, dynamic>? userReminderSettings,
    bool forceReschedule = false,
  }) async {
    final cacheService = _ref.read(routineCacheServiceProvider);
    final newChecksum = cacheService.calculateChecksum(
      calendar: calendar,
      weeklyGrid: weeklyGrid,
      exceptions: exceptions,
    );

    final storedChecksum = cacheService.getStoredChecksum(userId, semesterCode);

    if (!forceReschedule && storedChecksum != null && storedChecksum == newChecksum) {
      if (kDebugMode) {
        debugPrint('[LocalNotificationScheduler] Checksum match ($storedChecksum). Skipping re-schedule.');
      }
      return 0; // Cache hit - no need to reschedule
    }

    _initTimezone();

    // Clear previous scheduled alarms before deploying fresh rolling 7-day schedule
    await cancelAllNotifications();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Resolve start & end limits
    DateTime? startDate = DateTime.tryParse(calendar['classes_start_date']?.toString() ?? '');
    DateTime? endDate = DateTime.tryParse(calendar['classes_end_date']?.toString() ?? '');
    startDate ??= today.subtract(const Duration(days: 30));
    endDate ??= today.add(const Duration(days: 60));

    // Build holiday lookup
    final Set<String> holidayDates = {};
    final holidaysList = calendar['events'] as List? ?? calendar['holidays'] as List? ?? [];
    for (final ev in holidaysList) {
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

    // Build exceptions lookup
    final Set<String> cancelledClasses = {}; // "YYYY-MM-DD:COURSE_CODE"
    final List<Map<String, dynamic>> makeupClasses = [];

    for (final ex in exceptions) {
      final dateStr = ex['date']?.toString() ?? '';
      final cCode = (ex['course_code'] ?? ex['courseCode'] ?? '').toString().toUpperCase().replaceAll(' ', '');
      final type = ex['type']?.toString();
      if (dateStr.isNotEmpty) {
        if (type == 'cancel') {
          cancelledClasses.add('$dateStr:$cCode');
        } else if (type == 'makeup' || type == 'manual') {
          makeupClasses.add({
            'courseCode': cCode,
            'courseName': ex['course_name'] ?? ex['courseName'] ?? 'Makeup Class',
            'startTime': ex['start_time'] ?? ex['startTime'] ?? '',
            'endTime': ex['end_time'] ?? ex['endTime'] ?? '',
            'room': ex['room'] ?? 'TBA',
            'dateStr': dateStr,
          });
        }
      }
    }

    final Map<String, String> scheduledKeysMap = {};
    int scheduledCount = 0;
    DateTime? earliestNextAlert;
    final deviceId = getDeviceId();
    final platformStr = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : Platform.operatingSystem));
    final List<Map<String, dynamic>> localLogItems = [];

    // Schedule next 7 rolling days (Day 0 = today, up to Day 6)
    for (int offset = 0; offset < 7; offset++) {
      final targetDate = today.add(Duration(days: offset));
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
      final dayName = DateFormat('EEEE').format(targetDate);

      if (targetDate.isBefore(startDate) || targetDate.isAfter(endDate)) continue;
      if (holidayDates.contains(dateStr)) continue;

      final dayClasses = weeklyGrid[dayName] as List? ?? [];
      final dayMakeups = makeupClasses.where((m) => m['dateStr'] == dateStr).toList();

      final List<Map<String, dynamic>> allDayClasses = [
        ...dayClasses.map((c) => {...Map<String, dynamic>.from(c as Map), 'isMakeup': false}),
        ...dayMakeups.map((c) => {...c, 'isMakeup': true}),
      ];

      // Filter cancellations
      final activeClasses = <Map<String, dynamic>>[];
      for (final c in allDayClasses) {
        final cCode = (c['courseCode'] ?? c['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
        if (cancelledClasses.contains('$dateStr:$cCode')) continue;
        activeClasses.add(c);
      }

      if (activeClasses.isEmpty) continue;

      // Sort chronologically by start time
      activeClasses.sort((a, b) {
        final aStart = TimeUtils.parseTime(a['startTime'] ?? a['start_time'] ?? '');
        final bStart = TimeUtils.parseTime(b['startTime'] ?? b['start_time'] ?? '');
        return aStart.compareTo(bStart);
      });

      for (int i = 0; i < activeClasses.length; i++) {
        final c = activeClasses[i];
        final cCode = (c['courseCode'] ?? c['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
        final startTimeStr = (c['startTime'] ?? c['start_time'] ?? '').toString();
        final room = (c['room'] ?? c['venue'] ?? 'TBA').toString();
        final isMakeup = c['isMakeup'] == true;

        if (startTimeStr.isEmpty) continue;

        final currentStartMinutes = TimeUtils.parseTime(startTimeStr);
        final startH = currentStartMinutes ~/ 60;
        final startM = currentStartMinutes % 60;

        final classStart = DateTime(targetDate.year, targetDate.month, targetDate.day, startH, startM);

        final isFirstClass = (i == 0);
        int gapMinutes = 9999;
        if (!isFirstClass) {
          final prevClass = activeClasses[i - 1];
          final prevEndTimeStr = (prevClass['endTime'] ?? prevClass['end_time'] ?? prevClass['startTime'] ?? '').toString();
          final prevEndMinutes = TimeUtils.parseTime(prevEndTimeStr);
          gapMinutes = (currentStartMinutes - prevEndMinutes).clamp(0, 9999);
        }

        // Gap-aware notification slots matching alert-scheduler
        List<int> configuredMinutes = [];

        if (isFirstClass) {
          // Rule 1: 1st class -> [60, 30, 15] + custom
          List<int> baseSlots = [60, 30, 15];
          if (userReminderSettings != null) {
            final custom = userReminderSettings[cCode];
            if (custom is List) {
              final customNums = custom.map((e) => int.tryParse(e.toString()) ?? 0).where((n) => n > 0 && n <= 300).toList();
              baseSlots = {...baseSlots, ...customNums}.toList();
            }
          }
          baseSlots.sort((a, b) => b.compareTo(a));
          configuredMinutes = baseSlots;
        } else if (gapMinutes > 30) {
          // Rule 2: Gap > 30 mins -> [30, 15] (filtered by gap)
          List<int> baseSlots = [30, 15].where((m) => m <= gapMinutes).toList();
          if (userReminderSettings != null) {
            final custom = userReminderSettings[cCode];
            if (custom is List) {
              final customNums = custom.map((e) => int.tryParse(e.toString()) ?? 0).where((n) => n > 0 && n <= gapMinutes).toList();
              baseSlots = {...baseSlots, ...customNums}.toList();
            }
          }
          baseSlots.sort((a, b) => b.compareTo(a));
          configuredMinutes = baseSlots;
        } else {
          // Rule 3: Back-to-back class (gap <= 30 mins) -> STRICTLY 5 mins
          configuredMinutes = [5];
        }

        for (final m in configuredMinutes) {
          final triggerTime = classStart.subtract(Duration(minutes: m));
          if (triggerTime.isBefore(now)) continue; // Past trigger time

          final alertKey = 'c_${m}m:$cCode:$dateStr';
          final timeLeftText = _formatRemainingTime(m);

          final title = isMakeup
              ? 'Upcoming Class: $cCode in $timeLeftText'
              : 'Class in $timeLeftText: $cCode';

          final body = isMakeup
              ? 'Your $cCode class starts in $timeLeftText (at $startTimeStr) in $room (Makeup/Manual).'
              : 'Your $cCode class starts in $timeLeftText (at $startTimeStr) in $room.';

          final notifId = getNotificationId(alertKey);

          try {
            final scheduledTz = tz.TZDateTime.from(triggerTime, tz.local);

            final androidDetails = AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: channelDesc,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              tag: alertKey, // Android groups/replaces identical tags
            );

            const iosDetails = DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            );

            final details = NotificationDetails(
              android: androidDetails,
              iOS: iosDetails,
            );

            await _notifications.zonedSchedule(
              id: notifId,
              title: title,
              body: body,
              scheduledDate: scheduledTz,
              notificationDetails: details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: jsonEncode({
                'title': title,
                'body': body,
                'alert_key': alertKey,
                'course_code': cCode,
                'trigger_time': triggerTime.toIso8601String(),
              }),
            );

            scheduledKeysMap[alertKey] = triggerTime.toIso8601String();
            scheduledCount++;

            localLogItems.add({
              'user_id': userId,
              'device_id': deviceId,
              'platform': platformStr,
              'alert_key': alertKey,
              'title': title,
              'body': body,
              'trigger_at': triggerTime.toIso8601String(),
              'status': 'scheduled',
              'updated_at': DateTime.now().toIso8601String(),
            });

            if (earliestNextAlert == null || triggerTime.isBefore(earliestNextAlert)) {
              earliestNextAlert = triggerTime;
            }
          } catch (e) {
            if (kDebugMode) debugPrint('[LocalNotificationScheduler] Error scheduling $alertKey: $e');
            localLogItems.add({
              'user_id': userId,
              'device_id': deviceId,
              'platform': platformStr,
              'alert_key': alertKey,
              'title': title,
              'body': body,
              'trigger_at': triggerTime.toIso8601String(),
              'status': 'failed',
              'error_message': e.toString(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }
    }

    // Persist scheduled keys map in Hive
    try {
      if (Hive.isBoxOpen('routine_cache_box')) {
        await Hive.box('routine_cache_box').put(_scheduledKeysBoxKey, scheduledKeysMap);
      }
    } catch (_) {}

    // Save cache & new checksum
    await cacheService.saveRoutineCache(
      userId: userId,
      semesterCode: semesterCode,
      calendar: calendar,
      weeklyGrid: weeklyGrid,
      exceptions: exceptions,
      checksum: newChecksum,
    );

    // Record deployment state in Supabase database log table
    await _logLocalDeploymentToDatabase(
      userId: userId,
      semesterCode: semesterCode,
      checksum: newChecksum,
      scheduledCount: scheduledCount,
      activeKeys: scheduledKeysMap.keys.toList(),
      nextAlertTime: earliestNextAlert,
    );

    // Sync each individual scheduled alarm to local_notification_logs
    if (localLogItems.isNotEmpty) {
      try {
        await _supabase.from('local_notification_logs').upsert(
          localLogItems,
          onConflict: 'user_id,device_id,alert_key',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[LocalNotificationScheduler] Failed to upsert local_notification_logs: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[LocalNotificationScheduler] Deployed $scheduledCount local notifications for 7-day window.');
    }

    return scheduledCount;
  }

  /// Returns a persistent, unique device ID for this installation
  String getDeviceId() {
    try {
      if (Hive.isBoxOpen('profile_box')) {
        final box = Hive.box('profile_box');
        var id = box.get('client_device_id') as String?;
        if (id != null && id.isNotEmpty) return id;
        id = 'dev_${const Uuid().v4()}';
        box.put('client_device_id', id);
        return id;
      }
    } catch (_) {}
    return 'primary';
  }

  /// Logs deployment state to Supabase table `local_notification_states`
  Future<void> _logLocalDeploymentToDatabase({
    required String userId,
    required String semesterCode,
    required String checksum,
    required int scheduledCount,
    required List<String> activeKeys,
    DateTime? nextAlertTime,
  }) async {
    try {
      final deviceId = getDeviceId();
      final platformStr = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : Platform.operatingSystem));

      String appVersion = '2.0.0';
      try {
        final pkg = await PackageInfo.fromPlatform();
        appVersion = '${pkg.version}+${pkg.buildNumber}';
      } catch (_) {}

      await _supabase.from('local_notification_states').upsert({
        'user_id': userId,
        'device_id': deviceId,
        'platform': platformStr,
        'semester_code': semesterCode,
        'checksum': checksum,
        'scheduled_count': scheduledCount,
        'active_keys': activeKeys.take(100).toList(),
        'last_scheduled_at': DateTime.now().toIso8601String(),
        'status': 'active',
        'metadata': {
          'next_alert_time': nextAlertTime?.toIso8601String(),
          'device_time': DateTime.now().toIso8601String(),
          'app_version': appVersion,
          'os_version': kIsWeb ? 'web' : Platform.operatingSystemVersion,
        },
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,device_id');

      if (kDebugMode) {
        debugPrint('[LocalNotificationScheduler] Logged deployment state to database ($scheduledCount alerts for device $deviceId on $platformStr).');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalNotificationScheduler] Failed to log deployment state to database: $e');
      }
    }
  }
}
