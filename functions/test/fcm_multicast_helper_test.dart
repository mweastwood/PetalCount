import 'package:functions/src/interop/firebase_admin.dart';
import 'package:functions/src/reminders.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('fcm_multicast_helper unit tests', () {
    test(
      'fetchUsersInBatches chunks user queries and respects chunkSize',
      () async {
        final mockDb = MockFirestoreDatabase();
        for (var i = 1; i <= 5; i++) {
          mockDb.collection('users').doc('u_$i').docData = {
            'uid': 'u_$i',
            'role': 'wife',
          };
        }

        final users = await fetchUsersInBatches(
          mockDb,
          ['u_1', 'u_2', 'u_3', 'u_4', 'u_5'],
          chunkSize: 2,
        );

        expect(users.keys, containsAll(['u_1', 'u_2', 'u_3', 'u_4', 'u_5']));
        expect(mockDb.getAllCalls.length, equals(3));
        expect(mockDb.getAllCalls[0].length, equals(2));
        expect(mockDb.getAllCalls[1].length, equals(2));
        expect(mockDb.getAllCalls[2].length, equals(1));
      },
    );

    test(
      'buildFcmMulticastPayload includes badge when apnsBadge is provided and omits when null',
      () {
        final withBadge = buildFcmMulticastPayload(
          tokens: ['t1'],
          title: 'Title',
          body: 'Body',
          data: {'type': 'test'},
          androidChannelId: 'channel_1',
          apnsBadge: 1,
        );
        final apsWithBadge =
            ((withBadge['apns'] as Map)['payload'] as Map)['aps'] as Map;
        expect(apsWithBadge['badge'], equals(1));

        final withoutBadge = buildFcmMulticastPayload(
          tokens: ['t1'],
          title: 'Title',
          body: 'Body',
          data: {'type': 'test'},
          androidChannelId: 'channel_2',
        );
        final apsWithoutBadge =
            ((withoutBadge['apns'] as Map)['payload'] as Map)['aps'] as Map;
        expect(apsWithoutBadge.containsKey('badge'), isFalse);
      },
    );

    test(
      'collectInvalidFcmTokens filters only invalid and unregistered token errors',
      () {
        const response = BatchResponse(
          successCount: 1,
          failureCount: 3,
          responses: [
            SendResponse(success: true),
            SendResponse(
              success: false,
              errorCode: 'messaging/invalid-registration-token',
            ),
            SendResponse(
              success: false,
              errorCode: 'messaging/internal-error',
            ),
            SendResponse(
              success: false,
              errorCode: 'messaging/registration-token-not-registered',
            ),
          ],
        );

        final invalid = collectInvalidFcmTokens(
          response,
          ['tok_ok', 'tok_invalid', 'tok_transient', 'tok_unregistered'],
        );
        expect(invalid, equals({'tok_invalid', 'tok_unregistered'}));
      },
    );
  });
}
