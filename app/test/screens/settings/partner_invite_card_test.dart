import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings/partner_invite_card.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    Services.notifications = InMemoryNotificationService();
  });

  group('PartnerInviteCard Tests', () {
    testWidgets('renders email input and invite button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PartnerInviteCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invite Partner to Collaborate'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Send Collaboration Invite'), findsOneWidget);
    });

    testWidgets('entering email and submitting sends invite successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PartnerInviteCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'partner@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Collaboration Invite'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Invitation successfully sent to partner@example.com!',
        ),
        findsOneWidget,
      );
    });
  });
}
