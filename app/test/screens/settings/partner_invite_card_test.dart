import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings/partner_invite_card.dart';

class MockPartnerInviteDatabaseService extends InMemoryDatabaseService {
  Completer<void>? inviteCompleter;
  Object? errorToThrow;

  @override
  Future<void> invitePartner(String partnerEmail) async {
    if (inviteCompleter != null) {
      await inviteCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return super.invitePartner(partnerEmail);
  }
}

void main() {
  late MockPartnerInviteDatabaseService db;

  setUp(() async {
    db = MockPartnerInviteDatabaseService();
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

    testWidgets('displays error message when invite throws exception', (
      WidgetTester tester,
    ) async {
      db.errorToThrow = Exception('Network error');

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

      expect(find.text('Error: Network error'), findsOneWidget);
    });

    testWidgets(
      'does not throw when widget is unmounted before invite completes',
      (WidgetTester tester) async {
        db.inviteCompleter = Completer<void>();

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
        await tester.pump();

        // Unmount the widget by pumping another widget
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        // Complete async operation while widget is unmounted
        db.inviteCompleter!.complete();
        await tester.pumpAndSettle();

        // Should complete cleanly with no FlutterError
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'does not throw when widget is unmounted before invite errors',
      (WidgetTester tester) async {
        db.inviteCompleter = Completer<void>();
        db.errorToThrow = Exception('Delayed network error');

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
        await tester.pump();

        // Unmount the widget
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        // Complete async operation with error while widget is unmounted
        db.inviteCompleter!.complete();
        await tester.pumpAndSettle();

        // Should complete cleanly with no FlutterError
        expect(tester.takeException(), isNull);
      },
    );
  });
}
