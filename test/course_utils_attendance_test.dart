import 'package:flutter_test/flutter_test.dart';
import 'package:ewumate/core/utils/course_utils.dart';

void main() {
  group('CourseUtils Attendance Logic Tests', () {
    test('normalizeSessionType normalizes casing and variations', () {
      expect(CourseUtils.normalizeSessionType('Theory'), 'Theory');
      expect(CourseUtils.normalizeSessionType('THEORY'), 'Theory');
      expect(CourseUtils.normalizeSessionType('theory'), 'Theory');
      expect(CourseUtils.normalizeSessionType('Lab'), 'Lab');
      expect(CourseUtils.normalizeSessionType('LAB'), 'Lab');
      expect(CourseUtils.normalizeSessionType('lab'), 'Lab');
      expect(CourseUtils.normalizeSessionType('Makeup'), 'Makeup');
      expect(CourseUtils.normalizeSessionType('makeup'), 'Makeup');
      expect(CourseUtils.normalizeSessionType(null), 'Theory');
      expect(CourseUtils.normalizeSessionType(''), 'Theory');
    });

    test('isSessionMarked correctly matches compound keys case-insensitively', () {
      final dates = {
        '2026-11-05_Theory': 'joined',
        '2026-11-05': 'joined',
      };

      expect(CourseUtils.isSessionMarked(dates, '2026-11-05', 'Theory'), isTrue);
      expect(CourseUtils.isSessionMarked(dates, '2026-11-05', 'THEORY'), isTrue);
      expect(CourseUtils.isSessionMarked(dates, '2026-11-05', 'theory'), isTrue);
      expect(CourseUtils.isSessionMarked(dates, '2026-11-05', 'Lab'), isFalse);
    });

    test('isSessionMarked distinguishes between Theory and Lab on the same day', () {
      // User only attended Lab on 2026-11-03
      final dates = {
        '2026-11-03_Lab': 'joined',
        '2026-11-03': 'joined',
      };

      expect(CourseUtils.isSessionMarked(dates, '2026-11-03', 'Lab'), isTrue);
      expect(CourseUtils.isSessionMarked(dates, '2026-11-03', 'LAB'), isTrue);
      // Theory should NOT match the plain 2026-11-03 key because 2026-11-03_Lab exists!
      expect(CourseUtils.isSessionMarked(dates, '2026-11-03', 'Theory'), isFalse);
    });

    test('isSessionMarked handles legacy rows with only dateStr', () {
      final dates = {
        '2026-09-10': 'joined',
      };

      expect(CourseUtils.isSessionMarked(dates, '2026-09-10', 'Theory'), isTrue);
      expect(CourseUtils.isSessionMarked(dates, '2026-09-11', 'Theory'), isFalse);
    });

    test('getCourseTitle dynamically resolves registered courses without hardcoding', () {
      CourseUtils.clearDynamicTitles();

      // Before registration, falls back to normalized code
      expect(CourseUtils.getCourseTitle('cse 103'), 'CSE103');
      expect(CourseUtils.getCourseTitle('MAT 101'), 'MAT101');
      expect(CourseUtils.getCourseTitle(''), '');

      // Register dynamic titles
      CourseUtils.registerTitles({
        'CSE103': 'Structured Programming',
        'MAT101': 'Differential and Integral Calculus',
      });

      expect(CourseUtils.getCourseTitle('CSE103'), 'Structured Programming');
      expect(CourseUtils.getCourseTitle('cse 103'), 'Structured Programming');
      // Handles 4-digit OBE curriculum equivalence automatically
      expect(CourseUtils.getCourseTitle('CSE7103'), 'Structured Programming');
      expect(CourseUtils.getCourseTitle('MAT101'), 'Differential and Integral Calculus');
      expect(CourseUtils.getCourseTitle('mat 7101'), 'Differential and Integral Calculus');

      // Unregistered course safely returns normalized code
      expect(CourseUtils.getCourseTitle('GEN226'), 'GEN226');
    });
  });
}
