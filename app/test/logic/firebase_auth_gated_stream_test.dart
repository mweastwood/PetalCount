import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';

void main() {
  group('FirebaseDatabaseService.buildAuthGatedStreamHelper', () {
    test(
      'emits emptyValue immediately when getCurrentChartId() returns null',
      () async {
        final authController = StreamController<dynamic>.broadcast();
        addTearDown(authController.close);

        final stream =
            FirebaseDatabaseService.buildAuthGatedStreamHelper<List<String>>(
              getCurrentChartId: () => null,
              authStateChanges: authController.stream,
              emptyValue: const [],
              subscribe: (_) => const Stream.empty(),
            );

        final emitted = <List<String>>[];
        final sub = stream.listen(emitted.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();

        expect(emitted, [isEmpty]);
      },
    );

    test(
      'subscribes to subscribe(chartId) and forwards items when getCurrentChartId() is non-null',
      () async {
        final authController = StreamController<dynamic>.broadcast();
        final dataController = StreamController<List<String>>.broadcast();
        addTearDown(authController.close);
        addTearDown(dataController.close);

        String? requestedChartId;
        final stream =
            FirebaseDatabaseService.buildAuthGatedStreamHelper<List<String>>(
              getCurrentChartId: () => 'chart_123',
              authStateChanges: authController.stream,
              emptyValue: const [],
              subscribe: (chartId) {
                requestedChartId = chartId;
                return dataController.stream;
              },
            );

        final emitted = <List<String>>[];
        final sub = stream.listen(emitted.add);
        addTearDown(sub.cancel);

        expect(requestedChartId, 'chart_123');
        expect(dataController.hasListener, isTrue);

        dataController.add(['cycle_1', 'cycle_2']);
        await pumpEventQueue();

        expect(emitted, [
          ['cycle_1', 'cycle_2'],
        ]);
      },
    );

    test(
      'triggers updateListener when authStateChanges emits, switching active subscription',
      () async {
        final authController = StreamController<dynamic>.broadcast();
        final dataController1 = StreamController<List<String>>.broadcast();
        final dataController2 = StreamController<List<String>>.broadcast();
        addTearDown(authController.close);
        addTearDown(dataController1.close);
        addTearDown(dataController2.close);

        String? activeChartId = 'chart_1';
        final stream =
            FirebaseDatabaseService.buildAuthGatedStreamHelper<List<String>>(
              getCurrentChartId: () => activeChartId,
              authStateChanges: authController.stream,
              emptyValue: const [],
              subscribe: (chartId) {
                if (chartId == 'chart_1') return dataController1.stream;
                if (chartId == 'chart_2') return dataController2.stream;
                return const Stream.empty();
              },
            );

        final emitted = <List<String>>[];
        final sub = stream.listen(emitted.add);
        addTearDown(sub.cancel);

        expect(dataController1.hasListener, isTrue);
        expect(dataController2.hasListener, isFalse);

        dataController1.add(['chart1_val']);
        await pumpEventQueue();
        expect(emitted, [
          ['chart1_val'],
        ]);

        // Switch auth state to chart_2
        activeChartId = 'chart_2';
        authController.add('user_2');
        await pumpEventQueue();

        expect(dataController1.hasListener, isFalse);
        expect(dataController2.hasListener, isTrue);

        dataController2.add(['chart2_val']);
        await pumpEventQueue();
        expect(emitted, [
          ['chart1_val'],
          ['chart2_val'],
        ]);

        // Switch auth state to logged out (null chart ID)
        activeChartId = null;
        authController.add(null);
        await pumpEventQueue();

        expect(dataController2.hasListener, isFalse);
        expect(emitted, [
          ['chart1_val'],
          ['chart2_val'],
          isEmpty,
        ]);
      },
    );

    test(
      'forwards fallback emptyValue when data stream errors and logs with debugLabel',
      () async {
        final authController = StreamController<dynamic>.broadcast();
        final dataController = StreamController<List<String>>.broadcast();
        addTearDown(authController.close);
        addTearDown(dataController.close);

        final loggedMessages = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) loggedMessages.add(message);
        };
        addTearDown(() => debugPrint = originalDebugPrint);

        final stream =
            FirebaseDatabaseService.buildAuthGatedStreamHelper<List<String>>(
              getCurrentChartId: () => 'chart_err',
              authStateChanges: authController.stream,
              emptyValue: const [],
              debugLabel: 'test-cycles',
              subscribe: (_) => dataController.stream,
            );

        final emitted = <List<String>>[];
        final sub = stream.listen(emitted.add);
        addTearDown(sub.cancel);

        dataController.addError(Exception('Firestore query failed'));
        await pumpEventQueue();

        expect(emitted, [isEmpty]);
        expect(
          loggedMessages,
          contains(
            predicate<String>(
              (msg) =>
                  msg.contains('Error streaming test-cycles:') &&
                  msg.contains('Firestore query failed'),
            ),
          ),
        );
      },
    );

    test(
      'cancels active subscriptions (dataSub, authSub) when broadcast stream cancels',
      () async {
        final authController = StreamController<dynamic>.broadcast();
        final dataController = StreamController<List<String>>.broadcast();
        addTearDown(authController.close);
        addTearDown(dataController.close);

        final stream =
            FirebaseDatabaseService.buildAuthGatedStreamHelper<List<String>>(
              getCurrentChartId: () => 'chart_sub',
              authStateChanges: authController.stream,
              emptyValue: const [],
              subscribe: (_) => dataController.stream,
            );

        final sub = stream.listen((_) {});
        await pumpEventQueue();

        expect(dataController.hasListener, isTrue);
        expect(authController.hasListener, isTrue);

        await sub.cancel();
        await pumpEventQueue();

        expect(dataController.hasListener, isFalse);
        expect(authController.hasListener, isFalse);
      },
    );

    test(
      'correctly re-establishes listeners if a new subscriber listens after cancellation',
      () async {
        final authController = StreamController<dynamic>.broadcast();
        final dataController = StreamController<List<String>>.broadcast();
        addTearDown(authController.close);
        addTearDown(dataController.close);

        final stream =
            FirebaseDatabaseService.buildAuthGatedStreamHelper<List<String>>(
              getCurrentChartId: () => 'chart_sub',
              authStateChanges: authController.stream,
              emptyValue: const [],
              subscribe: (_) => dataController.stream,
            );

        final sub1 = stream.listen((_) {});
        await pumpEventQueue();

        expect(dataController.hasListener, isTrue);
        expect(authController.hasListener, isTrue);

        await sub1.cancel();
        await pumpEventQueue();

        expect(dataController.hasListener, isFalse);
        expect(authController.hasListener, isFalse);

        final emitted = <List<String>>[];
        final sub2 = stream.listen(emitted.add);
        addTearDown(sub2.cancel);
        await pumpEventQueue();

        expect(dataController.hasListener, isTrue);
        expect(authController.hasListener, isTrue);

        dataController.add(['resubscribed_item']);
        await pumpEventQueue();

        expect(emitted, [
          ['resubscribed_item'],
        ]);
      },
    );
  });
}
