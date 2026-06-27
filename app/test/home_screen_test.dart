import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/main.dart';

void main() {
  testGoldens('HomeScreen renders correctly in initial state', (tester) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await screenMatchesGolden(tester, 'home_screen_initial');
  });
}
