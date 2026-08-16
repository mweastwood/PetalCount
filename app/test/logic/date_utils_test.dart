import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  group('DateFormattingX dateKey', () {
    test('formats dates with appropriate zero-padding', () {
      final date1 = DateTime(2026, 1, 5);
      expect(date1.dateKey, '2026-01-05');

      final date2 = DateTime(2026, 11, 25);
      expect(date2.dateKey, '2026-11-25');

      final date3 = DateTime(999, 3, 9);
      expect(date3.dateKey, '0999-03-09');
    });

    test('handles leap years correctly', () {
      final leapDay = DateTime(2024, 2, 29);
      expect(leapDay.dateKey, '2024-02-29');

      final nonLeapFeb = DateTime(2025, 2, 28);
      expect(nonLeapFeb.dateKey, '2025-02-28');
    });

    test('ignores time component in DateTime', () {
      final dateTime = DateTime(2026, 7, 4, 23, 59, 59, 999);
      expect(dateTime.dateKey, '2026-07-04');
    });

    test('matches substring(0, 10) for normalized dates', () {
      for (int month = 1; month <= 12; month++) {
        for (int day = 1; day <= 28; day++) {
          final dt = DateTime(2026, month, day);
          expect(dt.dateKey, dt.toIso8601String().substring(0, 10));
        }
      }
    });
  });

  group('AppDateFormats singleton formatters', () {
    final testDate = DateTime(2026, 3, 14, 9, 5);

    test('isoDate formats as yyyy-MM-dd', () {
      expect(AppDateFormats.isoDate.format(testDate), '2026-03-14');
    });

    test('shortMonthDay formats as MMM dd', () {
      expect(AppDateFormats.shortMonthDay.format(testDate), 'Mar 14');
    });

    test('monthYear formats as MMMM yyyy', () {
      expect(AppDateFormats.monthYear.format(testDate), 'March 2026');
    });

    test('fullDate formats as EEEEE, MMM dd, yyyy', () {
      expect(
        AppDateFormats.fullDate.format(testDate),
        'Saturday, Mar 14, 2026',
      );
    });

    test('monthDayYear formats as MMMM dd, yyyy', () {
      expect(AppDateFormats.monthDayYear.format(testDate), 'March 14, 2026');
    });

    test('shortMonthDayYear formats as MMM dd, yyyy', () {
      expect(AppDateFormats.shortMonthDayYear.format(testDate), 'Mar 14, 2026');
    });

    test('weekdayMonthDay formats as EEEE, MMM dd', () {
      expect(
        AppDateFormats.weekdayMonthDay.format(testDate),
        'Saturday, Mar 14',
      );
    });

    test('dateTimeWithTime formats as MMM dd, yyyy • h:mm a', () {
      expect(
        AppDateFormats.dateTimeWithTime.format(testDate),
        'Mar 14, 2026 • 9:05 AM',
      );
    });

    test('timeOfDay formats as h:mm a', () {
      expect(AppDateFormats.timeOfDay.format(testDate), '9:05 AM');
    });

    test('timeOfDayPadded formats as hh:mm a', () {
      expect(AppDateFormats.timeOfDayPadded.format(testDate), '09:05 AM');
    });
  });

  group('Date Utils and Calendar Math Tests', () {
    test(
      'calendarDaysBetween calculates correct delta across standard days',
      () {
        final d1 = DateTime(2026, 6, 1);
        final d2 = DateTime(2026, 6, 15);
        expect(calendarDaysBetween(d1, d2), 14);
        expect(calendarDaysBetween(d2, d1), -14);
        expect(calendarDaysBetween(d1, d1), 0);
      },
    );

    test(
      'calendarDaysBetween handles DST spring-forward (23h) and fall-back (25h) days accurately',
      () {
        // Even if local DateTime instances have 23 or 25 physical hours between them,
        // calendarDaysBetween normalizes to UTC midnight and computes the exact calendar day difference.
        final springStart = DateTime(2026, 3, 7);
        final springEnd = DateTime(2026, 3, 9);
        expect(calendarDaysBetween(springStart, springEnd), 2);
        expect(springStart.calendarDaysTo(springEnd), 2);
        expect(springEnd.calendarDaysSince(springStart), 2);

        final fallStart = DateTime(2026, 10, 31);
        final fallEnd = DateTime(2026, 11, 2);
        expect(calendarDaysBetween(fallStart, fallEnd), 2);
        expect(fallStart.calendarDaysTo(fallEnd), 2);
        expect(fallEnd.calendarDaysSince(fallStart), 2);
      },
    );

    test('calendarDaysBetween handles month and year boundaries correctly', () {
      // Month boundary
      final may31 = DateTime(2026, 5, 31);
      final jun1 = DateTime(2026, 6, 1);
      expect(calendarDaysBetween(may31, jun1), 1);
      expect(calendarDaysBetween(jun1, may31), -1);

      // Non-leap year Feb -> Mar
      final feb28 = DateTime(2026, 2, 28);
      final mar1 = DateTime(2026, 3, 1);
      expect(calendarDaysBetween(feb28, mar1), 1);

      // Leap year Feb 28 -> Feb 29 -> Mar 1
      final leapFeb28 = DateTime(2028, 2, 28);
      final leapFeb29 = DateTime(2028, 2, 29);
      final leapMar1 = DateTime(2028, 3, 1);
      expect(calendarDaysBetween(leapFeb28, leapFeb29), 1);
      expect(calendarDaysBetween(leapFeb28, leapMar1), 2);

      // Year boundary
      final dec31 = DateTime(2026, 12, 31);
      final jan1 = DateTime(2027, 1, 1);
      expect(calendarDaysBetween(dec31, jan1), 1);
    });

    test('DateTimeNormalizationX toNormalizedDate and toUtcDate', () {
      final localWithTime = DateTime(2026, 7, 10, 14, 30, 45);
      final normalizedLocal = localWithTime.toNormalizedDate();
      expect(normalizedLocal.year, 2026);
      expect(normalizedLocal.month, 7);
      expect(normalizedLocal.day, 10);
      expect(normalizedLocal.hour, 0);
      expect(normalizedLocal.minute, 0);
      expect(normalizedLocal.isUtc, isFalse);

      final normalizedUtc = localWithTime.toUtcDate();
      expect(normalizedUtc.year, 2026);
      expect(normalizedUtc.month, 7);
      expect(normalizedUtc.day, 10);
      expect(normalizedUtc.hour, 0);
      expect(normalizedUtc.minute, 0);
      expect(normalizedUtc.isUtc, isTrue);
    });

    test(
      'DateTimeNormalizationX addCalendarDays and subtractCalendarDays preserve midnight time',
      () {
        final start = DateTime(2026, 3, 1); // Local midnight
        final nextDay = start.addCalendarDays(1);
        expect(nextDay.year, 2026);
        expect(nextDay.month, 3);
        expect(nextDay.day, 2);
        expect(nextDay.hour, 0);
        expect(nextDay.minute, 0);

        final monthLater = start.addCalendarDays(31);
        expect(monthLater.year, 2026);
        expect(monthLater.month, 4);
        expect(monthLater.day, 1);
        expect(monthLater.hour, 0);

        final prevDay = start.subtractCalendarDays(1);
        expect(prevDay.year, 2026);
        expect(prevDay.month, 2);
        expect(prevDay.day, 28);
        expect(prevDay.hour, 0);

        // UTC preservation
        final startUtc = DateTime.utc(2026, 3, 1);
        final nextUtc = startUtc.addCalendarDays(5);
        expect(nextUtc.isUtc, isTrue);
        expect(nextUtc.day, 6);

        final prevUtc = startUtc.subtractCalendarDays(5);
        expect(prevUtc.isUtc, isTrue);
        expect(prevUtc.month, 2);
        expect(prevUtc.day, 24);
      },
    );

    test(
      'parseIsoDate and DateTimeNormalizationX.parseIso handle formats safely',
      () {
        final standard = parseIsoDate('2026-08-16');
        expect(standard, DateTime(2026, 8, 16));

        final isoFull = parseIsoDate('2026-08-16T12:00:00Z');
        expect(isoFull, DateTime(2026, 8, 16));

        final extensionParsed = DateTimeNormalizationX.parseIso('2026-08-16');
        expect(extensionParsed, DateTime(2026, 8, 16));

        final invalid = parseIsoDate('not-a-date');
        expect(invalid, DateTime(1970, 1, 1));
      },
    );

    test('round-trip fidelity between dateKey and parseIsoDate', () {
      final original = DateTime(2026, 4, 15);
      final key = original.dateKey;
      final parsed = parseIsoDate(key);

      expect(parsed, original);
      expect(parsed.dateKey, key);
    });
  });
}
