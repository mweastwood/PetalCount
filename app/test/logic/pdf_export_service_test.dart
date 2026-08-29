import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

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
        expect(pdfText, contains('FertilityCare'));
        expect(pdfText, contains('Chart'));
        expect(pdfText, contains('Generated'));
        expect(pdfText, contains('on:'));
        expect(pdfText, contains('Legend'));
        expect(pdfText, contains('Bleeding'));
        expect(pdfText, contains('Infertile'));
        expect(pdfText, contains('Fertile'));
        expect(pdfText, isNot(contains('Cycle Starting:')));
        expect(pdfText, isNot(contains('Daily Notes:')));
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

        final emptyBytes = await PdfExportService.generatePdfBytes([]);
        final bytes = await PdfExportService.generatePdfBytes([cycle]);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 4), equals(pdfMagicBytes));
        expect(bytes.length, greaterThan(emptyBytes.length));

        final pdfText = _extractPdfText(bytes);
        expect(pdfText, contains('Creighton'));
        expect(pdfText, contains('FertilityCare'));
        expect(pdfText, contains('Chart'));
        expect(pdfText, contains('2026-06-01'));
        expect(pdfText, contains('6C'));
        expect(pdfText, contains('Period'));
        expect(pdfText, contains('start'));
        expect(pdfText, contains('Daily'));
        expect(pdfText, contains('Notes:'));
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
        expect(pdfText, contains('6C'));
        expect(pdfText, contains('2026-07-01'));
        expect(pdfText, contains('8C'));
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
        expect(pdfText, contains('6C'));
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
      'generatePdfBytes produces valid PDF bytes for extended cycle exceeding 35 days (45 days)',
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
        expect(pdfText, contains('2'));
        expect(pdfText, contains('Extended'));
        expect(pdfText, contains('comment'));
        expect(pdfText, contains('day'));
        expect(pdfText, contains('41'));
        expect(pdfText, contains('45'));
      },
    );

    test(
      'generatePdfBytes produces valid PDF bytes for multi-row cycle (75 days spanning 3 rows)',
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
        expect(pdfText, contains('None'));
        expect(pdfText, contains('75'));
        expect(pdfText, contains('Creighton'));
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
