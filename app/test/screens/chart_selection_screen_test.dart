import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/chart_selection_screen.dart';

class MockChartSelectionDatabaseService extends InMemoryDatabaseService {
  List<Map<String, dynamic>> pendingInvitationsToReturn = [];
  List<Map<String, dynamic>> availableChartsToReturn = [
    {
      'id': 'chart_1',
      'emails': ['user@example.com'],
      'role': 'Owner',
    },
  ];
  String? currentChartIdOverride = 'chart_1';
  User? currentUserOverride = MockUser(
    uid: 'user_1',
    email: 'user@example.com',
  );

  bool shouldFailAccept = false;
  bool shouldFailDecline = false;
  bool shouldFailCreateChart = false;

  final List<String> acceptedInvitationIds = [];
  final List<String> declinedInvitationIds = [];
  final List<String> activeChartIdsSet = [];
  int createChartCallCount = 0;
  int signOutCallCount = 0;
  int getPendingInvitationsCallCount = 0;

  @override
  User? get currentUser => currentUserOverride;

  @override
  String? get currentChartId => currentChartIdOverride;

  @override
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    getPendingInvitationsCallCount++;
    return List.from(pendingInvitationsToReturn);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamAvailableCharts() {
    return Stream.value(availableChartsToReturn);
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    if (shouldFailAccept) {
      throw Exception('Failed to accept invitation');
    }
    acceptedInvitationIds.add(invitationId);
    pendingInvitationsToReturn.removeWhere(
      (inv) =>
          (inv['invitationId'] ?? inv['id'] ?? inv['chartId']) == invitationId,
    );
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    if (shouldFailDecline) {
      throw Exception('Failed to decline invitation');
    }
    declinedInvitationIds.add(invitationId);
    pendingInvitationsToReturn.removeWhere(
      (inv) =>
          (inv['invitationId'] ?? inv['id'] ?? inv['chartId']) == invitationId,
    );
  }

  @override
  Future<void> setActiveChart(String chartId) async {
    activeChartIdsSet.add(chartId);
    currentChartIdOverride = chartId;
  }

  @override
  Future<void> createChart() async {
    if (shouldFailCreateChart) {
      throw Exception('Failed to create chart');
    }
    createChartCallCount++;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }
}

Widget buildTestApp({bool pushRoute = false}) {
  if (pushRoute) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChartSelectionScreen()),
              );
            },
            child: const Text('Open Chart Selection'),
          ),
        ),
      ),
    );
  }
  return const MaterialApp(home: ChartSelectionScreen());
}

