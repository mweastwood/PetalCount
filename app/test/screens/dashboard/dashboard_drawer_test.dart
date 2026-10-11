import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/utils/app_version.dart';
import 'package:petal_count/screens/dashboard/dashboard_drawer.dart';

void main() {
  group('DashboardDrawer Tests', () {
    testWidgets('renders all drawer items and version display correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: DashboardDrawer(
              onNavigateToCharts: () {},
              onSelectSupplements: () {},
              onNavigateToSettings: () {},
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Menu'), findsOneWidget);
      expect(find.byKey(const Key('drawer_switch_chart_tile')), findsOneWidget);
      expect(find.byKey(const Key('drawer_supplements_tile')), findsOneWidget);
      expect(find.byKey(const Key('drawer_settings_tile')), findsOneWidget);
      expect(find.byKey(const Key('drawer_logout_tile')), findsOneWidget);
      expect(find.byKey(const Key('drawer_version_tile')), findsOneWidget);
      expect(find.text(AppVersion.display), findsOneWidget);
    });

    testWidgets('triggers navigation callbacks when drawer tiles are tapped', (
      WidgetTester tester,
    ) async {
      var chartsCalled = false;
      var supplementsCalled = false;
      var settingsCalled = false;
      var signOutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: DashboardDrawer(
              onNavigateToCharts: () {
                chartsCalled = true;
              },
              onSelectSupplements: () {
                supplementsCalled = true;
              },
              onNavigateToSettings: () {
                settingsCalled = true;
              },
              onSignOut: () async {
                signOutCalled = true;
              },
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('drawer_switch_chart_tile')));
      await tester.pumpAndSettle();
      expect(chartsCalled, isTrue);

      await tester.tap(find.byKey(const Key('drawer_supplements_tile')));
      await tester.pumpAndSettle();
      expect(supplementsCalled, isTrue);

      await tester.tap(find.byKey(const Key('drawer_settings_tile')));
      await tester.pumpAndSettle();
      expect(settingsCalled, isTrue);

      await tester.tap(find.byKey(const Key('drawer_logout_tile')));
      await tester.pumpAndSettle();
      expect(signOutCalled, isTrue);
    });

    testWidgets('renders disabled sign out tile when onSignOut is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: DashboardDrawer(
              onNavigateToCharts: () {},
              onSelectSupplements: () {},
              onNavigateToSettings: () {},
              onSignOut: null,
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final signOutTile = tester.widget<ListTile>(
        find.byKey(const Key('drawer_logout_tile')),
      );
      expect(signOutTile.onTap, isNull);
    });
  });
}
