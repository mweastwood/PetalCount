import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';

class _MockBatch {
  final int id;
  final List<String> operations = [];
  bool committed = false;

  _MockBatch(this.id);
}

void main() {
  group('FirebaseDatabaseService batch chunking logic', () {
    test('does nothing when operations list is empty', () async {
      int batchCount = 0;
      final committedBatches = <_MockBatch>[];

      await FirebaseDatabaseService.commitBatchedOperations<_MockBatch>(
        operations: [],
        batchFactory: () => _MockBatch(++batchCount),
        commitBatch: (batch) async {
          batch.committed = true;
          committedBatches.add(batch);
        },
      );

      expect(batchCount, 0);
      expect(committedBatches, isEmpty);
    });

    test('executes small dataset (<= batchLimit) in a single batch', () async {
      int batchCount = 0;
      final committedBatches = <_MockBatch>[];

      final operations = List<void Function(_MockBatch)>.generate(
        100,
        (i) =>
            (batch) => batch.operations.add('op_$i'),
      );

      await FirebaseDatabaseService.commitBatchedOperations<_MockBatch>(
        operations: operations,
        batchFactory: () => _MockBatch(++batchCount),
        commitBatch: (batch) async {
          batch.committed = true;
          committedBatches.add(batch);
        },
      );

      expect(batchCount, 1);
      expect(committedBatches.length, 1);
      expect(committedBatches.first.committed, isTrue);
      expect(committedBatches.first.operations.length, 100);
      expect(committedBatches.first.operations.first, 'op_0');
      expect(committedBatches.first.operations.last, 'op_99');
    });

    test('executes exactly batchLimit operations in a single batch', () async {
      int batchCount = 0;
      final committedBatches = <_MockBatch>[];

      final operations = List<void Function(_MockBatch)>.generate(
        450,
        (i) =>
            (batch) => batch.operations.add('op_$i'),
      );

      await FirebaseDatabaseService.commitBatchedOperations<_MockBatch>(
        operations: operations,
        batchFactory: () => _MockBatch(++batchCount),
        commitBatch: (batch) async {
          batch.committed = true;
          committedBatches.add(batch);
        },
      );

      expect(batchCount, 1);
      expect(committedBatches.length, 1);
      expect(committedBatches.first.operations.length, 450);
    });

    test(
      'chunks >500 operations (> Firestore limit) into batches <= 450 operations',
      () async {
        int batchCount = 0;
        final committedBatches = <_MockBatch>[];

        // 501 operations: should produce 2 batches (450 + 51)
        final operations = List<void Function(_MockBatch)>.generate(
          501,
          (i) =>
              (batch) => batch.operations.add('op_$i'),
        );

        await FirebaseDatabaseService.commitBatchedOperations<_MockBatch>(
          operations: operations,
          batchFactory: () => _MockBatch(++batchCount),
          commitBatch: (batch) async {
            batch.committed = true;
            committedBatches.add(batch);
          },
        );

        expect(batchCount, 2);
        expect(committedBatches.length, 2);
        expect(committedBatches[0].operations.length, 450);
        expect(committedBatches[1].operations.length, 51);

        // Verify all operations are committed in sequential order with no loss
        final allCommittedOps = committedBatches
            .expand((b) => b.operations)
            .toList();
        expect(allCommittedOps.length, 501);
        expect(allCommittedOps.first, 'op_0');
        expect(allCommittedOps[449], 'op_449');
        expect(allCommittedOps[450], 'op_450');
        expect(allCommittedOps.last, 'op_500');
      },
    );

    test(
      'simulates large multi-cycle dataset (>1000 operations) with multiple batches',
      () async {
        int batchCount = 0;
        final committedBatches = <_MockBatch>[];

        // Simulate 25 cycles, each with 1 cycle update + 44 daily entries = 45 writes per cycle -> 1125 operations total
        const totalCycles = 25;
        const entriesPerCycle = 44;
        final operations = <void Function(_MockBatch batch)>[];

        for (var c = 0; c < totalCycles; c++) {
          final cycleId = 'cycle_$c';
          operations.add(
            (batch) => batch.operations.add('update_cycle:$cycleId'),
          );
          for (var e = 0; e < entriesPerCycle; e++) {
            operations.add(
              (batch) => batch.operations.add('set_entry:$cycleId:entry_$e'),
            );
          }
        }

        expect(operations.length, 1125);

        await FirebaseDatabaseService.commitBatchedOperations<_MockBatch>(
          operations: operations,
          batchFactory: () => _MockBatch(++batchCount),
          commitBatch: (batch) async {
            batch.committed = true;
            committedBatches.add(batch);
          },
        );

        // 1125 operations / 450 limit = 450 + 450 + 225 = 3 batches
        expect(batchCount, 3);
        expect(committedBatches.length, 3);
        expect(committedBatches[0].operations.length, 450);
        expect(committedBatches[1].operations.length, 450);
        expect(committedBatches[2].operations.length, 225);

        // Verify every batch stayed below Firestore 500 ceiling
        for (final b in committedBatches) {
          expect(b.operations.length, lessThanOrEqualTo(450));
          expect(b.committed, isTrue);
        }

        // Verify complete integrity of all 1125 operations
        final allCommittedOps = committedBatches
            .expand((b) => b.operations)
            .toList();
        expect(allCommittedOps.length, 1125);
        expect(allCommittedOps.first, 'update_cycle:cycle_0');
        expect(allCommittedOps.last, 'set_entry:cycle_24:entry_43');
      },
    );

    test('supports configurable custom batch limit', () async {
      int batchCount = 0;
      final committedBatches = <_MockBatch>[];

      final operations = List<void Function(_MockBatch)>.generate(
        350,
        (i) =>
            (batch) => batch.operations.add('op_$i'),
      );

      await FirebaseDatabaseService.commitBatchedOperations<_MockBatch>(
        operations: operations,
        batchLimit: 100,
        batchFactory: () => _MockBatch(++batchCount),
        commitBatch: (batch) async {
          batch.committed = true;
          committedBatches.add(batch);
        },
      );

      expect(batchCount, 4);
      expect(committedBatches.length, 4);
      expect(committedBatches[0].operations.length, 100);
      expect(committedBatches[1].operations.length, 100);
      expect(committedBatches[2].operations.length, 100);
      expect(committedBatches[3].operations.length, 50);
    });

    test('propagates commit exceptions correctly', () async {
      final operations = List<void Function(_MockBatch)>.generate(
        10,
        (i) =>
            (batch) => batch.operations.add('op_$i'),
      );

      expect(
        () => FirebaseDatabaseService.commitBatchedOperations<_MockBatch>(
          operations: operations,
          batchFactory: () => _MockBatch(1),
          commitBatch: (batch) async {
            throw Exception('Firestore write error');
          },
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Firestore write error'),
          ),
        ),
      );
    });
  });
}
