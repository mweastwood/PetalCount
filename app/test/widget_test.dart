import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/main.dart';

void main() {
  testWidgets('HomeScreen interactive widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PetalCountApp());

    // Verify Hello, World! is shown
    expect(find.text('Hello, World!'), findsOneWidget);
    expect(find.text('0 petals counted'), findsOneWidget);

    // Tap the 'Add Petal' button and trigger a frame.
    await tester.tap(find.widgetWithText(FilledButton, 'Add Petal'));
    await tester.pump();

    // Verify that the label has updated.
    expect(find.text('1 petal counted'), findsOneWidget);
  });
}
