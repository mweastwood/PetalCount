import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/main.dart';
import 'package:petal_count/services/services.dart';

void main() {
  setUpAll(() async {
    // Initialize our Services layer with mock/in-memory services for golden screenshot testing
    await Services.init();
  });

  testGoldens('Dashboard renders correctly in initial state', (tester) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await screenMatchesGolden(tester, 'dashboard_screen_initial');
  });
}
