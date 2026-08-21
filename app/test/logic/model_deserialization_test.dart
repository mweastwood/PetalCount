import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/cycle.dart';
import 'package:petal_count/logic/models/daily_entry.dart';

void main() {
  group('Cycle Deserialization Tests', () {
    test('correctly parses valid date strings for startDate and endDate', () {
      final map = {
        'id': 'cycle_1',
        'startDate': '2026-03-01',
        'endDate': '2026-03-28',
        'bipCodes': ['BIP-1'],
        'dailyEntries': <String, dynamic>{},
      };

      final cycle = Cycle.fromMap(map);
      expect(cycle.id, 'cycle_1');
      expect(cycle.startDate, DateTime(2026, 3, 1));
      expect(cycle.endDate, DateTime(2026, 3, 28));
      expect(cycle.bipCodes, ['BIP-1']);
      expect(cycle.dailyEntries, isEmpty);
    });

    test(
      'gracefully handles null, missing, and non-string values for startDate and endDate',
      () {
        // Null startDate and null endDate
        final nullMap = {
          'id': 'cycle_null',
          'startDate': null,
          'endDate': null,
        };
        final cycleNull = Cycle.fromMap(nullMap);
        expect(cycleNull.startDate, DateTime(1970, 1, 1));
        expect(cycleNull.endDate, isNull);

        // Missing startDate and missing endDate
        final missingMap = {'id': 'cycle_missing'};
        final cycleMissing = Cycle.fromMap(missingMap);
        expect(cycleMissing.startDate, DateTime(1970, 1, 1));
        expect(cycleMissing.endDate, isNull);

        // Non-string / integer values
        final nonStringMap = {
          'id': 'cycle_non_string',
          'startDate': 20260301,
          'endDate': 20260328,
        };
        final cycleNonString = Cycle.fromMap(nonStringMap);
        expect(cycleNonString.startDate, isNotNull);
        expect(cycleNonString.endDate, isNotNull);

        // Malformed / invalid date strings
        final malformedMap = {
          'id': 'cycle_malformed',
          'startDate': 'invalid-date',
          'endDate': 'also-invalid',
        };
        final cycleMalformed = Cycle.fromMap(malformedMap);
        expect(cycleMalformed.startDate, DateTime(1970, 1, 1));
        expect(cycleMalformed.endDate, DateTime(1970, 1, 1));
      },
    );

    test('preserves properties through toMap and fromMap roundtrip', () {
      final original = Cycle(
        id: 'cycle_roundtrip',
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30),
        bipCodes: ['BIP-A', 'BIP-B'],
        dailyEntries: {
          '2026-04-01': DailyEntry(
            date: DateTime(2026, 4, 1),
            resolvedVdrsCode: '2W',
            stampType: StampType.whiteBaby,
            observations: const [],
            painLevel: 0.0,
            painTypes: const [],
            comments: '',
          ),
        },
      );

      final map = original.toMap();
      final restored = Cycle.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
      expect(restored.bipCodes, original.bipCodes);
      expect(restored.dailyEntries.length, 1);
      expect(restored.dailyEntries['2026-04-01']?.date, DateTime(2026, 4, 1));
      expect(restored.dailyEntries['2026-04-01']?.resolvedVdrsCode, '2W');
    });
  });

  group('DailyEntry Deserialization Tests', () {
    test('correctly parses valid date strings for date', () {
      final map = {
        'date': '2026-03-15',
        'resolvedVdrsCode': '4K',
        'stampType': 'green',
        'observations': [],
        'painLevel': 2.0,
        'painTypes': ['Headache'],
        'comments': 'Test entry',
        'peakDayLabel': 'P',
      };

      final entry = DailyEntry.fromMap(map);
      expect(entry.date, DateTime(2026, 3, 15));
      expect(entry.resolvedVdrsCode, '4K');
      expect(entry.stampType, StampType.green);
      expect(entry.painLevel, 2.0);
      expect(entry.painTypes, ['Headache']);
      expect(entry.comments, 'Test entry');
      expect(entry.peakDayLabel, 'P');
    });

    test(
      'gracefully handles null, missing, and non-string values for date',
      () {
        // Null date
        final nullMap = {'date': null, 'resolvedVdrsCode': ''};
        final entryNull = DailyEntry.fromMap(nullMap);
        expect(entryNull.date, DateTime(1970, 1, 1));

        // Missing date
        final missingMap = {'resolvedVdrsCode': ''};
        final entryMissing = DailyEntry.fromMap(missingMap);
        expect(entryMissing.date, DateTime(1970, 1, 1));

        // Non-string / integer value
        final nonStringMap = {'date': 20260315, 'resolvedVdrsCode': ''};
        final entryNonString = DailyEntry.fromMap(nonStringMap);
        expect(entryNonString.date, isNotNull);

        // Malformed / invalid date string
        final malformedMap = {
          'date': 'not-a-valid-date',
          'resolvedVdrsCode': '',
        };
        final entryMalformed = DailyEntry.fromMap(malformedMap);
        expect(entryMalformed.date, DateTime(1970, 1, 1));
      },
    );

    test('preserves properties through toMap and fromMap roundtrip', () {
      final original = DailyEntry(
        date: DateTime(2026, 5, 10),
        resolvedVdrsCode: '8CX1',
        stampType: StampType.whiteBaby,
        observations: [],
        painLevel: 3.5,
        painTypes: ['Cramps'],
        comments: 'Cycle day 10',
        peakDayLabel: 'P+3',
      );

      final map = original.toMap();
      final restored = DailyEntry.fromMap(map);

      expect(restored.date, original.date);
      expect(restored.resolvedVdrsCode, original.resolvedVdrsCode);
      expect(restored.stampType, original.stampType);
      expect(restored.painLevel, original.painLevel);
      expect(restored.painTypes, original.painTypes);
      expect(restored.comments, original.comments);
      expect(restored.peakDayLabel, original.peakDayLabel);
    });
  });
}
