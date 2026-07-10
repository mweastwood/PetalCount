import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/main.dart';
import 'package:petal_count/services/database_service.dart';
import 'package:petal_count/services/services.dart';

class TestDatabaseService extends InMemoryDatabaseService {
  bool shouldFailCreateChart = false;
  String? overrideChartId;
  final _testAuthController = StreamController<User?>.broadcast();
  User? testUser;
  Completer<void>? createChartCompleter;

  TestDatabaseService() {
    testUser = MockUser(uid: 'test_uid', email: 'test@example.com');
    overrideChartId = null;
  }

  @override
  User? get currentUser => testUser;

  @override
  String? get currentChartId => overrideChartId;

  @override
  Stream<User?> get authStateChanges => _testAuthController.stream;

  void emitUser(User? user) {
    _testAuthController.add(user);
  }

  @override
  Future<void> createChart() async {
    if (createChartCompleter != null) {
      await createChartCompleter!.future;
    }
    if (shouldFailCreateChart) {
      throw Exception("Simulated Firestore write failure");
    }
    // Simulate success
    overrideChartId = 'chart_123';
    emitUser(testUser);
  }
}

void main() {
  late TestDatabaseService testDb;

  setUp(() {
    testDb = TestDatabaseService();
    Services.db = testDb;
  });

  testWidgets('SetupChartScreen success path navigates to DashboardScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PetalCountApp());

    // Emit the initial user so AuthGate builder fires
    testDb.emitUser(testDb.testUser);
    await tester.pumpAndSettle();

    // Verify we are on SetupChartScreen
    expect(find.text('Setup Chart'), findsOneWidget);
    expect(find.text('Create New Shared Chart'), findsOneWidget);

    // Tap "Create New Shared Chart"
    await tester.tap(find.text('Create New Shared Chart'));

    // Pump frames to handle the microtasks and transition
    await tester.pumpAndSettle();

    // Verify we transitioned to DashboardScreen
    expect(find.text('Petal Count'), findsOneWidget);
  });

  testWidgets(
    'SetupChartScreen failure path stops loading and shows SnackBar',
    (WidgetTester tester) async {
      testDb.shouldFailCreateChart = true;
      testDb.createChartCompleter = Completer<void>();

      await tester.pumpWidget(const PetalCountApp());
      testDb.emitUser(testDb.testUser);
      await tester.pumpAndSettle();

      // Tap "Create New Shared Chart"
      await tester.tap(find.text('Create New Shared Chart'));

      // Let the loading state render
      await tester.pump();

      // Verify we are showing loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future (which will trigger failure inside createChart)
      testDb.createChartCompleter!.complete();

      // Let the exception throw and handle finally block
      await tester.pumpAndSettle();

      // Verify we are still on Setup Chart screen (not Dashboard)
      expect(find.text('Setup Chart'), findsOneWidget);

      // Verify loader is gone and button is visible again
      expect(find.text('Create New Shared Chart'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify SnackBar with error message is displayed
      expect(find.textContaining('Error creating chart:'), findsOneWidget);
      expect(
        find.textContaining('Simulated Firestore write failure'),
        findsOneWidget,
      );
    },
  );
}
