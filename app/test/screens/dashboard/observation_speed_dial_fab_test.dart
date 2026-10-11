import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/widgets/wizard/wizard_controller.dart';
import 'package:petal_count/screens/dashboard/observation_speed_dial_fab.dart';

void main() {
  group('ObservationSpeedDialFab Tests', () {
    testWidgets('renders closed state with add icon and calls onToggle', (
      WidgetTester tester,
    ) async {
      var toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: ObservationSpeedDialFab(
              isOpen: false,
              onToggle: () {
                toggleCalled = true;
              },
              onSelectCategory: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fab_log_observation_toggle')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);

      // Verify speed dial options are hidden
      expect(find.text('Log intercourse'), findsNothing);
      expect(find.text('Log pain'), findsNothing);
      expect(find.text('Log bleeding'), findsNothing);
      expect(find.text('Log mucus'), findsNothing);

      await tester.tap(find.byKey(const Key('fab_log_observation_toggle')));
      await tester.pumpAndSettle();

      expect(toggleCalled, isTrue);
    });

    testWidgets('renders open state with close icon and all option items', (
      WidgetTester tester,
    ) async {
      final selectedCategories = <ObservationCategory>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: ObservationSpeedDialFab(
              isOpen: true,
              onToggle: () {},
              onSelectCategory: (category) {
                selectedCategories.add(category);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fab_log_observation_toggle')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.close), findsOneWidget);

      expect(find.text('Log intercourse'), findsOneWidget);
      expect(find.text('Log pain'), findsOneWidget);
      expect(find.text('Log bleeding'), findsOneWidget);
      expect(find.text('Log mucus'), findsOneWidget);

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.healing), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
      expect(find.byIcon(Icons.bubble_chart), findsOneWidget);

      // Tap options and verify callbacks
      await tester.tap(find.text('Log intercourse'));
      await tester.pumpAndSettle();
      expect(selectedCategories, contains(ObservationCategory.intercourse));

      await tester.tap(find.text('Log pain'));
      await tester.pumpAndSettle();
      expect(selectedCategories, contains(ObservationCategory.pain));

      await tester.tap(find.text('Log bleeding'));
      await tester.pumpAndSettle();
      expect(selectedCategories, contains(ObservationCategory.bleeding));

      await tester.tap(find.text('Log mucus'));
      await tester.pumpAndSettle();
      expect(selectedCategories, contains(ObservationCategory.mucus));

      // Also verify tapping the small FAB buttons directly
      selectedCategories.clear();
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();
      expect(selectedCategories, contains(ObservationCategory.intercourse));

      await tester.tap(find.byIcon(Icons.healing));
      await tester.pumpAndSettle();
      expect(selectedCategories, contains(ObservationCategory.pain));

      await tester.tap(find.byIcon(Icons.water_drop));
      await tester.pumpAndSettle();
      expect(selectedCategories, contains(ObservationCategory.bleeding));

      await tester.tap(find.byIcon(Icons.bubble_chart));
      await tester.pumpAndSettle();
      expect(selectedCategories, contains(ObservationCategory.mucus));
    });

    testWidgets('selecting a speed dial category does not trigger onToggle', (
      WidgetTester tester,
    ) async {
      var toggleCalled = false;
      ObservationCategory? selectedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: ObservationSpeedDialFab(
              isOpen: true,
              onToggle: () {
                toggleCalled = true;
              },
              onSelectCategory: (category) {
                selectedCategory = category;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log intercourse'));
      await tester.pumpAndSettle();

      expect(selectedCategory, equals(ObservationCategory.intercourse));
      expect(toggleCalled, isFalse);

      await tester.tap(find.text('Log pain'));
      await tester.pumpAndSettle();

      expect(selectedCategory, equals(ObservationCategory.pain));
      expect(toggleCalled, isFalse);

      await tester.tap(find.text('Log bleeding'));
      await tester.pumpAndSettle();

      expect(selectedCategory, equals(ObservationCategory.bleeding));
      expect(toggleCalled, isFalse);

      await tester.tap(find.text('Log mucus'));
      await tester.pumpAndSettle();

      expect(selectedCategory, equals(ObservationCategory.mucus));
      expect(toggleCalled, isFalse);
    });
  });
}
