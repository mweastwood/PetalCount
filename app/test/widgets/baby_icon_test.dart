import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/theme/baby_svg.dart';
import 'package:petal_count/theme/creighton_theme.dart';
import 'package:petal_count/widgets/baby_icon.dart';

void main() {
  group('BabySvg Unit Tests', () {
    test('assetPath points to baby_swaddled.svg', () {
      expect(BabySvg.assetPath, 'assets/images/baby_swaddled.svg');
    });

    test(
      'getSvg generates valid SVG string with default and custom colors',
      () {
        final defaultSvg = BabySvg.getSvg();
        expect(defaultSvg, contains('<svg'));
        expect(defaultSvg, contains('viewBox="0 0 64 64"'));
        expect(defaultSvg, contains('stroke="#2E7D32"'));

        final whiteSvg = BabySvg.getSvg(strokeColor: '#FFFFFF');
        expect(whiteSvg, contains('stroke="#FFFFFF"'));

        final blackSvg = BabySvg.getSvg(strokeColor: '#000000');
        expect(blackSvg, contains('stroke="#000000"'));
      },
    );
  });

  group('BabyIcon Widget Tests', () {
    testWidgets('Renders BabyIcon with default properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: BabyIcon())),
        ),
      );

      expect(find.byType(BabyIcon), findsOneWidget);
    });

    testWidgets('Renders BabyIcon with custom size and color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BabyIcon(
                size: 32,
                color: CreightonTheme.babyIconDarkGreen,
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(BabyIcon);
      expect(iconFinder, findsOneWidget);

      final babyIcon = tester.widget<BabyIcon>(iconFinder);
      expect(babyIcon.size, 32);
      expect(babyIcon.color, CreightonTheme.babyIconDarkGreen);
    });

    testGoldens('BabyIcon renders swaddled sleeping baby golden', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.grey.shade100,
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // White stamp variant
                  Container(
                    width: 50,
                    height: 50,
                    color: Colors.white,
                    child: const Center(
                      child: BabyIcon(
                        size: 26,
                        color: CreightonTheme.babyIconDarkGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Green stamp variant
                  Container(
                    width: 50,
                    height: 50,
                    color: CreightonTheme.greenStamp,
                    child: const Center(
                      child: BabyIcon(size: 26, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Yellow stamp variant
                  Container(
                    width: 50,
                    height: 50,
                    color: CreightonTheme.yellowStamp,
                    child: const Center(
                      child: BabyIcon(
                        size: 26,
                        color: CreightonTheme.babyIconGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        surfaceSize: const Size(300, 150),
      );

      await screenMatchesGolden(tester, 'baby_icon_stamps');
    });
  });
}
