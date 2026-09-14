import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/supplements/daily_intake_tab.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    await Services.db.resetDefaultSupplements();
  });

  group('DailyIntakeTab Tests', () {
    testWidgets('renders daily intake list, progress, and date navigator', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final supps = await Services.db.streamSupplements().first;
      final date = DateTime(2026, 8, 25);
      final log = DailySupplementLog(date: date, takenDoses: {});

      int? dateOffset;
      bool todayPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyIntakeTab(
              selectedDate: date,
              cycleDay: 6,
              daysPastPeak: null,
              hasPeakOccurred: false,
              supplements: supps,
              dailyLog: log,
              onDateChanged: (offset) => dateOffset = offset,
              onGoToToday: () => todayPressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aug 25, 2026'), findsOneWidget);
      expect(find.text('Cycle Day 6'), findsOneWidget);
      expect(find.text('Daily Adherence'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous Day'));
      expect(dateOffset, equals(-1));

      await tester.tap(find.byTooltip('Next Day'));
      expect(dateOffset, equals(1));

      await tester.tap(find.byTooltip('Go to Today'));
      expect(todayPressed, isTrue);
    });

    testWidgets(
      'displays post-peak and peak day status correctly in navigator',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final supps = await Services.db.streamSupplements().first;
        final date = DateTime(2026, 8, 25);
        final log = DailySupplementLog(date: date, takenDoses: {});

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DailyIntakeTab(
                selectedDate: date,
                cycleDay: 16,
                daysPastPeak: 2,
                hasPeakOccurred: true,
                supplements: supps,
                dailyLog: log,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cycle Day 16 • Post-Peak (P+2)'), findsOneWidget);
      },
    );

    testWidgets('toggles dose adherence callback when dose card tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final supps = await Services.db.streamSupplements().first;
      final date = DateTime(2026, 8, 25);
      final log = DailySupplementLog(date: date, takenDoses: {});

      SupplementItem? toggledItem;
      SupplementTimeOfDay? toggledTime;
      bool? toggledTaken;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyIntakeTab(
              selectedDate: date,
              cycleDay: 6,
              daysPastPeak: null,
              hasPeakOccurred: false,
              supplements: supps,
              dailyLog: log,
              onToggleDose: (item, time, taken) {
                toggledItem = item;
                toggledTime = time;
                toggledTaken = taken;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      expect(toggledItem, isNotNull);
      expect(toggledTime, equals(SupplementTimeOfDay.morning));
      expect(toggledTaken, isTrue);
    });

    testWidgets(
      'toggles dose and calls Services.db.logSupplementDose when onToggleDose is null',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final spyDb = _SpyDatabaseService();
        Services.db = spyDb;
        await Services.db.resetDefaultSupplements();

        final supps = await Services.db.streamSupplements().first;
        final date = DateTime(2026, 8, 25);
        final log = DailySupplementLog(
          date: date,
          takenDoses: {
            supps.first.id: [SupplementTimeOfDay.morning],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DailyIntakeTab(
                selectedDate: date,
                cycleDay: 6,
                daysPastPeak: null,
                hasPeakOccurred: false,
                supplements: supps,
                dailyLog: log,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When currently taken, tapping card toggles to not taken (false)
        final firstCardInkWell = find.ancestor(
          of: find.byType(Checkbox).first,
          matching: find.byType(InkWell),
        );
        await tester.tap(firstCardInkWell);
        await tester.pumpAndSettle();

        expect(spyDb.lastLoggedDate, equals(date));
        expect(spyDb.lastLoggedSupplementId, equals(supps.first.id));
        expect(spyDb.lastLoggedTimeOfDay, equals(SupplementTimeOfDay.morning));
        expect(spyDb.lastLoggedTaken, isFalse);

        // When untaken, tapping checkbox toggles to taken (true)
        final emptyLog = DailySupplementLog(date: date, takenDoses: {});
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DailyIntakeTab(
                selectedDate: date,
                cycleDay: 6,
                daysPastPeak: null,
                hasPeakOccurred: false,
                supplements: supps,
                dailyLog: emptyLog,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final firstCheckbox = find.byType(Checkbox).first;
        await tester.tap(firstCheckbox);
        await tester.pumpAndSettle();

        expect(spyDb.lastLoggedTaken, isTrue);
      },
    );

    testWidgets(
      'displays SnackBar error feedback when Services.db.logSupplementDose throws',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final spyDb = _SpyDatabaseService();
        spyDb.shouldThrowOnLog = true;
        Services.db = spyDb;
        await Services.db.resetDefaultSupplements();

        final supps = await Services.db.streamSupplements().first;
        final date = DateTime(2026, 8, 25);
        final log = DailySupplementLog(date: date, takenDoses: {});

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DailyIntakeTab(
                selectedDate: date,
                cycleDay: 6,
                daysPastPeak: null,
                hasPeakOccurred: false,
                supplements: supps,
                dailyLog: log,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final firstCheckbox = find.byType(Checkbox).first;
        await tester.tap(firstCheckbox);
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text(
            'Failed to update supplement dose: Exception: Database write failure',
          ),
          findsOneWidget,
        );
      },
    );
  });
}

class _SpyDatabaseService extends InMemoryDatabaseService {
  DateTime? lastLoggedDate;
  String? lastLoggedSupplementId;
  SupplementTimeOfDay? lastLoggedTimeOfDay;
  bool? lastLoggedTaken;
  bool shouldThrowOnLog = false;

  @override
  Future<void> logSupplementDose({
    required DateTime date,
    required String supplementId,
    required SupplementTimeOfDay timeOfDay,
    required bool taken,
  }) async {
    if (shouldThrowOnLog) {
      throw Exception('Database write failure');
    }
    lastLoggedDate = date;
    lastLoggedSupplementId = supplementId;
    lastLoggedTimeOfDay = timeOfDay;
    lastLoggedTaken = taken;
    await super.logSupplementDose(
      date: date,
      supplementId: supplementId,
      timeOfDay: timeOfDay,
      taken: taken,
    );
  }
}
