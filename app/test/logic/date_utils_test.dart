import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/utils/date_utils.dart';

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

  group('DateTimeNormalizationX and parseIsoDate', () {
    test('toNormalizedDate strips time component', () {
      final withTime = DateTime(2026, 8, 16, 14, 30, 45, 500);
      final normalized = withTime.toNormalizedDate();

      expect(normalized.year, 2026);
      expect(normalized.month, 8);
      expect(normalized.day, 16);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
    });

    test('parseIsoDate parses yyyy-MM-dd cleanly', () {
      final parsed = parseIsoDate('2026-10-31');
      expect(parsed, DateTime(2026, 10, 31));
      expect(parsed.dateKey, '2026-10-31');
    });

    test('parseIsoDate parses ISO-8601 timestamp string with fallback', () {
      final parsed = parseIsoDate('2026-12-25T18:00:00.000Z');
      expect(parsed.year, 2026);
      expect(parsed.month, 12);
      expect(parsed.day, 25);
    });

    test('parseIsoDate fallback handles malformed strings gracefully', () {
      final fallback = parseIsoDate('invalid-date');
      expect(fallback, DateTime(1970, 1, 1));
    });

    test('round-trip fidelity between dateKey and parseIsoDate', () {
      final original = DateTime(2026, 4, 15);
      final key = original.dateKey;
      final parsed = parseIsoDate(key);

      expect(parsed, original);
      expect(parsed.dateKey, key);
    });
  });
}
