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
        final cycle = Cycle(
          id: '2026-06-01',
          startDate: start,
          bipCodes: const ['6-C'],
          dailyEntries: {
            '2026-06-01': DailyEntry(
              date: start,
              resolvedVdrsCode: 'H',
              stampType: StampType.red,
              observations: [],
              painLevel: 0,
              painTypes: [],
              comments: 'Period start',
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
          bipCodes: const ['6-C'],
          dailyEntries: {},
        );

        final cycle2 = Cycle(
          id: '2026-07-01',
          startDate: DateTime(2026, 7, 1),
          bipCodes: const ['8-C'],
          dailyEntries: {},
        );

        final bytes = await PdfExportService.generatePdfBytes([cycle1, cycle2]);
        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(1000));
      },
    );
  });
}
