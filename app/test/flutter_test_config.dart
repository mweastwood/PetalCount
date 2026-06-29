import 'dart:async';
import 'dart:io';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  return GoldenToolkit.runWithConfiguration(
    () async {
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      skipGoldenAssertion: () => Platform.environment.containsKey('CI'),
    ),
  );
}
