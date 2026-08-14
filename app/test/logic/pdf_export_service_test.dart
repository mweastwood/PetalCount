import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  group('PdfExportService Unit Tests', () {
    test(
      'generatePdfBytes produces non-empty PDF bytes for empty cycles list',
      () async {
        final bytes = await PdfExportService.generatePdfBytes([]);
        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(100));
      },
    );

    test(
      'generatePdfBytes produces valid PDF bytes for single cycle',
      () async {
        final start = DateTime(2026, 6, 1);
        final obs = Observation(
          id: '1',
          timestamp: start,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.heavy,
          comment: 'Period start',
          userId: 'test',
        );
        final cycle = Cycle(
          id: '2026-06-01',
          startDate: start,
          bipCodes: const ['6C'],
          dailyEntries: {
            '2026-06-01': CreightonLogic.resolveDailyEntry(
              date: start,
              observations: [obs],
            ),
          },
        );

        final bytes = await PdfExportService.generatePdfBytes([cycle]);
        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(500));
      },
    );

    test(
      'generatePdfBytes produces valid PDF bytes for multiple cycles',
      () async {
        final cycle1 = Cycle(
          id: '2026-06-01',
          startDate: DateTime(2026, 6, 1),
          bipCodes: const ['6C'],
          dailyEntries: {},
        );

        final cycle2 = Cycle(
          id: '2026-07-01',
          startDate: DateTime(2026, 7, 1),
          bipCodes: const ['8C'],
          dailyEntries: {},
        );

        final bytes = await PdfExportService.generatePdfBytes([cycle1, cycle2]);
        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(1000));
      },
    );
    test('generatePdfBytes produces valid PDF bytes for cycle with missing observation days', () async {
      final start = DateTime(2026, 6, 1);
      final obs1 = Observation(
        id: '1',
        timestamp: start,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        comment: 'Period start',
        userId: 'test',
      );
      final june5 = DateTime(2026, 6, 5);
      final obs5 = Observation(
        id: '5',
        timestamp: june5,
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final cycle = Cycle(
        id: '2026-06-01',
        startDate: start,
        bipCodes: const ['6C'],
        dailyEntries: {
          '2026-06-01': CreightonLogic.resolveDailyEntry(
            date: start,
            observations: [obs1],
          ),
          '2026-06-05': CreightonLogic.resolveDailyEntry(
            date: june5,
            observations: [obs5],
          ),
        },
      );

      final bytes = await PdfExportService.generatePdfBytes([cycle]);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500));
    });
  });
}
