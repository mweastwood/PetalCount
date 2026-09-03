import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/widgets/wizard/option_card.dart';

void main() {
  group('OptionCard & OptionGrid Unit & Widget Tests', () {
    group('OptionCard', () {
      testWidgets('renders basic label without optional subtitle or icon', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptionCard(label: 'Simple Option', onTap: () {}),
            ),
          ),
        );

        expect(find.text('Simple Option'), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
      });

      testWidgets('renders full OptionCard with subtitle and custom icon', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptionCard(
                label: 'Detailed Option',
                subtitle: 'A helpful subtitle',
                icon: Icons.star,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Detailed Option'), findsOneWidget);
        expect(find.text('A helpful subtitle'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('renders unselected styling and no checkmark badge', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: Scaffold(
              body: OptionCard(
                label: 'Unselected',
                icon: Icons.circle,
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(OptionCard),
            matching: find.byType(Material),
          ),
        );
        final context = tester.element(find.byType(OptionCard));
        final colorScheme = Theme.of(context).colorScheme;

        expect(
          material.color,
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        );

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(InkWell),
                matching: find.byType(Container),
              )
              .first,
        );
        final boxDecoration = container.decoration as BoxDecoration;
        final border = boxDecoration.border as Border;
        expect(border.top.width, 1.0);
        expect(
          border.top.color,
          colorScheme.outlineVariant.withValues(alpha: 0.5),
        );

        expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      });

      testWidgets(
        'renders selected styling, border highlight, and checkmark badge',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.light(useMaterial3: true),
              home: Scaffold(
                body: OptionCard(
                  label: 'Selected Option',
                  subtitle: 'Selected Subtitle',
                  icon: Icons.check,
                  isSelected: true,
                  onTap: () {},
                ),
              ),
            ),
          );

          final material = tester.widget<Material>(
            find.descendant(
              of: find.byType(OptionCard),
              matching: find.byType(Material),
            ),
          );
          final context = tester.element(find.byType(OptionCard));
          final colorScheme = Theme.of(context).colorScheme;

          expect(material.color, colorScheme.primaryContainer);

          final container = tester.widget<Container>(
            find
                .descendant(
                  of: find.byType(InkWell),
                  matching: find.byType(Container),
                )
                .first,
          );
          final boxDecoration = container.decoration as BoxDecoration;
          final border = boxDecoration.border as Border;
          expect(border.top.width, 2.0);
          expect(border.top.color, colorScheme.primary);

          expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
          final checkIcon = tester.widget<Icon>(
            find.byIcon(Icons.check_circle_rounded),
          );
          expect(checkIcon.color, colorScheme.primary);
        },
      );

      testWidgets('triggers onTap callback when tapped', (
        WidgetTester tester,
      ) async {
        bool wasTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptionCard(
                label: 'Tappable',
                onTap: () {
                  wasTapped = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tappable'));
        await tester.pumpAndSettle();

        expect(wasTapped, isTrue);
      });
    });

    group('OptionGrid', () {
      testWidgets('renders standard GridView when fullWidthIndexes is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                child: OptionGrid(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  children: [
                    OptionCard(label: 'Item 1', onTap: () {}),
                    OptionCard(label: 'Item 2', onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(GridView), findsOneWidget);
        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.childrenDelegate as SliverChildListDelegate;
        expect(delegate.children.length, 2);
      });

      testWidgets(
        'renders custom Column with ConstrainedBox for fullWidthIndexes on wide screens',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 600,
                  child: OptionGrid(
                    fullWidthIndexes: const [0],
                    crossAxisCount: 2,
                    children: [
                      OptionCard(label: 'Full Width Item', onTap: () {}),
                      OptionCard(label: 'Item A', onTap: () {}),
                      OptionCard(label: 'Item B', onTap: () {}),
                      OptionCard(label: 'Item C (Unpaired)', onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          );

          // In fullWidth mode on wide screens, OptionGrid creates Column with rows and ConstrainedBox
          expect(find.byType(GridView), findsNothing);
          expect(find.byType(ConstrainedBox), findsWidgets);
          expect(find.text('Full Width Item'), findsOneWidget);
          expect(find.text('Item A'), findsOneWidget);
          expect(find.text('Item B'), findsOneWidget);
          expect(find.text('Item C (Unpaired)'), findsOneWidget);
          expect(find.byType(Spacer), findsOneWidget);
        },
      );

      testWidgets(
        'collapses to single column GridView on narrow screens (maxWidth < 380)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 320,
                  child: OptionGrid(
                    fullWidthIndexes: const [0],
                    children: [
                      OptionCard(label: 'Item 1', onTap: () {}),
                      OptionCard(label: 'Item 2', onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          );

          // On narrow screen (width 320 < 380), responsiveColumns == 1, renders GridView
          expect(find.byType(GridView), findsOneWidget);
          final gridView = tester.widget<GridView>(find.byType(GridView));
          final gridDelegate =
              gridView.gridDelegate
                  as SliverGridDelegateWithFixedCrossAxisCount;
          expect(gridDelegate.crossAxisCount, 1);
          expect(gridDelegate.childAspectRatio, 2.8);
        },
      );
    });
  });
}
