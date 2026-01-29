/// Application-wide constants
class AppConstants {
  // Time-related constants
  static const int eveningHourThreshold = 20; // 8 PM
  static const int examSyncDaysAhead = 7; // Days ahead to sync exams

  // Firestore query limits
  static const int firestoreWhereInLimit = 30; // Firestore whereIn limit

  // Notification scheduling
  static const int notificationScheduleDays = 7; // Days ahead to schedule notifications
  static const int morningAlarmHour = 7; // 7 AM alarm
  static const int morningClassHour = 8; // 8 AM class
  static const int morningClassMinute = 30; // 8:30 AM class
  static const int silentAlertMinutesBefore = 10; // 10 minutes before class
  static const int silentAlertMinutesBeforeShort = 5; // 5 minutes before class
  static const int breakReminderMinutesBefore = 30; // 30 minutes before next class
  static const int breakGapThresholdMinutes = 20; // Minimum gap for break reminder

  // Notification IDs
  static const int morningAlarmId = 700;
  static const int morningAlarmSnoozeId = 718;
  static const int snoozeDelayMinutes = 18; // 18 minutes after main alarm

  // Cache keys
  static const String scheduleCachePrefix = 'schedule_cache_';
  static const String progressCachePrefix = 'progress_cache_';
  static const String statsCachePrefix = 'stats_cache_';

  // Date/Time formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'EEEE, d MMM';

  // Private constructor to prevent instantiation
  AppConstants._();
}
