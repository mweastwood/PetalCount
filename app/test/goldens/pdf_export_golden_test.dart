import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/logic.dart';

import '../helpers/pdf_rasterizer.dart';

void main() {
  final testDate = DateTime(2026, 6, 1);
  final bool canRasterize = PdfRasterizer.isSupported;

  group('PDF Export Golden Tests', () {
    testGoldens(
      'Empty cycles PDF matches golden',
      (tester) async {
      tester.view.physicalSize = const Size(1100, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final pdfBytes = await PdfExportService.generatePdfBytes(
        [],
        generatedAt: testDate,
      );

      final pages = PdfRasterizer.rasterizeSync(pdfBytes, dpi: 100);
      expect(pages, isNotEmpty);

      final imageWidget = Image.memory(pages.first, gaplessPlayback: true);

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
        await precacheImage(MemoryImage(pages.first), imageElement);
      });
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'pdf_empty_cycles');
    }, skip: !canRasterize);

    testGoldens(
      'Single cycle with stamps and notes PDF matches golden',
      (tester) async {
      tester.view.physicalSize = const Size(1100, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Day 3: Dry (Green stamp)
      final day3Date = cycleStart.addCalendarDays(2);
      entries[day3Date.dateKey] = DailyEntry(
        date: day3Date,
        stampType: StampType.green,
        peakDayLabel: null,
        resolvedVdrsCode: '2',
        painLevel: 0,
        painTypes: [],
        comments: '',
        observations: [
          Observation(
            id: '3',
            timestamp: day3Date,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            intercourse: true,
            userId: 'test',
          ),
        ],
      );

      // Day 4: Mucus / Fertile (White Baby stamp)
      final day4Date = cycleStart.addCalendarDays(3);
      entries[day4Date.dateKey] = DailyEntry(
        date: day4Date,
        stampType: StampType.whiteBaby,
        peakDayLabel: null,
        resolvedVdrsCode: '10WLK',
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
        ],
      );

      // Day 5: Peak Day (P)
      final day5Date = cycleStart.addCalendarDays(4);
      entries[day5Date.dateKey] = DailyEntry(
        date: day5Date,
        stampType: StampType.whiteBaby,
        peakDayLabel: 'P',
        resolvedVdrsCode: '10KL',
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

      // Day 6: Post-Peak Day 1 (Green baby stamp)
      final day6Date = cycleStart.addCalendarDays(5);
      entries[day6Date.dateKey] = DailyEntry(
        date: day6Date,
        stampType: StampType.greenBaby,
        peakDayLabel: '1',
        resolvedVdrsCode: '2',
        painLevel: 0,
        painTypes: [],
        comments: '',
        observations: [
          Observation(
            id: '6',
            timestamp: day6Date,
            sensation: Sensation.dry,
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
      expect(pages, isNotEmpty);

      final imageWidget = Image.memory(pages.first, gaplessPlayback: true);

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
        await precacheImage(MemoryImage(pages.first), imageElement);
      });
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'pdf_single_cycle');
    }, skip: !canRasterize);

    testGoldens(
      'Extended multi-row cycle PDF matches golden',
      (tester) async {
      tester.view.physicalSize = const Size(1100, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
          resolvedVdrsCode: i < 5 ? 'H' : (i % 2 == 0 ? '0' : '8C'),
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
      expect(pages, isNotEmpty);

      final imageWidget = Image.memory(pages.first, gaplessPlayback: true);

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
        await precacheImage(MemoryImage(pages.first), imageElement);
      });
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'pdf_extended_cycle');
    }, skip: !canRasterize);
  });
}
