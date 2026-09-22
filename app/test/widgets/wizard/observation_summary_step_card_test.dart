import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/observation.dart';
import 'package:petal_count/widgets/wizard/observation_summary_step_card.dart';

void main() {
  late TextEditingController commentController;

  setUp(() {
    commentController = TextEditingController();
  });

  tearDown(() {
    commentController.dispose();
  });

  Widget buildTestWidget({
    DateTime? combinedDateTime,
    bool showBleeding = true,
    bool hasBleeding = false,
    Bleeding? bleedingFlow,
    String? bleedingColor,
    bool showMucus = true,
    Sensation? sensation,
    bool hasLubrication = false,
    bool hasMucus = false,
    Stretch? stretch,
    List<MucusColor> selectedColors = const [],
    Frequency frequency = Frequency.none,
    bool showPain = true,
    bool hasPain = false,
    List<String> formattedPainTypes = const [],
    double painLevel = 0.0,
    bool showIntercourse = true,
    bool? hasIntercourse,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 800,
          child: ObservationSummaryStepCard(
            combinedDateTime: combinedDateTime ?? DateTime(2025, 5, 10, 14, 30),
            showBleeding: showBleeding,
            hasBleeding: hasBleeding,
            bleedingFlow: bleedingFlow,
            bleedingColor: bleedingColor,
            showMucus: showMucus,
            sensation: sensation,
            hasLubrication: hasLubrication,
            hasMucus: hasMucus,
            stretch: stretch,
            selectedColors: selectedColors,
            frequency: frequency,
            showPain: showPain,
            hasPain: hasPain,
            formattedPainTypes: formattedPainTypes,
            painLevel: painLevel,
            showIntercourse: showIntercourse,
            hasIntercourse: hasIntercourse,
            commentController: commentController,
          ),
        ),
      ),
    );
  }

  group('ObservationSummaryStepCard Widget & Unit Tests', () {
    testWidgets('renders basic layout headers and observation date', (
      WidgetTester tester,
    ) async {
      final testDate = DateTime(2025, 5, 10, 14, 30);
      await tester.pumpWidget(buildTestWidget(combinedDateTime: testDate));

      expect(find.text('Summary & Additional Notes'), findsOneWidget);
      expect(find.text('Observation Summary:'), findsOneWidget);
      expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
      expect(find.textContaining('Date: May 10, 2025'), findsOneWidget);
      expect(find.text('Comments / Notes (Optional):'), findsOneWidget);
    });

    group('Bleeding Section', () {
      testWidgets('renders Bleeding: None when hasBleeding is false', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(hasBleeding: false));
        expect(find.text('Bleeding: None'), findsOneWidget);
      });

      testWidgets(
        'renders bleeding flow label and color name when hasBleeding is true',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              hasBleeding: true,
              bleedingFlow: Bleeding.heavy,
              bleedingColor: Bleeding.red.code,
            ),
          );
          expect(find.text('Bleeding: Heavy, Red'), findsOneWidget);
        },
      );

      testWidgets('defaults flow label to Light when bleedingFlow is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            hasBleeding: true,
            bleedingFlow: null,
            bleedingColor: Bleeding.brown.code,
          ),
        );
        expect(find.text('Bleeding: Light, Brown'), findsOneWidget);
      });

      testWidgets(
        'renders bleeding color Black when bleedingColor matches Bleeding.black.code',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              hasBleeding: true,
              bleedingFlow: Bleeding.moderate,
              bleedingColor: Bleeding.black.code,
            ),
          );
          expect(find.text('Bleeding: Moderate, Black'), findsOneWidget);
        },
      );

      testWidgets(
        'renders bleeding flow label without color suffix when bleedingColor is null',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              hasBleeding: true,
              bleedingFlow: Bleeding.moderate,
              bleedingColor: null,
            ),
          );
          expect(find.text('Bleeding: Moderate'), findsOneWidget);

          // Verify default Light flow when bleedingFlow is also null
          await tester.pumpWidget(
            buildTestWidget(
              hasBleeding: true,
              bleedingFlow: null,
              bleedingColor: null,
            ),
          );
          expect(find.text('Bleeding: Light'), findsOneWidget);
        },
      );
    });

    group('Mucus & Sensation Section', () {
      testWidgets(
        'renders default Dry sensation and Mucus None when hasMucus is false',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestWidget(hasMucus: false, sensation: null),
          );
          expect(find.text('Sensation: Dry'), findsOneWidget);
          expect(find.text('Mucus: None'), findsOneWidget);
        },
      );

      testWidgets('formats sensation with lubrication annotation when hasLubrication is true', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(sensation: Sensation.wet, hasLubrication: true),
        );
        expect(find.text('Sensation: Wet (Lubricative)'), findsOneWidget);
      });

      testWidgets(
        'renders non-lubricated sensation without annotation when hasLubrication is false',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestWidget(sensation: Sensation.damp, hasLubrication: false),
          );
          expect(find.text('Sensation: Damp'), findsOneWidget);

          await tester.pumpWidget(
            buildTestWidget(sensation: Sensation.wet, hasLubrication: false),
          );
          expect(find.text('Sensation: Wet'), findsOneWidget);
        },
      );

      testWidgets('formats mucus color logic (_formatMucusColor)', (
        WidgetTester tester,
      ) async {
        // Case 1: Empty selected colors defaults to Cloudy
        await tester.pumpWidget(
          buildTestWidget(hasMucus: true, selectedColors: []),
        );
        expect(find.text('Mucus: Sticky, Cloudy'), findsOneWidget);

        // Case 2: Single color selection
        await tester.pumpWidget(
          buildTestWidget(hasMucus: true, selectedColors: [MucusColor.clear]),
        );
        expect(find.text('Mucus: Sticky, Clear'), findsOneWidget);

        // Case 3: Multi-color selection with custom stretch
        await tester.pumpWidget(
          buildTestWidget(
            hasMucus: true,
            stretch: Stretch.stretchy,
            selectedColors: [MucusColor.clear, MucusColor.yellow],
          ),
        );
        expect(
          find.text('Mucus: Stretchy (1 inch or more), Clear/Yellow'),
          findsOneWidget,
        );
      });

      testWidgets(
        'defaults stretch label to Sticky fallback when stretch is null and hasMucus is true',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestWidget(hasMucus: true, stretch: null),
          );
          expect(find.text('Mucus: Sticky, Cloudy'), findsOneWidget);

          await tester.pumpWidget(
            buildTestWidget(
              hasMucus: true,
              stretch: null,
              selectedColors: [MucusColor.clear],
            ),
          );
          expect(find.text('Mucus: Sticky, Clear'), findsOneWidget);
        },
      );
    });

    group('Frequency Section', () {
      testWidgets('omits frequency label when frequency is Frequency.none', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(frequency: Frequency.none));
        expect(find.textContaining('Frequency:'), findsNothing);
      });

      testWidgets('renders frequency label when specified', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(frequency: Frequency.twice));
        expect(find.text('Frequency: Twice (x2)'), findsOneWidget);
      });

      testWidgets('renders frequency label for Frequency.allDay', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(frequency: Frequency.allDay));
        expect(find.text('Frequency: All Day (AD)'), findsOneWidget);
      });
    });

    group('Pain Section', () {
      testWidgets('renders Pain: None when hasPain is false', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(hasPain: false));
        expect(find.text('Pain: None'), findsOneWidget);
      });

      testWidgets('renders pain badge/details and formatted pain types', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            hasPain: true,
            formattedPainTypes: ['Cramps (Mild)', 'Backache'],
            painLevel: 6.0,
          ),
        );
        expect(
          find.text('Pain: Cramps (Mild), Backache (6/10)'),
          findsOneWidget,
        );
      });

      testWidgets('fallback text Logged when formattedPainTypes is empty', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            hasPain: true,
            formattedPainTypes: [],
            painLevel: 4.0,
          ),
        );
        expect(find.text('Pain: Logged (4/10)'), findsOneWidget);
      });

      testWidgets(
        'truncates floating-point pain level double to integer representation',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              hasPain: true,
              formattedPainTypes: ['Cramps'],
              painLevel: 7.8,
            ),
          );
          expect(find.text('Pain: Cramps (7/10)'), findsOneWidget);
        },
      );
    });

    group('Intercourse Section', () {
      testWidgets('renders Intercourse: Yes when hasIntercourse is true', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(hasIntercourse: true));
        expect(find.text('Intercourse: Yes'), findsOneWidget);
      });

      testWidgets('renders Intercourse: No when hasIntercourse is false', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(hasIntercourse: false));
        expect(find.text('Intercourse: No'), findsOneWidget);
      });

      testWidgets(
        'omits intercourse summary line when hasIntercourse is null',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(hasIntercourse: null));
          expect(find.textContaining('Intercourse:'), findsNothing);
        },
      );
    });

    group('Conditional Visibility Flags', () {
      testWidgets('omits sections when show flags are set to false', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            showBleeding: false,
            showMucus: false,
            showPain: false,
            showIntercourse: false,
            hasIntercourse: true,
          ),
        );

        expect(find.textContaining('Bleeding:'), findsNothing);
        expect(find.textContaining('Sensation:'), findsNothing);
        expect(find.textContaining('Mucus:'), findsNothing);
        expect(find.textContaining('Pain:'), findsNothing);
        expect(find.textContaining('Intercourse:'), findsNothing);
      });
    });

    group('Comments Text Field', () {
      testWidgets(
        'displays initial controller text and updates on user input',
        (WidgetTester tester) async {
          commentController.text = 'Initial note';
          await tester.pumpWidget(buildTestWidget());

          expect(find.text('Initial note'), findsOneWidget);

          await tester.enterText(find.byType(TextField), 'Updated test note');
          await tester.pump();

          expect(commentController.text, equals('Updated test note'));
          expect(find.text('Updated test note'), findsOneWidget);
        },
      );
    });
  });
}
