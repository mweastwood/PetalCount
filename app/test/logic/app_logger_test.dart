import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/app_logger.dart';

void main() {
  group('AppLogger & AppLogEvent Unit Tests', () {
    test('AppLogEvent serializes to JSON correctly', () {
      final now = DateTime.utc(2026, 8, 16, 12, 0, 0);
      final event = AppLogEvent(
        timestamp: now,
        level: LogLevel.error,
        category: 'observation',
        message: 'Failed to write observation',
        metadata: {'chartId': 'chart_123', 'userId': 'user_abc'},
        error: 'FirebaseException: permission-denied',
        stackTrace: 'stack trace line 1',
      );

      final json = event.toJson();
      expect(json['timestamp'], '2026-08-16T12:00:00.000Z');
      expect(json['level'], 'error');
      expect(json['category'], 'observation');
      expect(json['message'], 'Failed to write observation');
      expect(json['metadata'], {'chartId': 'chart_123', 'userId': 'user_abc'});
      expect(json['error'], 'FirebaseException: permission-denied');
      expect(json['stackTrace'], 'stack trace line 1');
    });

    test('AppLogger records debug, info, warning, and error events', () {
      final logger = AppLogger(maxCapacity: 10);
      expect(logger.logs, isEmpty);

      logger.debug('Debug test', category: 'auth', metadata: {'key': 'val'});
      logger.info('Info test', category: 'cycle');
      logger.warning('Warning test', category: 'db');
      logger.error(
        'Error test',
        category: 'firestore',
        error: Exception('test err'),
      );

      expect(logger.length, 4);
      expect(logger.logs[0].level, LogLevel.debug);
      expect(logger.logs[0].category, 'auth');
      expect(logger.logs[0].metadata?['key'], 'val');

      expect(logger.logs[1].level, LogLevel.info);
      expect(logger.logs[2].level, LogLevel.warning);
      expect(logger.logs[3].level, LogLevel.error);
      expect(logger.logs[3].error, contains('test err'));
    });

    test('AppLogger bounds ring buffer to maxCapacity and evicts FIFO', () {
      final logger = AppLogger(maxCapacity: 3);

      logger.info('Message 1');
      logger.info('Message 2');
      logger.info('Message 3');
      expect(logger.length, 3);
      expect(logger.logs.map((e) => e.message).toList(), [
        'Message 1',
        'Message 2',
        'Message 3',
      ]);

      // Adding 4th message should evict Message 1
      logger.info('Message 4');
      expect(logger.length, 3);
      expect(logger.logs.map((e) => e.message).toList(), [
        'Message 2',
        'Message 3',
        'Message 4',
      ]);

      // Adding 5th message should evict Message 2
      logger.info('Message 5');
      expect(logger.length, 3);
      expect(logger.logs.map((e) => e.message).toList(), [
        'Message 3',
        'Message 4',
        'Message 5',
      ]);
    });

    test('AppLogger clear() removes all recorded logs', () {
      final logger = AppLogger(maxCapacity: 5);
      logger.info('Item 1');
      logger.info('Item 2');
      expect(logger.length, 2);

      logger.clear();
      expect(logger.length, 0);
      expect(logger.logs, isEmpty);
    });
  });
}
