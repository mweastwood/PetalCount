import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/add_observation_dialog.dart';
import 'package:petal_count/widgets/creighton_stamp_widget.dart';
import 'package:petal_count/widgets/daily_detail_sheet.dart';

class MockDailyDetailDatabaseService extends InMemoryDatabaseService {
  String? lastDeletedCycleId;
  DateTime? lastDeletedDate;
  String? lastDeletedObservationId;
  int deleteCallCount = 0;

  @override
  Future<void> deleteObservation({
    required String cycleId,
    required DateTime date,
    required String observationId,
  }) async {
    deleteCallCount++;
    lastDeletedCycleId = cycleId;
    lastDeletedDate = date;
    lastDeletedObservationId = observationId;
    await super.deleteObservation(
      cycleId: cycleId,
      date: date,
      observationId: observationId,
    );
  }
}

void main() {
  late MockDailyDetailDatabaseService mockDb;

  final testDate = DateTime(2026, 8, 3);
  final testCycle = Cycle(
    id: 'cycle-123',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 28),
  );

  setUp(() async {
    mockDb = MockDailyDetailDatabaseService();
    await Services.init(dbService: mockDb);
  });

  Widget buildTestWidget({
    required DailyEntry entry,
    required Cycle cycle,
    bool openAsBottomSheet = false,
  }) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      home: Scaffold(
        body: openAsBottomSheet
            ? Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          DailyDetailSheet(entry: entry, cycle: cycle),
                    ),
                    child: const Text('Open Daily Detail Sheet'),
                  ),
                ),
              )
            : SingleChildScrollView(
                child: DailyDetailSheet(entry: entry, cycle: cycle),
              ),
      ),
    );
  }

  group('DailyDetailSheet Empty State Tests', () {
    testWidgets(
      'displays placeholder text when entry has no individual observations',
      (WidgetTester tester) async {
        final entry = DailyEntry(
          date: testDate,
          resolvedVdrsCode: '0',
          stampType: StampType.green,
          observations: [],
          painLevel: 0,
          painTypes: [],
          comments: '',
        );

        await tester.pumpWidget(
          buildTestWidget(entry: entry, cycle: testCycle),
        );
        await tester.pumpAndSettle();

        // Verify date header and resolved code
        expect(
          find.text(
            'Observations for ${AppDateFormats.weekdayMonthDay.format(testDate)}',
          ),
          findsOneWidget,
        );
        expect(find.text('Resolved Code: 0'), findsOneWidget);

        // Verify count in section header
        expect(find.text('Logged Entries (0):'), findsOneWidget);

        // Verify empty state placeholder
        expect(
          find.text('No individual observations. (Click grid to add)'),
          findsOneWidget,
        );

        // Verify Add Observation button is present
        expect(
          find.text('Add Another Observation for This Day'),
          findsOneWidget,
        );

        // Verify no observation card exists
        expect(find.byType(Card), findsNothing);
      },
    );
  });

  group('DailyDetailSheet Header and Badges Tests', () {
    testWidgets('renders formatted date header, badge, and resolved VDRS code', (
      WidgetTester tester,
    ) async {
      final entry = DailyEntry(
        date: testDate,
        resolvedVdrsCode: '10KL',
        stampType: StampType.whiteBaby,
        peakDayLabel: 'P',
        observations: [],
        painLevel: 0,
        painTypes: [],
        comments: '',
      );

      await tester.pumpWidget(buildTestWidget(entry: entry, cycle: testCycle));
      await tester.pumpAndSettle();

      // Check date header
      expect(
        find.text(
          'Observations for ${AppDateFormats.weekdayMonthDay.format(testDate)}',
        ),
        findsOneWidget,
      );

      // Check CreightonStampWidget badge
      expect(find.byType(CreightonStampWidget), findsOneWidget);
      expect(find.text('P'), findsOneWidget);

      // Check Resolved code
      expect(find.text('Resolved Code: 10KL'), findsOneWidget);

      // Intercourse badge should NOT be shown
      expect(find.text('Intercourse (I)'), findsNothing);
    });

    testWidgets(
      'renders intercourse badge in header when hasIntercourse is true',
      (WidgetTester tester) async {
        final obsWithIntercourse = Observation(
          id: 'obs-1',
          timestamp: DateTime(2026, 8, 3, 21, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          intercourse: true,
          userId: 'wife_uid',
        );

        final entry = DailyEntry(
          date: testDate,
          resolvedVdrsCode: 'I',
          stampType: StampType.green,
          observations: [obsWithIntercourse],
          painLevel: 0,
          painTypes: [],
          comments: '',
        );

        await tester.pumpWidget(
          buildTestWidget(entry: entry, cycle: testCycle),
        );
        await tester.pumpAndSettle();

        // Intercourse badge in header row contains icon and text
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.text('Intercourse (I)'), findsWidgets);
      },
    );

    testWidgets('tapping close icon pops the bottom sheet', (
      WidgetTester tester,
    ) async {
      final entry = DailyEntry(
        date: testDate,
        resolvedVdrsCode: '0',
        stampType: StampType.green,
        observations: [],
        painLevel: 0,
        painTypes: [],
        comments: '',
      );

      await tester.pumpWidget(
        buildTestWidget(
          entry: entry,
          cycle: testCycle,
          openAsBottomSheet: true,
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Open Daily Detail Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyDetailSheet), findsOneWidget);

      // Tap close button (Icons.close)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.byType(DailyDetailSheet), findsNothing);
    });
  });

  group('DailyDetailSheet Notes and Pain Indicators Tests', () {
    testWidgets('renders notes summary when entry comments are present', (
      WidgetTester tester,
    ) async {
      final entry = DailyEntry(
        date: testDate,
        resolvedVdrsCode: '2W',
        stampType: StampType.green,
        observations: [],
        painLevel: 0,
        painTypes: [],
        comments: 'Felt slight dampness in the afternoon after walking.',
      );

      await tester.pumpWidget(buildTestWidget(entry: entry, cycle: testCycle));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Notes Summary: Felt slight dampness in the afternoon after walking.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('hides notes summary when entry comments are empty', (
      WidgetTester tester,
    ) async {
      final entry = DailyEntry(
        date: testDate,
        resolvedVdrsCode: '0',
        stampType: StampType.green,
        observations: [],
        painLevel: 0,
        painTypes: [],
        comments: '',
      );

      await tester.pumpWidget(buildTestWidget(entry: entry, cycle: testCycle));
      await tester.pumpAndSettle();

      expect(find.textContaining('Notes Summary:'), findsNothing);
    });

    testWidgets('renders pain indicator when painLevel is greater than 0', (
      WidgetTester tester,
    ) async {
      final entry = DailyEntry(
        date: testDate,
        resolvedVdrsCode: '0',
        stampType: StampType.green,
        observations: [],
        painLevel: 8,
        painTypes: ['cramps', 'headache'],
        comments: '',
      );

      await tester.pumpWidget(buildTestWidget(entry: entry, cycle: testCycle));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.text('Pain Level: 8/10 (cramps, headache)'), findsOneWidget);
    });

    testWidgets('hides pain indicator when painLevel is 0', (
      WidgetTester tester,
    ) async {
      final entry = DailyEntry(
        date: testDate,
        resolvedVdrsCode: '0',
        stampType: StampType.green,
        observations: [],
        painLevel: 0,
        painTypes: [],
        comments: '',
      );

      await tester.pumpWidget(buildTestWidget(entry: entry, cycle: testCycle));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_fire_department), findsNothing);
      expect(find.textContaining('Pain Level:'), findsNothing);
    });
  });

  group('DailyDetailSheet Observation Card List & Attribution Tests', () {
    testWidgets(
      'renders observation cards with details, comments, and Husband/Wife attribution',
      (WidgetTester tester) async {
        final obs1 = Observation(
          id: 'obs-1',
          timestamp: DateTime(2026, 8, 3, 9, 30),
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [Consistency.lubricative],
          bleeding: Bleeding.none,
          frequency: Frequency.twice,
          intercourse: false,
          comment: 'Noticed clear mucus twice today',
          userId: 'husband_uid',
        );

        final obs2 = Observation(
          id: 'obs-2',
          timestamp: DateTime(2026, 8, 3, 22, 15),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          frequency: Frequency.none,
          intercourse: true,
          comment: '',
          userId: 'wife_uid',
        );

        final entry = DailyEntry(
          date: testDate,
          resolvedVdrsCode: '10KL x2 I',
          stampType: StampType.whiteBaby,
          observations: [obs1, obs2],
          painLevel: 0,
          painTypes: [],
          comments: '',
        );

        await tester.pumpWidget(
          buildTestWidget(entry: entry, cycle: testCycle),
        );
        await tester.pumpAndSettle();

        // Check header observation count
        expect(find.text('Logged Entries (2):'), findsOneWidget);

        // Check Observation 1 details
        expect(find.text('Code: ${obs1.vdrsCode}'), findsOneWidget);
        expect(
          find.text(
            'Sensation: Damp | Stretch: Stretchy (1 inch or more) | Freq: Twice (x2)',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Notes: Noticed clear mucus twice today'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Logged at ${AppDateFormats.timeOfDayPadded.format(obs1.timestamp)} by Husband',
          ),
          findsOneWidget,
        );

        // Check Observation 2 details
        expect(find.text('Code: ${obs2.vdrsCode}'), findsOneWidget);
        expect(
          find.text('Sensation: Dry | Stretch: None | Intercourse (I)'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Logged at ${AppDateFormats.timeOfDayPadded.format(obs2.timestamp)} by Wife',
          ),
          findsOneWidget,
        );

        // Verify delete buttons exist for both observations
        expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
      },
    );
  });

  group('DailyDetailSheet Delete Observation Action Tests', () {
    testWidgets(
      'tapping delete icon invokes Services.db.deleteObservation and closes bottom sheet',
      (WidgetTester tester) async {
        final obs = Observation(
          id: 'obs-delete-me',
          timestamp: DateTime(2026, 8, 3, 14, 0),
          sensation: Sensation.wet,
          stretch: Stretch.tacky,
          colors: [MucusColor.cloudy],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'wife_uid',
        );

        final entry = DailyEntry(
          date: testDate,
          resolvedVdrsCode: '8C',
          stampType: StampType.whiteBaby,
          observations: [obs],
          painLevel: 0,
          painTypes: [],
          comments: '',
        );

        await tester.pumpWidget(
          buildTestWidget(
            entry: entry,
            cycle: testCycle,
            openAsBottomSheet: true,
          ),
        );
        await tester.pumpAndSettle();

        // Open bottom sheet
        await tester.tap(find.text('Open Daily Detail Sheet'));
        await tester.pumpAndSettle();

        expect(find.byType(DailyDetailSheet), findsOneWidget);

        // Tap delete icon
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Verify deleteObservation was called on Services.db with expected arguments
        expect(mockDb.deleteCallCount, equals(1));
        expect(mockDb.lastDeletedCycleId, equals('cycle-123'));
        expect(mockDb.lastDeletedDate, equals(testDate));
        expect(mockDb.lastDeletedObservationId, equals('obs-delete-me'));

        // Verify bottom sheet is dismissed
        expect(find.byType(DailyDetailSheet), findsNothing);
      },
    );
  });

  group('DailyDetailSheet Add Observation Button Tests', () {
    testWidgets(
      'tapping Add Another Observation button closes sheet and opens AddObservationDialog',
      (WidgetTester tester) async {
        final entry = DailyEntry(
          date: testDate,
          resolvedVdrsCode: '0',
          stampType: StampType.green,
          observations: [],
          painLevel: 0,
          painTypes: [],
          comments: '',
        );

        await tester.pumpWidget(
          buildTestWidget(
            entry: entry,
            cycle: testCycle,
            openAsBottomSheet: true,
          ),
        );
        await tester.pumpAndSettle();

        // Open bottom sheet
        await tester.tap(find.text('Open Daily Detail Sheet'));
        await tester.pumpAndSettle();

        expect(find.byType(DailyDetailSheet), findsOneWidget);

        // Tap "Add Another Observation for This Day" button
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            'Add Another Observation for This Day',
          ),
        );
        await tester.pumpAndSettle();

        // Bottom sheet should be dismissed
        expect(find.byType(DailyDetailSheet), findsNothing);

        // AddObservationDialog should be displayed
        expect(find.byType(AddObservationDialog), findsOneWidget);
      },
    );
  });
}
