import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

class LocalFileComparatorWithTolerance extends LocalFileComparator {
  final double maxDiffPercent;

  LocalFileComparatorWithTolerance(super.testFile, this.maxDiffPercent);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    if (autoUpdateGoldenFiles) {
      await update(golden, imageBytes);
      return true;
    }

    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (!result.passed && result.diffPercent > maxDiffPercent) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return true;
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  if (goldenFileComparator is LocalFileComparator) {
    final testUrl = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = LocalFileComparatorWithTolerance(
      Uri.parse('$testUrl/test.dart'),
      0.0, // Strict 0% golden diff tolerance
    );
  }
  return GoldenToolkit.runWithConfiguration(() async {
    await testMain();
  }, config: GoldenToolkitConfiguration());
}
