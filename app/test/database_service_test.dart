import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/services/database_service.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() {
    db = InMemoryDatabaseService();
  });

  test('InMemoryDatabaseService initial state has a currentChartId', () {
    expect(db.currentChartId, 'mock_shared_chart');
    expect(db.currentUser, isNotNull);
  });

  test('unlinkChart sets currentChartId to null and clears cache', () async {
    expect(db.currentChartId, 'mock_shared_chart');

    await db.unlinkChart();

    expect(db.currentChartId, isNull);
  });

  test('unlinkChart triggers authStateChanges stream broadcast', () async {
    final userStates = <Object?>[];
    final subscription = db.authStateChanges.listen((user) {
      userStates.add(user);
    });

    // Perform unlink which triggers auth controller event
    await db.unlinkChart();

    await Future.delayed(Duration.zero); // Allow stream to flush events

    expect(userStates, isNotEmpty);
    expect(db.currentChartId, isNull);

    await subscription.cancel();
  });
}
