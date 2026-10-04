import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/theme/creighton_theme.dart';

void main() {
  group('PdfExportService Unit Tests', () {
    const pdfMagicBytes = [0x25, 0x50, 0x44, 0x46]; // '%PDF'

    test(
      'generatePdfBytes produces valid PDF bytes for empty cycles list',
      () async {
        final bytes = await PdfExportService.generatePdfBytes([]);
        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 4), equals(pdfMagicBytes));

        final pdfText = _extractPdfText(bytes);
        expect(pdfText, contains('Creighton'));
        expect(pdfText, contains('Model'));
        expect(pdfText, contains('Chart'));
        expect(pdfText, contains('Generated'));
        expect(pdfText, contains('on:'));
        expect(pdfText, isNot(contains('FertilityCare')));
        expect(pdfText, isNot(contains('Legend')));
        expect(pdfText, isNot(contains('Cycle Starting:')));
        expect(pdfText, isNot(contains('Daily Notes:')));
      },
    );

    test('generatePdfBytes formats custom generatedAt in PDF header', () async {
      final customDate = DateTime(2025, 12, 25);
      final bytes = await PdfExportService.generatePdfBytes(
        [],
        generatedAt: customDate,
      );
      final pdfText = _extractPdfText(bytes);
      expect(pdfText, contains('Generated'));
      expect(pdfText, contains('2025-12-25'));
    });

    test('generatePdfBytes formats Peak and +1, +2, +3 labels', () async {
      final start = DateTime(2026, 6, 1);
      final entries = <String, DailyEntry>{
        '2026-06-01': DailyEntry(
          date: start,
          stampType: StampType.whiteBaby,
          resolvedVdrsCode: '10KL',
          peakDayLabel: 'P',
          painLevel: 0,
          painTypes: [],
          comments: '',
          observations: [],
        ),
        '2026-06-02': DailyEntry(
          date: start.addCalendarDays(1),
          stampType: StampType.greenBaby,
          resolvedVdrsCode: '2',
          peakDayLabel: '1',
          painLevel: 0,
          painTypes: [],
          comments: '',
          observations: [],
        ),
        '2026-06-03': DailyEntry(
          date: start.addCalendarDays(2),
          stampType: StampType.greenBaby,
          resolvedVdrsCode: '2',
          peakDayLabel: '2',
          painLevel: 0,
          painTypes: [],
          comments: '',
          observations: [],
        ),
        '2026-06-04': DailyEntry(
          date: start.addCalendarDays(3),
          stampType: StampType.greenBaby,
          resolvedVdrsCode: '2',
          peakDayLabel: '3',
          painLevel: 0,
          painTypes: [],
          comments: '',
          observations: [],
        ),
      };

      final cycle = Cycle(
        id: 'cycle_peak',
        startDate: start,
        bipCodes: const [],
        dailyEntries: entries,
      );

      final bytes = await PdfExportService.generatePdfBytes([cycle]);
      final pdfText = _extractPdfText(bytes);
      expect(pdfText, contains('Peak'));
      expect(pdfText, contains('+1'));
      expect(pdfText, contains('+2'));
      expect(pdfText, contains('+3'));
    });

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
          painLevel: 2,
          painTypes: ['Cramps'],
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

        final emptyBytes = await PdfExportService.generatePdfBytes([]);
        final bytes = await PdfExportService.generatePdfBytes([cycle]);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 4), equals(pdfMagicBytes));
        expect(bytes.length, greaterThan(emptyBytes.length));

        final pdfText = _extractPdfText(bytes);
        expect(pdfText, contains('Creighton'));
        expect(pdfText, contains('Model'));
        expect(pdfText, contains('Chart'));
        expect(pdfText, contains('Cycle'));
        expect(pdfText, contains('Starting:'));
        expect(pdfText, contains('2026-06-01'));
        expect(pdfText, isNot(contains('BIP:')));
        expect(pdfText, contains('Period'));
        expect(pdfText, contains('start'));
        expect(pdfText, contains('Cramps'));
        expect(pdfText, contains('H'));
        expect(pdfText, contains('Jun'));
        expect(pdfText, contains('01'));
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

        final singleBytes = await PdfExportService.generatePdfBytes([cycle1]);
        final bytes = await PdfExportService.generatePdfBytes([cycle1, cycle2]);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 4), equals(pdfMagicBytes));
        expect(bytes.length, greaterThan(singleBytes.length));

        final pdfText = _extractPdfText(bytes);
        expect(pdfText, contains('2026-06-01'));
        expect(pdfText, contains('2026-07-01'));
        expect(pdfText, isNot(contains('BIP:')));
      },
    );

    test(
      'generatePdfBytes produces valid PDF bytes for cycle with missing observation days',
      () async {
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
        expect(bytes.sublist(0, 4), equals(pdfMagicBytes));

        final pdfText = _extractPdfText(bytes);
        expect(pdfText, contains('2026-06-01'));
        expect(pdfText, isNot(contains('BIP:')));
        expect(pdfText, contains('Period'));
        expect(pdfText, contains('start'));
        expect(pdfText, contains('?'));
        expect(pdfText, contains('H'));
        expect(pdfText, contains('10WLK'));
        expect(pdfText, contains('Jun'));
        expect(pdfText, contains('01'));
        expect(pdfText, contains('05'));
      },
    );

    test(
      'generatePdfBytes produces valid PDF bytes for extended cycle exceeding 14 days (45 days)',
      () async {
        final start = DateTime(2026, 1, 1);
        final entries = <String, DailyEntry>{};

        for (int i = 0; i < 45; i++) {
          final date = start.addCalendarDays(i);
          final obs = Observation(
            id: 'obs_$i',
            timestamp: date,
            sensation: i % 2 == 0 ? Sensation.dry : Sensation.wet,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: i == 0 ? Bleeding.heavy : Bleeding.none,
            comment: i == 40 ? 'Extended cycle comment day 41' : '',
            userId: 'test',
          );
          entries[date.dateKey] = CreightonLogic.resolveDailyEntry(
            date: date,
            observations: [obs],
          );
        }

        final cycle = Cycle(
          id: '2026-01-01',
          startDate: start,
          bipCodes: const ['2'],
          dailyEntries: entries,
        );

        final bytes = await PdfExportService.generatePdfBytes([cycle]);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 4), equals(pdfMagicBytes));

        final pdfText = _extractPdfText(bytes);
        expect(pdfText, contains('2026-01-01'));
        expect(pdfText, contains('Extended'));
        expect(pdfText, contains('comment'));
        expect(pdfText, contains('day'));
        expect(pdfText, contains('41'));
        expect(pdfText, contains('45'));
      },
    );

    test(
      'generatePdfBytes produces valid PDF bytes for multi-row cycle (75 days spanning multiple 14-day rows)',
      () async {
        final start = DateTime(2026, 1, 1);
        final entries = <String, DailyEntry>{};

        for (int i = 0; i < 75; i++) {
          final date = start.addCalendarDays(i);
          final obs = Observation(
            id: 'obs_$i',
            timestamp: date,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            userId: 'test',
          );
          entries[date.dateKey] = CreightonLogic.resolveDailyEntry(
            date: date,
            observations: [obs],
          );
        }

        final cycle = Cycle(
          id: '2026-01-01',
          startDate: start,
          bipCodes: const [],
          dailyEntries: entries,
        );

        final bytes = await PdfExportService.generatePdfBytes([cycle]);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 4), equals(pdfMagicBytes));

        final pdfText = _extractPdfText(bytes);
        expect(pdfText, contains('2026-01-01'));
        expect(pdfText, contains('75'));
        expect(pdfText, contains('Creighton'));
      },
    );

    test('formatObservationCode handles various counts and codes properly', () {
      final date = DateTime(2026, 6, 1);

      // null entry
      expect(PdfExportService.formatObservationCode(null), '?');

      // Empty code
      expect(
        PdfExportService.formatObservationCode(
          DailyEntry(
            date: date,
            resolvedVdrsCode: '',
            stampType: StampType.green,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ),
        '',
      );

      // Menstrual flow without frequency
      expect(
        PdfExportService.formatObservationCode(
          DailyEntry(
            date: date,
            resolvedVdrsCode: 'H',
            stampType: StampType.red,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ),
        'H',
      );
      expect(
        PdfExportService.formatObservationCode(
          DailyEntry(
            date: date,
            resolvedVdrsCode: 'L',
            stampType: StampType.red,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ),
        'L',
      );

      // Already has frequency
      expect(
        PdfExportService.formatObservationCode(
          DailyEntry(
            date: date,
            resolvedVdrsCode: '10K x2 I',
            stampType: StampType.whiteBaby,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ),
        '10K x2 I',
      );
      expect(
        PdfExportService.formatObservationCode(
          DailyEntry(
            date: date,
            resolvedVdrsCode: '0 AD',
            stampType: StampType.green,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ),
        '0 AD',
      );

      // Single observation without frequency gets x1
      expect(
        PdfExportService.formatObservationCode(
          DailyEntry(
            date: date,
            resolvedVdrsCode: '10WLK',
            stampType: StampType.whiteBaby,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ),
        '10WLK x1',
      );

      // Single observation with intercourse
      expect(
        PdfExportService.formatObservationCode(
          DailyEntry(
            date: date,
            resolvedVdrsCode: '2 I',
            stampType: StampType.green,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ),
        '2 x1 I',
      );

      // Count matching observations from entry.observations
      final obsA = Observation(
        id: '1',
        timestamp: date,
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: const [MucusColor.clear],
        consistencies: const [],
        bleeding: Bleeding.none,
        userId: 'u',
      );
      final obsB = Observation(
        id: '2',
        timestamp: date,
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: const [MucusColor.clear],
        consistencies: const [],
        bleeding: Bleeding.none,
        userId: 'u',
      );
      final obsDry = Observation(
        id: '3',
        timestamp: date,
        sensation: Sensation.damp,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.none,
        userId: 'u',
      );

      // 2 matching mucus observations -> 10K x2
      expect(
        PdfExportService.formatObservationCode(
          DailyEntry(
            date: date,
            resolvedVdrsCode: '10K',
            stampType: StampType.whiteBaby,
            observations: [obsDry, obsA, obsB],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ),
        '10K x2',
      );
    });

    test(
      'derives baby symbol size from stamp cell height and shared fraction',
      () {
        expect(CreightonTheme.babyIconFraction, equals(0.75));
        expect(PdfExportService.stampCellHeight, equals(38.0));
        expect(PdfExportService.stampCellWidth, equals(48.0));
        expect(
          PdfExportService.babySymbolSize,
          equals(
            PdfExportService.stampCellHeight * CreightonTheme.babyIconFraction,
          ),
        );
        expect(PdfExportService.babySymbolSize, equals(28.5));

        final defaultBabyWidget = PdfExportService.buildBabySymbol(
          PdfColors.black,
        );
        expect(defaultBabyWidget, isA<pw.SvgImage>());
        final defaultSvg = defaultBabyWidget as pw.SvgImage;
        expect(defaultSvg.width, equals(28.5));
        expect(defaultSvg.height, equals(28.5));

        final customBabyWidget = PdfExportService.buildBabySymbol(
          PdfColors.white,
          size: 20.0,
        );
        expect(customBabyWidget, isA<pw.SvgImage>());
        final customSvg = customBabyWidget as pw.SvgImage;
        expect(customSvg.width, equals(20.0));
        expect(customSvg.height, equals(20.0));
      },
    );

    test(
      'stamp cell Stack children order ensures cycle day number renders on top of baby icon',
      () {
        final start = DateTime(2026, 6, 1);
        final cycle = Cycle(
          id: 'test_cycle',
          startDate: start,
          dailyEntries: {
            '2026-06-01': DailyEntry(
              date: start,
              stampType: StampType.whiteBaby,
              resolvedVdrsCode: '10KL',
              painLevel: 0,
              painTypes: [],
              comments: '',
              observations: const [],
            ),
            '2026-06-02': DailyEntry(
              date: start.addCalendarDays(1),
              stampType: StampType.greenBaby,
              resolvedVdrsCode: '2',
              painLevel: 0,
              painTypes: [],
              comments: '',
              observations: const [],
            ),
          },
        );

        // Check whiteBaby stamp cell: baby symbol at index 0, day number at index 1
        final day0Column =
            PdfExportService.buildDayColumn(cycle, 0) as pw.Container;
        final col0 = day0Column.child as pw.Column;
        final stamp0Container = col0.children[1] as pw.Container;
        final stack0 = stamp0Container.child as pw.Stack;

        expect(stack0.children.length, equals(2));
        final baby0 = stack0.children[0] as pw.Positioned;
        expect(baby0.child, isA<pw.SvgImage>());
        final num0 = stack0.children[1] as pw.Positioned;
        expect(num0.child, isA<pw.Text>());
        expect((num0.child as pw.Text).text.toPlainText(), equals('1'));

        // Check greenBaby stamp cell: baby symbol at index 0, day number at index 1
        final day1Column =
            PdfExportService.buildDayColumn(cycle, 1) as pw.Container;
        final col1 = day1Column.child as pw.Column;
        final stamp1Container = col1.children[1] as pw.Container;
        final stack1 = stamp1Container.child as pw.Stack;

        expect(stack1.children.length, equals(2));
        final baby1 = stack1.children[0] as pw.Positioned;
        expect(baby1.child, isA<pw.SvgImage>());
        final num1 = stack1.children[1] as pw.Positioned;
        expect(num1.child, isA<pw.Text>());
        expect((num1.child as pw.Text).text.toPlainText(), equals('2'));

        // Check unlogged day stamp cell: '?' at index 0, day number at index 1
        final day2Column =
            PdfExportService.buildDayColumn(cycle, 2) as pw.Container;
        final col2 = day2Column.child as pw.Column;
        final stamp2Container = col2.children[1] as pw.Container;
        final stack2 = stamp2Container.child as pw.Stack;

        expect(stack2.children.length, equals(2));
        final unloggedCenter = stack2.children[0] as pw.Center;
        expect(unloggedCenter.child, isA<pw.Text>());
        expect(
          (unloggedCenter.child as pw.Text).text.toPlainText(),
          equals('?'),
        );
        final num2 = stack2.children[1] as pw.Positioned;
        expect(num2.child, isA<pw.Text>());
        expect((num2.child as pw.Text).text.toPlainText(), equals('3'));
      },
    );
  });
}

/// Extracts decompressed stream text from the generated PDF byte array.
String _extractPdfText(List<int> bytes) {
  final buffer = StringBuffer();
  final streamHeader = ascii.encode('stream');
  final streamFooter = ascii.encode('endstream');

  int index = 0;
  while (index < bytes.length) {
    final streamStart = _indexOf(bytes, streamHeader, index);
    if (streamStart == -1) break;

    int contentStart = streamStart + streamHeader.length;
    if (contentStart < bytes.length && bytes[contentStart] == 0x0D) {
      contentStart++;
    }
    if (contentStart < bytes.length && bytes[contentStart] == 0x0A) {
      contentStart++;
    }

    final streamEnd = _indexOf(bytes, streamFooter, contentStart);
    if (streamEnd == -1) break;

    int contentEnd = streamEnd;
    if (contentEnd > contentStart && bytes[contentEnd - 1] == 0x0A) {
      contentEnd--;
    }
    if (contentEnd > contentStart && bytes[contentEnd - 1] == 0x0D) {
      contentEnd--;
    }

    final chunk = bytes.sublist(contentStart, contentEnd);
    try {
      final decompressed = zlib.decode(chunk);
      buffer.write(latin1.decode(decompressed));
    } catch (_) {
      buffer.write(latin1.decode(chunk));
    }

    index = streamEnd + streamFooter.length;
  }
  return buffer.toString();
}

int _indexOf(List<int> data, List<int> pattern, int start) {
  for (int i = start; i <= data.length - pattern.length; i++) {
    bool match = true;
    for (int j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return -1;
}
