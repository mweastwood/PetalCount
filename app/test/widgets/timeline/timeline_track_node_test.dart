import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/creighton_stamp_widget.dart';
import 'package:petal_count/widgets/timeline/timeline_track_node.dart';

void main() {
  group('TimelineTrackNode Unit & Widget Tests', () {
    testWidgets('renders day number and Creighton stamp node', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimelineTrackNode(
              stampType: StampType.green,
              peakDayLabel: '1',
              dayNumber: 14,
            ),
          ),
        ),
      );

      expect(find.byType(CreightonStampWidget), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      final trackSizedBox = tester.widget<SizedBox>(
        find.byType(SizedBox).first,
      );
      expect(trackSizedBox.width, equals(56));
    });

    testWidgets('invokes onTap callback when tapped', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineTrackNode(
              stampType: StampType.whiteBaby,
              dayNumber: 5,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });

    testWidgets('renders without error when stampType and onTap are null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TimelineTrackNode(dayNumber: 1)),
        ),
      );

      expect(find.byType(CreightonStampWidget), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
