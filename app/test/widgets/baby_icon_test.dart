import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/models/daily_entry.dart';
import 'package:petal_count/theme/baby_svg.dart';
import 'package:petal_count/theme/creighton_theme.dart';
import 'package:petal_count/widgets/baby_icon.dart';

void main() {
  group('BabySvg Unit Tests', () {
    test('assetPath points to baby_swaddled.svg', () {
      expect(BabySvg.assetPath, 'assets/images/baby_swaddled.svg');
    });

    test('rawSvg matches default getSvg()', () {
      expect(BabySvg.rawSvg, BabySvg.getSvg());
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

        // Named CSS / SVG colors should be preserved without prepending '#'
        final namedBlackSvg = BabySvg.getSvg(strokeColor: 'black');
        expect(namedBlackSvg, contains('stroke="black"'));

        final namedWhiteSvg = BabySvg.getSvg(strokeColor: 'white');
        expect(namedWhiteSvg, contains('stroke="white"'));

        final namedNoneSvg = BabySvg.getSvg(strokeColor: 'none');
        expect(namedNoneSvg, contains('stroke="none"'));

        final namedTransparentSvg = BabySvg.getSvg(strokeColor: 'transparent');
        expect(namedTransparentSvg, contains('stroke="transparent"'));
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

    testWidgets(
      'BabyIcon.forStamp properly resolves Creighton colors for stamp types',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  BabyIcon.forStamp(
                    StampType.whiteBaby,
                    key: const ValueKey('whiteBaby'),
                  ),
                  BabyIcon.forStamp(
                    StampType.greenBaby,
                    key: const ValueKey('greenBaby'),
                  ),
                  BabyIcon.forStamp(
                    StampType.yellowBaby,
                    key: const ValueKey('yellowBaby'),
                  ),
                  BabyIcon.forStamp(null, key: const ValueKey('nullStamp')),
                ],
              ),
            ),
          ),
        );

        final whiteSvg = tester.widget<SvgPicture>(
          find.descendant(
            of: find.byKey(const ValueKey('whiteBaby')),
            matching: find.byType(SvgPicture),
          ),
        );
        expect(
          whiteSvg.colorFilter,
          ColorFilter.mode(
            CreightonTheme.getBabyIconColor(StampType.whiteBaby),
            BlendMode.srcIn,
          ),
        );

        final greenSvg = tester.widget<SvgPicture>(
          find.descendant(
            of: find.byKey(const ValueKey('greenBaby')),
            matching: find.byType(SvgPicture),
          ),
        );
        expect(
          greenSvg.colorFilter,
          ColorFilter.mode(
            CreightonTheme.getBabyIconColor(StampType.greenBaby),
            BlendMode.srcIn,
          ),
        );

        final yellowSvg = tester.widget<SvgPicture>(
          find.descendant(
            of: find.byKey(const ValueKey('yellowBaby')),
            matching: find.byType(SvgPicture),
          ),
        );
        expect(
          yellowSvg.colorFilter,
          ColorFilter.mode(
            CreightonTheme.getBabyIconColor(StampType.yellowBaby),
            BlendMode.srcIn,
          ),
        );

        final nullSvg = tester.widget<SvgPicture>(
          find.descendant(
            of: find.byKey(const ValueKey('nullStamp')),
            matching: find.byType(SvgPicture),
          ),
        );
        expect(
          nullSvg.colorFilter,
          ColorFilter.mode(
            CreightonTheme.getBabyIconColor(null),
            BlendMode.srcIn,
          ),
        );
      },
    );

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
