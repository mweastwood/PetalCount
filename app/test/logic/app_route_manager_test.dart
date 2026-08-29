import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Services.init();
  });

  group('AppRouteManager Unit & Widget Tests', () {
    testWidgets('handleUrlParameters parses /chart route', (tester) async {
      final routeManager = AppRouteManager(
        mockUri: Uri.parse('https://example.com/chart'),
      );

      ViewMode? updatedMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  routeManager.handleUrlParameters(
                    context: context,
                    onViewModeChanged: (mode) {
                      updatedMode = mode;
                    },
                    currentViewMode: ViewMode.observations,
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(updatedMode, ViewMode.chart);
    });

    testWidgets('handleUrlParameters parses /observations route', (
      tester,
    ) async {
      final routeManager = AppRouteManager(
        mockUri: Uri.parse('https://example.com/observations'),
      );

      ViewMode? updatedMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  routeManager.handleUrlParameters(
                    context: context,
                    onViewModeChanged: (mode) {
                      updatedMode = mode;
                    },
                    currentViewMode: ViewMode.chart,
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(updatedMode, ViewMode.observations);
    });

    testWidgets('handleUrlParameters opens SettingsScreen for /settings', (
      tester,
    ) async {
      final routeManager = AppRouteManager(
        mockUri: Uri.parse('https://example.com/settings'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  routeManager.handleUrlParameters(
                    context: context,
                    onViewModeChanged: (_) {},
                    currentViewMode: ViewMode.observations,
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(find.text('Settings & Configuration'), findsOneWidget);
    });

    testWidgets('handleUrlParameters opens ChartSelectionScreen for /charts', (
      tester,
    ) async {
      final routeManager = AppRouteManager(
        mockUri: Uri.parse('https://example.com/charts'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  routeManager.handleUrlParameters(
                    context: context,
                    onViewModeChanged: (_) {},
                    currentViewMode: ViewMode.observations,
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(find.text('Select Chart'), findsOneWidget);
    });

    test('updateUrlPath is a no-op on non-web platforms and does not throw', () {
      final routeManager = AppRouteManager();
      // On non-web platforms (kIsWeb == false), updateUrlPath safely no-ops
      for (final mode in ViewMode.values) {
        expect(
          () => routeManager.updateUrlPath(mode),
          returnsNormally,
          reason:
              'updateUrlPath($mode) should execute safely on non-web platforms',
        );
      }
    });

    test(
      'updateUrlPathRaw is a no-op on non-web platforms and does not throw',
      () {
        final routeManager = AppRouteManager();
        const testPaths = [
          '/observations',
          '/chart',
          '/settings',
          '/supplements',
          '/charts',
          '/custom-route',
        ];
        // On non-web platforms (kIsWeb == false), updateUrlPathRaw safely no-ops
        for (final path in testPaths) {
          expect(
            () => routeManager.updateUrlPathRaw(path),
            returnsNormally,
            reason:
                'updateUrlPathRaw($path) should execute safely on non-web platforms',
          );
        }
      },
    );
  });
}
