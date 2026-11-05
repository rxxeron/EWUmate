import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:ewumate/core/utils/time_utils.dart';

void main() {
  group('TimeUtils.parseTime robust parsing tests', () {
    test('standard formats', () {
      expect(TimeUtils.parseTime('8:30 AM'), 8 * 60 + 30);
      expect(TimeUtils.parseTime('08:30 AM'), 8 * 60 + 30);
      expect(TimeUtils.parseTime('4:50 PM'), 16 * 60 + 50);
      expect(TimeUtils.parseTime('04:50 PM'), 16 * 60 + 50);
      expect(TimeUtils.parseTime('12:00 PM'), 12 * 60);
      expect(TimeUtils.parseTime('12:00 AM'), 0);
    });

    test('range format (4:50 PM - 6:20 PM)', () {
      expect(TimeUtils.parseTime('4:50 PM - 6:20 PM'), 16 * 60 + 50);
      expect(TimeUtils.parseTime('04:50 PM - 06:20 PM'), 16 * 60 + 50);
    });

    test('no space AM/PM (4:50PM)', () {
      expect(TimeUtils.parseTime('4:50PM'), 16 * 60 + 50);
      expect(TimeUtils.parseTime('8:30AM'), 8 * 60 + 30);
    });

    test('omitted AM/PM heuristic for afternoon/evening university classes', () {
      expect(TimeUtils.parseTime('4:50'), 16 * 60 + 50);
      expect(TimeUtils.parseTime('04:50'), 16 * 60 + 50);
      expect(TimeUtils.parseTime('8:30'), 8 * 60 + 30);
    });

    test('invalid or empty', () {
      expect(TimeUtils.parseTime(null), 24 * 60);
      expect(TimeUtils.parseTime(''), 24 * 60);
    });
  });

  group('Dhaka timezone deterministic scheduling calculation', () {
    test('4:50 PM class triggers exactly at 4:20 PM, 4:35 PM in Asia/Dhaka', () {
      tz.initializeTimeZones();
      final dhaka = tz.getLocation('Asia/Dhaka');

      final targetDate = DateTime(2026, 11, 5);
      final currentStartMinutes = TimeUtils.parseTime('4:50 PM');
      final startH = currentStartMinutes ~/ 60;
      final startM = currentStartMinutes % 60;

      final classStartTz = tz.TZDateTime(
        dhaka,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        startH,
        startM,
      );

      expect(classStartTz.hour, 16);
      expect(classStartTz.minute, 50);

      final trigger30m = classStartTz.subtract(const Duration(minutes: 30));
      expect(trigger30m.hour, 16);
      expect(trigger30m.minute, 20);

      final trigger15m = classStartTz.subtract(const Duration(minutes: 15));
      expect(trigger15m.hour, 16);
      expect(trigger15m.minute, 35);
    });
  });
}
