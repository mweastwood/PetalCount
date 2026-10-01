import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/logic.dart';

import '../helpers/pdf_rasterizer.dart';

void main() {
  final testDate = DateTime(2026, 6, 1);
  final bool canRasterize = PdfRasterizer.isSupported;
  final String? skipRasterizeReason = !canRasterize
      ? 'Ghostscript (gs) or Poppler (pdftoppm) required for PDF golden tests'
      : null;

  Future<void> pumpPageImage(WidgetTester tester, Uint8List pageBytes) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final imageWidget = Image.memory(pageBytes, gaplessPlayback: true);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: imageWidget),
        ),
      ),
    );

    await tester.runAsync(() async {
      final imageElement = find.byType(Image).evaluate().first;
      await precacheImage(MemoryImage(pageBytes), imageElement);
    });
    await tester.pumpAndSettle();
  }

  group('PDF Export Golden Tests', () {
    testGoldens('Empty cycles PDF matches golden', (tester) async {
      final pdfBytes = await PdfExportService.generatePdfBytes(
        [],
        generatedAt: testDate,
      );

      final pages = PdfRasterizer.rasterizeSync(pdfBytes, dpi: 100);
      expect(pages.length, equals(1));

      await pumpPageImage(tester, pages.first);
      await screenMatchesGolden(tester, 'pdf_empty_cycles');
    }, skip: skipRasterizeReason);

    testGoldens('Single cycle with stamps and notes PDF matches golden', (
      tester,
    ) async {
      final cycleStart = DateTime(2026, 6, 1);
      final entries = <String, DailyEntry>{};

      // Day 1: Heavy Bleeding
      final day1Date = cycleStart;
      entries[day1Date.dateKey] = CreightonLogic.resolveDailyEntry(
        date: day1Date,
        observations: [
          Observation(
            id: '1',
            timestamp: day1Date,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            comment: 'Flow started',
            userId: 'test',
          ),
        ],
      );

      // Day 2: Light Bleeding + Cramp pain
      final day2Date = cycleStart.addCalendarDays(1);
      entries[day2Date.dateKey] = DailyEntry(
        date: day2Date,
        stampType: StampType.red,
        peakDayLabel: null,
        resolvedVdrsCode: 'L',
        painLevel: 2,
        painTypes: ['Cramps'],
        comments: 'Mild cramping',
        observations: [
          Observation(
            id: '2',
            timestamp: day2Date,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.light,
            painLevel: 2,
            painTypes: ['Cramps'],
            comment: 'Mild cramping',
            userId: 'test',
          ),
        ],
      );

      // Day 3: Dry (Green stamp) with Intercourse
      final day3Date = cycleStart.addCalendarDays(2);
      entries[day3Date.dateKey] = DailyEntry(
        date: day3Date,
        stampType: StampType.green,
        peakDayLabel: null,
        resolvedVdrsCode: '2 x1 I',
        painLevel: 0,
        painTypes: [],
        comments: '',
        observations: [
          Observation(
            id: '3',
            timestamp: day3Date,
            sensation: Sensation.damp,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            intercourse: true,
            userId: 'test',
          ),
        ],
      );

      // Day 4: Mucus / Fertile (White Baby stamp) - Twice (x2)
      final day4Date = cycleStart.addCalendarDays(3);
      entries[day4Date.dateKey] = DailyEntry(
        date: day4Date,
        stampType: StampType.whiteBaby,
        peakDayLabel: null,
        resolvedVdrsCode: '10WLK x2',
        painLevel: 0,
        painTypes: [],
        comments: 'Clear stretchy',
        observations: [
          Observation(
            id: '4',
            timestamp: day4Date,
            sensation: Sensation.wet,
            stretch: Stretch.stretchy,
            colors: [MucusColor.clear],
            consistencies: [Consistency.lubricative],
            bleeding: Bleeding.none,
            comment: 'Clear stretchy',
            userId: 'test',
          ),
          Observation(
            id: '4b',
            timestamp: day4Date.add(const Duration(hours: 4)),
            sensation: Sensation.wet,
            stretch: Stretch.stretchy,
            colors: [MucusColor.clear],
            consistencies: [Consistency.lubricative],
            bleeding: Bleeding.none,
            userId: 'test',
          ),
        ],
      );

      // Day 5: Peak Day (P) - Once (x1)
      final day5Date = cycleStart.addCalendarDays(4);
      entries[day5Date.dateKey] = DailyEntry(
        date: day5Date,
        stampType: StampType.whiteBaby,
        peakDayLabel: 'P',
        resolvedVdrsCode: '10KL x1',
        painLevel: 1,
        painTypes: ['Ovulation'],
        comments: 'Peak day',
        observations: [
          Observation(
            id: '5',
            timestamp: day5Date,
            sensation: Sensation.wet,
            stretch: Stretch.stretchy,
            colors: [MucusColor.clear],
            consistencies: [Consistency.lubricative],
            bleeding: Bleeding.none,
            painLevel: 1,
            painTypes: ['Ovulation'],
            comment: 'Peak day',
            userId: 'test',
          ),
        ],
      );

      // Day 6: Post-Peak Day 1 (Green baby stamp) - Once (x1)
      final day6Date = cycleStart.addCalendarDays(5);
      entries[day6Date.dateKey] = DailyEntry(
        date: day6Date,
        stampType: StampType.greenBaby,
        peakDayLabel: '1',
        resolvedVdrsCode: '2 x1',
        painLevel: 0,
        painTypes: [],
        comments: '',
        observations: [
          Observation(
            id: '6',
            timestamp: day6Date,
            sensation: Sensation.damp,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            userId: 'test',
          ),
        ],
      );

      final cycle = Cycle(
        id: 'cycle_golden_1',
        startDate: cycleStart,
        bipCodes: const ['6C'],
        dailyEntries: entries,
      );

      final pdfBytes = await PdfExportService.generatePdfBytes([
        cycle,
      ], generatedAt: testDate);

      final pages = PdfRasterizer.rasterizeSync(pdfBytes, dpi: 100);
      expect(pages.length, equals(1));

      await pumpPageImage(tester, pages.first);
      await screenMatchesGolden(tester, 'pdf_single_cycle');
    }, skip: skipRasterizeReason);

    testGoldens('Extended multi-row cycle PDF matches golden', (tester) async {
      final cycleStart = DateTime(2026, 6, 1);
      final entries = <String, DailyEntry>{};

      for (int i = 0; i < 42; i++) {
        final date = cycleStart.addCalendarDays(i);
        entries[date.dateKey] = DailyEntry(
          date: date,
          stampType: i < 5
              ? StampType.red
              : (i % 2 == 0 ? StampType.green : StampType.whiteBaby),
          peakDayLabel: i == 14 ? 'P' : (i == 15 ? '1' : null),
          resolvedVdrsCode: i < 5 ? 'H' : (i % 2 == 0 ? '0 x1' : '8C x1'),
          painLevel: 0,
          painTypes: [],
          comments: i == 41 ? 'Cycle conclusion note' : '',
          observations: [],
        );
      }

      final cycle = Cycle(
        id: 'cycle_golden_extended',
        startDate: cycleStart,
        bipCodes: const ['2'],
        dailyEntries: entries,
      );

      final pdfBytes = await PdfExportService.generatePdfBytes([
        cycle,
      ], generatedAt: testDate);

      final pages = PdfRasterizer.rasterizeSync(pdfBytes, dpi: 100);
      expect(pages.length, equals(1));

      await pumpPageImage(tester, pages.first);
      await screenMatchesGolden(tester, 'pdf_extended_cycle');
    }, skip: skipRasterizeReason);

    testGoldens('Multiple cycles PDF matches golden (one cycle per page)', (
      tester,
    ) async {
      // Cycle 1: June 1, 2026 (28-day cycle)
      final cycle1Start = DateTime(2026, 6, 1);
      final entries1 = <String, DailyEntry>{};
      for (int i = 0; i < 28; i++) {
        final date = cycle1Start.addCalendarDays(i);
        final dayNum = i + 1;
        StampType stamp;
        String? peak;
        String vdrs;
        double pain = 0;
        List<String> painTypes = [];
        String comment = '';

        if (dayNum <= 4) {
          stamp = StampType.red;
          vdrs = 'H';
          if (dayNum == 2) {
            pain = 2;
            painTypes = ['Cramps'];
            comment = 'Cycle 1 cramps';
          }
        } else if (dayNum <= 9) {
          stamp = StampType.green;
          vdrs = '2 x1';
        } else if (dayNum <= 13) {
          stamp = StampType.whiteBaby;
          vdrs = '10WLK x1';
        } else if (dayNum == 14) {
          stamp = StampType.whiteBaby;
          peak = 'P';
          vdrs = '10KL x1';
          pain = 1;
          painTypes = ['Ovulation'];
        } else if (dayNum == 15) {
          stamp = StampType.greenBaby;
          peak = '1';
          vdrs = '2 x1';
        } else if (dayNum == 16) {
          stamp = StampType.greenBaby;
          peak = '2';
          vdrs = '2 x1';
        } else if (dayNum == 17) {
          stamp = StampType.greenBaby;
          peak = '3';
          vdrs = '2 x1';
        } else {
          stamp = StampType.green;
          vdrs = '2 x1';
        }

        entries1[date.dateKey] = DailyEntry(
          date: date,
          stampType: stamp,
          peakDayLabel: peak,
          resolvedVdrsCode: vdrs,
          painLevel: pain,
          painTypes: painTypes,
          comments: comment,
          observations: [],
        );
      }

      final cycle1 = Cycle(
        id: 'cycle_multi_1',
        startDate: cycle1Start,
        bipCodes: const ['6C'],
        dailyEntries: entries1,
      );

      // Cycle 2: June 29, 2026 (24-day cycle)
      final cycle2Start = DateTime(2026, 6, 29);
      final entries2 = <String, DailyEntry>{};
      for (int i = 0; i < 24; i++) {
        final date = cycle2Start.addCalendarDays(i);
        final dayNum = i + 1;
        StampType stamp;
        String? peak;
        String vdrs;
        String comment = '';

        if (dayNum <= 3) {
          stamp = StampType.red;
          vdrs = 'H';
          if (dayNum == 1) {
            comment = 'Cycle 2 started';
          }
        } else if (dayNum <= 7) {
          stamp = StampType.green;
          vdrs = '2 x1';
        } else if (dayNum <= 10) {
          stamp = StampType.whiteBaby;
          vdrs = '10WLK x1';
        } else if (dayNum == 11) {
          stamp = StampType.whiteBaby;
          peak = 'P';
          vdrs = '10KL x1';
        } else if (dayNum == 12) {
          stamp = StampType.greenBaby;
          peak = '1';
          vdrs = '2 x1';
        } else if (dayNum == 13) {
          stamp = StampType.greenBaby;
          peak = '2';
          vdrs = '2 x1';
        } else if (dayNum == 14) {
          stamp = StampType.greenBaby;
          peak = '3';
          vdrs = '2 x1';
        } else {
          stamp = StampType.green;
          vdrs = '2 x1';
        }

        entries2[date.dateKey] = DailyEntry(
          date: date,
          stampType: stamp,
          peakDayLabel: peak,
          resolvedVdrsCode: vdrs,
          painLevel: 0,
          painTypes: [],
          comments: comment,
          observations: [],
        );
      }

      final cycle2 = Cycle(
        id: 'cycle_multi_2',
        startDate: cycle2Start,
        bipCodes: const ['8C'],
        dailyEntries: entries2,
      );

      final pdfBytes = await PdfExportService.generatePdfBytes([
        cycle1,
        cycle2,
      ], generatedAt: testDate);

      final pages = PdfRasterizer.rasterizeSync(pdfBytes, dpi: 100);
      expect(pages.length, equals(2));

      // Page 1: Cycle 1
      await pumpPageImage(tester, pages[0]);
      await screenMatchesGolden(tester, 'pdf_multi_cycle_page_1');

      // Page 2: Cycle 2
      await pumpPageImage(tester, pages[1]);
      await screenMatchesGolden(tester, 'pdf_multi_cycle_page_2');
    }, skip: skipRasterizeReason);
  });
}
