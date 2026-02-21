import 'package:flutter/foundation.dart';

import '../models/course_model.dart';

class SchedulerLogic {
  static Future<void> scheduleAllNotifications(
      List<Course> enrolledCourses) async {
    // Notifications removed
    debugPrint(
        '[Scheduler] Scheduling notifications for ${enrolledCourses.length} courses (Notifications Disabled)');

    // ... logic removed ...
  }

  static Future<void> cancelAllNotifications() async {
    debugPrint('[Scheduler] Cancel all notifications');
  }

  static Future<void> updateScheduleNotifications(List<Course> courses) async {
    await scheduleAllNotifications(courses);
  }

  /// Alternative: Schedule from cloud schedule map directly
  /// The cloudSchedule has format: { "S": [...classes], "M": [...], etc }
  static Future<void> scheduleFromCloudSchedule(
      Map<String, dynamic>? cloudSchedule) async {
    debugPrint(
        '[Scheduler] Schedule from cloud schedule called (Notifications Disabled)');
  }
}
