import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    test('getSvg matches canonical assets/images/baby_swaddled.svg file', () {
      final assetPath = File(BabySvg.assetPath).existsSync()
          ? BabySvg.assetPath
          : 'app/${BabySvg.assetPath}';
      final file = File(assetPath);
      expect(file.existsSync(), isTrue);
      final assetContent = file.readAsStringSync();

      // Normalize stroke="currentColor" to stroke="#2E7D32" and compare whitespace-trimmed lines
      final expectedFromAsset = assetContent
          .replaceAll('stroke="currentColor"', 'stroke="#2E7D32"')
          .replaceAll('\r\n', '\n')
          .trim();
      final actualSvg = BabySvg.getSvg().replaceAll('\r\n', '\n').trim();

      expect(actualSvg, expectedFromAsset);
    });

    test(
      'getSvg generates valid SVG string with default, unhashed, and custom colors',
      () {
        final defaultSvg = BabySvg.getSvg();
        expect(defaultSvg, contains('<svg'));
        expect(defaultSvg, contains('viewBox="0 0 64 64"'));
        expect(defaultSvg, contains('stroke="#2E7D32"'));

        final whiteSvg = BabySvg.getSvg(strokeColor: '#FFFFFF');
        expect(whiteSvg, contains('stroke="#FFFFFF"'));

        final unhashedSvg = BabySvg.getSvg(strokeColor: 'FFFFFF');
        expect(unhashedSvg, contains('stroke="#FFFFFF"'));

        final currentColorSvg = BabySvg.getSvg(strokeColor: 'currentColor');
        expect(currentColorSvg, contains('stroke="currentColor"'));

        final rgbSvg = BabySvg.getSvg(strokeColor: 'rgb(46, 125, 50)');
        expect(rgbSvg, contains('stroke="rgb(46, 125, 50)"'));

        final blackSvg = BabySvg.getSvg(strokeColor: '#000000');
        expect(blackSvg, contains('stroke="#000000"'));
      },
    );
  });

  group('BabyIcon Widget Tests', () {
    testWidgets('Renders BabyIcon with default properties and semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: BabyIcon())),
        ),
      );

      expect(find.byType(BabyIcon), findsOneWidget);

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final svgWidget = tester.widget<SvgPicture>(svgFinder);
      expect(svgWidget.width, 24.0);
      expect(svgWidget.height, 24.0);
      expect(svgWidget.semanticsLabel, 'Baby icon');
      expect(
        svgWidget.colorFilter,
        const ColorFilter.mode(CreightonTheme.babyIconGreen, BlendMode.srcIn),
      );
    });

    testWidgets(
      'Renders BabyIcon with custom size, color, and semanticsLabel',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: BabyIcon(
                  size: 32,
                  color: CreightonTheme.babyIconDarkGreen,
                  semanticsLabel: 'Fertile day baby symbol',
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
        expect(babyIcon.semanticsLabel, 'Fertile day baby symbol');

        final svgWidget = tester.widget<SvgPicture>(find.byType(SvgPicture));
        expect(svgWidget.width, 32);
        expect(svgWidget.height, 32);
        expect(svgWidget.semanticsLabel, 'Fertile day baby symbol');
        expect(
          svgWidget.colorFilter,
          const ColorFilter.mode(
            CreightonTheme.babyIconDarkGreen,
            BlendMode.srcIn,
          ),
        );
      },
    );

    testWidgets('BabyIcon preserves alpha and transparency via ColorFilter', (
      tester,
    ) async {
      const translucentGreen = Color(0x802E7D32); // 50% opacity green
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: BabyIcon(color: translucentGreen)),
          ),
        ),
      );

      final svgWidget = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        svgWidget.colorFilter,
        const ColorFilter.mode(translucentGreen, BlendMode.srcIn),
      );
    });

    testWidgets('BabyIcon respects excludeFromSemantics flag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: BabyIcon(excludeFromSemantics: true)),
          ),
        ),
      );

      final svgWidget = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgWidget.excludeFromSemantics, isTrue);
      expect(svgWidget.semanticsLabel, isNull);
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
