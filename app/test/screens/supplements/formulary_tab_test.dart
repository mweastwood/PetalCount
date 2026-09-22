import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/supplements/formulary_tab.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    await Services.db.resetDefaultSupplements();
  });

  group('FormularyTab Tests', () {
    testWidgets('renders all supplement items with edit and delete callbacks', (
      tester,
    ) async {
      final supps = await Services.db.streamSupplements().first;
      SupplementItem? editedItem;
      SupplementItem? deletedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormularyTab(
              supplements: supps,
              onEdit: (item) => editedItem = item,
              onDelete: (item) => deletedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prenatal'), findsOneWidget);
      expect(find.text('CoQ10'), findsOneWidget);
      expect(find.text('Vitamin D'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit Supplement').first);
      expect(editedItem, equals(supps.first));

      await tester.tap(find.byTooltip('Delete Supplement').first);
      expect(deletedItem, equals(supps.first));
    });

    testWidgets('filters supplements by selected user role segment', (
      tester,
    ) async {
      const wifeSupp = SupplementItem(
        id: 'w1',
        name: 'Wife Vitamin',
        quantity: '1 pill',
        targetRole: UserRole.wife,
      );
      const husbandSupp = SupplementItem(
        id: 'h1',
        name: 'Husband Zinc',
        quantity: '1 tablet',
        targetRole: UserRole.husband,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormularyTab(supplements: [wifeSupp, husbandSupp]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 'All' is selected - both supplements are displayed
      expect(find.text('Wife Vitamin'), findsOneWidget);
      expect(find.text('Husband Zinc'), findsOneWidget);

      // Tap 'Wife' segment filter
      await tester.tap(find.text('👩 Wife (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Wife Vitamin'), findsOneWidget);
      expect(find.text('Husband Zinc'), findsNothing);

      // Tap 'Husband' segment filter
      await tester.tap(find.text('👨 Husband (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Wife Vitamin'), findsNothing);
      expect(find.text('Husband Zinc'), findsOneWidget);

      // Tap 'All' segment filter to reset
      await tester.tap(find.text('All (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Wife Vitamin'), findsOneWidget);
      expect(find.text('Husband Zinc'), findsOneWidget);
    });

    testWidgets(
      'renders initial role filter when initialRoleFilter is provided',
      (tester) async {
        const wifeSupp = SupplementItem(
          id: 'w1',
          name: 'Wife Folate',
          quantity: '1 pill',
          targetRole: UserRole.wife,
        );
        const husbandSupp = SupplementItem(
          id: 'h1',
          name: 'Husband Omega 3',
          quantity: '1 capsule',
          targetRole: UserRole.husband,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FormularyTab(
                supplements: [wifeSupp, husbandSupp],
                initialRoleFilter: UserRole.wife,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Wife Folate'), findsOneWidget);
        expect(find.text('Husband Omega 3'), findsNothing);
      },
    );

    testWidgets(
      'renders empty state card when no supplements match the filter',
      (tester) async {
        const wifeSupp = SupplementItem(
          id: 'w1',
          name: 'Wife Prenatal',
          quantity: '1 tablet',
          targetRole: UserRole.wife,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: FormularyTab(supplements: [wifeSupp])),
          ),
        );
        await tester.pumpAndSettle();

        // Filter by Husband role which has 0 supplements
        await tester.tap(find.text('👨 Husband (0)'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
        expect(
          find.text('No supplements found for this filter.'),
          findsOneWidget,
        );
        expect(find.text('Wife Prenatal'), findsNothing);
      },
    );

    testWidgets(
      'renders empty state card when input supplement list is empty',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: FormularyTab(supplements: [])),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
        expect(
          find.text('No supplements found for this filter.'),
          findsOneWidget,
        );
        expect(find.text('All (0)'), findsOneWidget);
        expect(find.text('👩 Wife (0)'), findsOneWidget);
        expect(find.text('👨 Husband (0)'), findsOneWidget);
      },
    );

    testWidgets('displays accurate item counts in segment button labels', (
      tester,
    ) async {
      const wifeSupp1 = SupplementItem(
        id: 'w1',
        name: 'Wife Supp 1',
        quantity: '1',
        targetRole: UserRole.wife,
      );
      const wifeSupp2 = SupplementItem(
        id: 'w2',
        name: 'Wife Supp 2',
        quantity: '1',
        targetRole: UserRole.wife,
      );
      const husbandSupp = SupplementItem(
        id: 'h1',
        name: 'Husband Supp 1',
        quantity: '1',
        targetRole: UserRole.husband,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormularyTab(
              supplements: [wifeSupp1, wifeSupp2, husbandSupp],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('👩 Wife (2)'), findsOneWidget);
      expect(find.text('👨 Husband (1)'), findsOneWidget);
    });

    testWidgets(
      'renders supplement details including dosage badges, role chips, and instructions',
      (tester) async {
        const detailedSupp = SupplementItem(
          id: 'detailed_1',
          name: 'Comprehensive Multivitamin',
          quantity: '2 capsules',
          takeWithFood: true,
          morningDose: 1,
          afternoonDose: 1,
          eveningDose: 1,
          instructions: 'Take daily with full meal',
          targetRole: UserRole.husband,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: FormularyTab(supplements: [detailedSupp])),
          ),
        );
        await tester.pumpAndSettle();

        // Item header info
        expect(find.text('Comprehensive Multivitamin'), findsOneWidget);
        expect(find.text('Quantity: 2 capsules'), findsOneWidget);
        expect(
          find.text('👨 Husband (1)'),
          findsOneWidget,
        ); // Segment button label
        expect(find.text('👨 Husband'), findsOneWidget); // Card role chip

        // Dose badges
        expect(find.text('🌅 Morning (1)'), findsOneWidget);
        expect(find.text('☀️ Afternoon (1)'), findsOneWidget);
        expect(find.text('🌙 Evening (1)'), findsOneWidget);
        expect(find.text('🍽️ Take with food'), findsOneWidget);

        // Schedule and instructions
        expect(find.text('Schedule: '), findsOneWidget);
        expect(find.text('Daily (All Days)'), findsOneWidget);
        expect(find.text('Take daily with full meal'), findsOneWidget);
      },
    );

    testWidgets(
      'omits dosage badges and instructions when not configured',
      (tester) async {
        const minimalSupp = SupplementItem(
          id: 'min_1',
          name: 'Basic Folate',
          quantity: '1 pill',
          morningDose: 1,
          afternoonDose: 0,
          eveningDose: 0,
          takeWithFood: false,
          instructions: '',
          targetRole: UserRole.wife,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: FormularyTab(supplements: [minimalSupp])),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Basic Folate'), findsOneWidget);
        expect(find.text('🌅 Morning (1)'), findsOneWidget);
        expect(find.text('☀️ Afternoon (0)'), findsNothing);
        expect(find.text('🌙 Evening (0)'), findsNothing);
        expect(find.text('🍽️ Take with food'), findsNothing);
      },
    );

    testWidgets('renders custom schedule rule descriptions', (tester) async {
      const cycleDaysSupp = SupplementItem(
        id: 'cd_1',
        name: 'Clomid',
        quantity: '50 mg',
        ruleType: SupplementScheduleRuleType.cycleDays,
        startCycleDay: 4,
        endCycleDay: 8,
        targetRole: UserRole.wife,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FormularyTab(supplements: [cycleDaysSupp])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clomid'), findsOneWidget);
      expect(find.text('Cycle Day 4 – Day 8'), findsOneWidget);
    });
  });
}
