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

  test('streamAvailableCharts streams all charts linked to user', () async {
    final chartsList = await db.streamAvailableCharts().first;
    expect(chartsList.length, 1);
    expect(chartsList.first['id'], 'mock_shared_chart');
  });

  test('setActiveChart updates currentChartId', () async {
    await db.setActiveChart('another_mock_chart');
    expect(db.currentChartId, 'another_mock_chart');
  });

  test(
    'createChart creates a new chart, sets it active, and streams it',
    () async {
      final initialCharts = await db.streamAvailableCharts().first;
      expect(initialCharts.length, 1);

      await db.createChart();

      final updatedCharts = await db.streamAvailableCharts().first;
      expect(updatedCharts.length, 2);
      expect(db.currentChartId, startsWith('chart_'));
    },
  );

  test(
    'deleteChart permanently deletes a chart and clears user link',
    () async {
      final initialCharts = await db.streamAvailableCharts().first;
      expect(initialCharts.length, 1);
      final activeId = db.currentChartId;
      expect(activeId, isNotNull);

      await db.deleteChart(activeId!);

      final updatedCharts = await db.streamAvailableCharts().first;
      expect(updatedCharts, isEmpty);
      expect(db.currentChartId, isNull);
    },
  );
}
