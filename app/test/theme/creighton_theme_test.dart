import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/daily_entry.dart';
import 'package:petal_count/theme/creighton_theme.dart';

void main() {
  group('CreightonTheme Layout Dimensions & Corner Radii', () {
    test('layout dimensions match defined design constants', () {
      expect(CreightonTheme.cellWidth, 66.0);
      expect(CreightonTheme.cellHeight, 114.0);
      expect(CreightonTheme.headerRowHeight, 36.0);
      expect(CreightonTheme.cycleHeaderWidth, 110.0);
      expect(CreightonTheme.cellGap, 3.0);
    });

    test('corner radii match defined design constants', () {
      expect(CreightonTheme.cardBorderRadius, 8.0);
      expect(CreightonTheme.stickerBorderRadius, 6.5);
    });
  });

  group('CreightonTheme Color Constants', () {
    test('stamp color constants have expected hex values', () {
      expect(CreightonTheme.redStamp, const Color(0xFFEF5350));
      expect(CreightonTheme.greenStamp, const Color(0xFF66BB6A));
      expect(CreightonTheme.whiteStamp, Colors.white);
      expect(CreightonTheme.yellowStamp, const Color(0xFFFFCA28));
      expect(CreightonTheme.emptyCellBackground, const Color(0xFFFAFAFA));
    });

    test('border and accent color constants have expected hex values', () {
      expect(CreightonTheme.redBorder, const Color(0xFFE53935));
      expect(CreightonTheme.greenBorder, const Color(0xFF43A047));
      expect(CreightonTheme.yellowBorder, const Color(0xFFFDD835));
      expect(CreightonTheme.babyIconGreen, const Color(0xFF2E7D32));
      expect(CreightonTheme.babyIconDarkGreen, const Color(0xFF388E3C));
      expect(CreightonTheme.peakBadgeRed, const Color(0xFFD32F2F));
    });
  });

  group('CreightonTheme.getStampColor', () {
    test('returns redStamp for red stamp type', () {
      expect(
        CreightonTheme.getStampColor(StampType.red),
        CreightonTheme.redStamp,
      );
    });

    test('returns greenStamp for green stamp type', () {
      expect(
        CreightonTheme.getStampColor(StampType.green),
        CreightonTheme.greenStamp,
      );
    });

    test('returns whiteStamp for whiteBaby stamp type', () {
      expect(
        CreightonTheme.getStampColor(StampType.whiteBaby),
        CreightonTheme.whiteStamp,
      );
    });

    test('returns greenStamp for greenBaby stamp type', () {
      expect(
        CreightonTheme.getStampColor(StampType.greenBaby),
        CreightonTheme.greenStamp,
      );
    });

    test('returns yellowStamp for yellow stamp type', () {
      expect(
        CreightonTheme.getStampColor(StampType.yellow),
        CreightonTheme.yellowStamp,
      );
    });

    test('returns yellowStamp for yellowBaby stamp type', () {
      expect(
        CreightonTheme.getStampColor(StampType.yellowBaby),
        CreightonTheme.yellowStamp,
      );
    });

    test('returns emptyCellBackground when stamp type is null', () {
      expect(
        CreightonTheme.getStampColor(null),
        CreightonTheme.emptyCellBackground,
      );
    });

    test(
      'returns custom defaultColor when stamp type is null and defaultColor is provided',
      () {
        const customDefault = Color(0xFF123456);
        expect(
          CreightonTheme.getStampColor(null, defaultColor: customDefault),
          customDefault,
        );
      },
    );
  });

  group('CreightonTheme.getBorderColor', () {
    test('returns redBorder for red stamp type', () {
      expect(
        CreightonTheme.getBorderColor(StampType.red),
        CreightonTheme.redBorder,
      );
    });

    test(
      'returns greenBorder for green, whiteBaby, and greenBaby stamp types',
      () {
        expect(
          CreightonTheme.getBorderColor(StampType.green),
          CreightonTheme.greenBorder,
        );
        expect(
          CreightonTheme.getBorderColor(StampType.whiteBaby),
          CreightonTheme.greenBorder,
        );
        expect(
          CreightonTheme.getBorderColor(StampType.greenBaby),
          CreightonTheme.greenBorder,
        );
      },
    );

    test('returns yellowBorder for yellow and yellowBaby stamp types', () {
      expect(
        CreightonTheme.getBorderColor(StampType.yellow),
        CreightonTheme.yellowBorder,
      );
      expect(
        CreightonTheme.getBorderColor(StampType.yellowBaby),
        CreightonTheme.yellowBorder,
      );
    });

    test('returns default border color 0xFFE0E0E0 when stamp type is null', () {
      expect(CreightonTheme.getBorderColor(null), const Color(0xFFE0E0E0));
    });

    test(
      'returns custom defaultColor when stamp type is null and defaultColor is provided',
      () {
        const customDefault = Color(0xFF654321);
        expect(
          CreightonTheme.getBorderColor(null, defaultColor: customDefault),
          customDefault,
        );
      },
    );
  });

  group('CreightonTheme.getBabyIconColor', () {
    test('returns babyIconDarkGreen for whiteBaby stamp type', () {
      expect(
        CreightonTheme.getBabyIconColor(StampType.whiteBaby),
        CreightonTheme.babyIconDarkGreen,
      );
    });

    test('returns Colors.white for greenBaby stamp type', () {
      expect(
        CreightonTheme.getBabyIconColor(StampType.greenBaby),
        Colors.white,
      );
    });

    test('returns babyIconGreen for yellowBaby stamp type', () {
      expect(
        CreightonTheme.getBabyIconColor(StampType.yellowBaby),
        CreightonTheme.babyIconGreen,
      );
    });

    test('returns Colors.black87 for non-baby stamp types', () {
      expect(CreightonTheme.getBabyIconColor(StampType.red), Colors.black87);
      expect(CreightonTheme.getBabyIconColor(StampType.green), Colors.black87);
      expect(CreightonTheme.getBabyIconColor(StampType.yellow), Colors.black87);
    });

    test('returns Colors.black87 when stamp type is null', () {
      expect(CreightonTheme.getBabyIconColor(null), Colors.black87);
    });
  });

  group('CreightonTheme.hasBabyIcon', () {
    test('returns true for baby stamp types', () {
      expect(CreightonTheme.hasBabyIcon(StampType.whiteBaby), isTrue);
      expect(CreightonTheme.hasBabyIcon(StampType.greenBaby), isTrue);
      expect(CreightonTheme.hasBabyIcon(StampType.yellowBaby), isTrue);
    });

    test('returns false for non-baby stamp types', () {
      expect(CreightonTheme.hasBabyIcon(StampType.red), isFalse);
      expect(CreightonTheme.hasBabyIcon(StampType.green), isFalse);
      expect(CreightonTheme.hasBabyIcon(StampType.yellow), isFalse);
    });

    test('returns false when stamp type is null', () {
      expect(CreightonTheme.hasBabyIcon(null), isFalse);
    });
  });
}