void main() {
  late MockChartSelectionDatabaseService testDb;

  setUp(() async {
    testDb = MockChartSelectionDatabaseService();
    await Services.init(dbService: testDb);
  });

  group('Group A: Pending Invitations & Actions', () {
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

      await tester.pumpWidget(buildTestApp());
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

        await tester.pumpWidget(buildTestApp());
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

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Pending Chart Invitations'), findsOneWidget);
        expect(find.text('Chart from Unknown'), findsOneWidget);
        expect(find.text('ID: chart_missing'), findsOneWidget);
      },
    );

    testWidgets(
      'accepts invitation: calls acceptInvitation, reloads invites, and pops navigator if able',
      (WidgetTester tester) async {
        testDb.pendingInvitationsToReturn = [
          {
            'invitationId': 'invite_accept_1',
            'chartId': 'chart_target_1',
            'senderEmail': 'partner@example.com',
          },
        ];

        await tester.pumpWidget(buildTestApp(pushRoute: true));
        await tester.tap(find.text('Open Chart Selection'));
        await tester.pumpAndSettle();

        expect(find.byType(ChartSelectionScreen), findsOneWidget);
        expect(find.text('Chart from partner@example.com'), findsOneWidget);

        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        expect(testDb.acceptedInvitationIds, ['invite_accept_1']);
        expect(testDb.getPendingInvitationsCallCount, 2);
        expect(find.byType(ChartSelectionScreen), findsNothing);
      },
    );

    testWidgets(
      'declines invitation: calls declineInvitation, reloads invites, and removes card',
      (WidgetTester tester) async {
        testDb.pendingInvitationsToReturn = [
          {
            'invitationId': 'invite_decline_1',
            'chartId': 'chart_target_2',
            'senderEmail': 'decliner@example.com',
          },
        ];

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Chart from decliner@example.com'), findsOneWidget);

        await tester.tap(find.text('Decline'));
        await tester.pumpAndSettle();

        expect(testDb.declinedInvitationIds, ['invite_decline_1']);
        expect(testDb.getPendingInvitationsCallCount, 2);
        expect(find.text('Chart from decliner@example.com'), findsNothing);
        expect(find.text('Pending Chart Invitations'), findsNothing);
      },
    );

    testWidgets(
      'handles invitation fallback IDs when invitationId is not specified',
      (WidgetTester tester) async {
        testDb.pendingInvitationsToReturn = [
          {
            'id': 'invite_by_id',
            'chartId': 'chart_id_fallback',
            'senderEmail': 'first@example.com',
          },
          {'chartId': 'chart_only_id', 'senderEmail': 'second@example.com'},
        ];

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Accept').first);
        await tester.pumpAndSettle();
        expect(testDb.acceptedInvitationIds, ['invite_by_id']);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Decline').first);
        await tester.pumpAndSettle();
        expect(testDb.declinedInvitationIds, ['chart_only_id']);
      },
    );

    testWidgets(
      'accept invitation error displays red SnackBar with Dismiss action',
      (WidgetTester tester) async {
        testDb.shouldFailAccept = true;
        testDb.pendingInvitationsToReturn = [
          {
            'invitationId': 'fail_invite_1',
            'chartId': 'chart_fail_1',
            'senderEmail': 'error@example.com',
          },
        ];

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Error accepting invitation:'),
          findsOneWidget,
        );

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, Colors.red);

        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'decline invitation error displays red SnackBar with Dismiss action',
      (WidgetTester tester) async {
        testDb.shouldFailDecline = true;
        testDb.pendingInvitationsToReturn = [
          {
            'invitationId': 'fail_invite_2',
            'chartId': 'chart_fail_2',
            'senderEmail': 'error2@example.com',
          },
        ];

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Decline'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Error declining invitation:'),
          findsOneWidget,
        );

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, Colors.red);

        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });

  group('Group B: Chart Selection & Display', () {
    testWidgets(
      'switches active chart: calls setActiveChart and pops when in navigation stack',
      (WidgetTester tester) async {
        testDb.availableChartsToReturn = [
          {
            'id': 'chart_1',
            'emails': ['user@example.com'],
            'role': 'Owner',
          },
          {
            'id': 'chart_2',
            'emails': ['user@example.com', 'partner@example.com'],
            'role': 'Member',
          },
        ];
        testDb.currentChartIdOverride = 'chart_1';

        await tester.pumpWidget(buildTestApp(pushRoute: true));
        await tester.tap(find.text('Open Chart Selection'));
        await tester.pumpAndSettle();

        expect(find.byType(ChartSelectionScreen), findsOneWidget);

        await tester.tap(find.text('Chart ID: chart_2'));
        await tester.pumpAndSettle();

        expect(testDb.activeChartIdsSet, ['chart_2']);
        expect(find.byType(ChartSelectionScreen), findsNothing);
      },
    );

    testWidgets(
      'switches active chart: calls setActiveChart without popping when root route',
      (WidgetTester tester) async {
        testDb.availableChartsToReturn = [
          {
            'id': 'chart_1',
            'emails': ['user@example.com'],
          },
          {
            'id': 'chart_2',
            'emails': ['user@example.com'],
          },
        ];
        testDb.currentChartIdOverride = 'chart_1';

        await tester.pumpWidget(buildTestApp(pushRoute: false));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Chart ID: chart_2'));
        await tester.pumpAndSettle();

        expect(testDb.activeChartIdsSet, ['chart_2']);
        expect(find.byType(ChartSelectionScreen), findsOneWidget);
      },
    );

    testWidgets('renders active chart styling and inactive chart styling', (
      WidgetTester tester,
    ) async {
      testDb.availableChartsToReturn = [
        {
          'id': 'chart_1',
          'emails': ['user@example.com'],
        },
        {
          'id': 'chart_2',
          'emails': ['user@example.com'],
        },
      ];
      testDb.currentChartIdOverride = 'chart_1';

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final activeCard = tester.widget<Card>(
        find.ancestor(
          of: find.text('Chart ID: chart_1'),
          matching: find.byType(Card),
        ),
      );
      expect(activeCard.shape, isA<RoundedRectangleBorder>());
      final border = (activeCard.shape as RoundedRectangleBorder).side;
      expect(border.width, 2.0);

      final inactiveCard = tester.widget<Card>(
        find.ancestor(
          of: find.text('Chart ID: chart_2'),
          matching: find.byType(Card),
        ),
      );
      expect(inactiveCard.shape, isNull);

      final activeTile = find.ancestor(
        of: find.text('Chart ID: chart_1'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: activeTile,
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );

      final inactiveTile = find.ancestor(
        of: find.text('Chart ID: chart_2'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: inactiveTile,
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders "My Solo Chart" when no partner emails exist or emails list is null',
      (WidgetTester tester) async {
        testDb.availableChartsToReturn = [
          {
            'id': 'chart_solo_1',
            'emails': ['user@example.com'],
          },
          {'id': 'chart_solo_no_emails'},
        ];

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('My Solo Chart'), findsNWidgets(2));
      },
    );

    testWidgets('renders "Shared with: ..." when partner emails exist', (
      WidgetTester tester,
    ) async {
      testDb.availableChartsToReturn = [
        {
          'id': 'chart_shared_1',
          'emails': ['user@example.com', 'partner@example.com'],
        },
        {
          'id': 'chart_shared_multi',
          'emails': [
            'user@example.com',
            'alice@example.com',
            'bob@example.com',
          ],
        },
      ];

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Shared with: partner@example.com'), findsOneWidget);
      expect(
        find.text('Shared with: alice@example.com, bob@example.com'),
        findsOneWidget,
      );
    });
  });

  group('Group C: Empty States & Chart Creation', () {
    testWidgets('renders empty state when availableChartsToReturn is empty', (
      WidgetTester tester,
    ) async {
      testDb.availableChartsToReturn = [];

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to PetalCount!'), findsOneWidget);
      expect(
        find.text(
          'Create your first chart to start tracking cycles, or accept a partner\'s invitation.',
        ),
        findsOneWidget,
      );
      expect(find.text('Create First Chart'), findsOneWidget);
      expect(find.text('Create New Chart'), findsNothing);
    });

    testWidgets('creates first chart when tapping "Create First Chart"', (
      WidgetTester tester,
    ) async {
      testDb.availableChartsToReturn = [];

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create First Chart'));
      await tester.pumpAndSettle();

      expect(testDb.createChartCallCount, 1);
    });

    testWidgets(
      'creates chart when tapping "Create New Chart" with existing charts',
      (WidgetTester tester) async {
        testDb.availableChartsToReturn = [
          {
            'id': 'chart_1',
            'emails': ['user@example.com'],
          },
        ];

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Create New Chart'), findsOneWidget);
        await tester.tap(find.text('Create New Chart'));
        await tester.pumpAndSettle();

        expect(testDb.createChartCallCount, 1);
      },
    );

    testWidgets(
      'chart creation error displays red SnackBar with Dismiss action',
      (WidgetTester tester) async {
        testDb.shouldFailCreateChart = true;

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create New Chart'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Error creating chart:'), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, Colors.red);

        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });

  group('Group D: AppBar & Navigation State', () {
    testWidgets('with active chart: shows back button and pops on press', (
      WidgetTester tester,
    ) async {
      testDb.currentChartIdOverride = 'chart_1';

      await tester.pumpWidget(buildTestApp(pushRoute: true));
      await tester.tap(find.text('Open Chart Selection'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(ChartSelectionScreen), findsNothing);
    });

    testWidgets(
      'without active chart: hides back button, shows logout button and calls signOut',
      (WidgetTester tester) async {
        testDb.currentChartIdOverride = null;

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsNothing);
        expect(find.byIcon(Icons.logout), findsOneWidget);

        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        expect(testDb.signOutCallCount, 1);
      },
    );
  });
}
