import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/chart_selection_screen.dart';

class MockChartSelectionDatabaseService extends InMemoryDatabaseService {
  List<Map<String, dynamic>> pendingInvitationsToReturn = [];

  @override
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    return pendingInvitationsToReturn;
  }

  @override
  Stream<List<Map<String, dynamic>>> streamAvailableCharts() {
    return Stream.value([
      {
        'id': 'chart_1',
        'emails': ['user@example.com'],
        'role': 'Owner',
      },
    ]);
  }
}

void main() {
  late MockChartSelectionDatabaseService testDb;

  setUp(() async {
    testDb = MockChartSelectionDatabaseService();
    await Services.init(dbService: testDb);
  });

  group('ChartSelectionScreen Pending Invitations Tests', () {
    testWidgets('renders pending invitation with valid senderEmail', (
      WidgetTester tester,
    ) async {
      testDb.pendingInvitationsToReturn = [
        {
          'invitationId': 'invite_1',
          'chartId': 'chart_abc',
          'senderEmail': 'alice@example.com',
          'status': 'pending',
        },
      ];

      await tester.pumpWidget(const MaterialApp(home: ChartSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pending Chart Invitations'), findsOneWidget);
      expect(find.text('Chart from alice@example.com'), findsOneWidget);
      expect(find.text('ID: chart_abc'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets(
      'renders fallback "Unknown" when senderEmail is null without crashing',
      (WidgetTester tester) async {
        testDb.pendingInvitationsToReturn = [
          {
            'invitationId': 'invite_2',
            'chartId': 'chart_xyz',
            'senderEmail': null,
            'status': 'pending',
          },
        ];

        await tester.pumpWidget(
          const MaterialApp(home: ChartSelectionScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pending Chart Invitations'), findsOneWidget);
        expect(find.text('Chart from Unknown'), findsOneWidget);
        expect(find.text('ID: chart_xyz'), findsOneWidget);
      },
    );

    testWidgets(
      'renders fallback "Unknown" when senderEmail is omitted / missing',
      (WidgetTester tester) async {
        testDb.pendingInvitationsToReturn = [
          {
            'invitationId': 'invite_3',
            'chartId': 'chart_missing',
            'status': 'pending',
          },
        ];

        await tester.pumpWidget(
          const MaterialApp(home: ChartSelectionScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pending Chart Invitations'), findsOneWidget);
        expect(find.text('Chart from Unknown'), findsOneWidget);
        expect(find.text('ID: chart_missing'), findsOneWidget);
      },
    );
  });
}
