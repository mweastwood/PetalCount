import 'package:flutter/material.dart';

import '../logic/models/daily_entry.dart';

/// Centralized design tokens, color palettes, and layout dimensions for Creighton charting components.
class CreightonTheme {
  CreightonTheme._();

  // Grid Cell Layout Dimensions
  static const double cellWidth = 66.0;
  static const double cellHeight = 114.0;
  static const double headerRowHeight = 36.0;
  static const double cycleHeaderWidth = 110.0;
  static const double cellGap = 3.0;

  // Corner Radii
  static const double cardBorderRadius = 8.0;
  static const double stickerBorderRadius = 6.5;

  // Stamp Colors
  static const Color redStamp = Color(0xFFEF5350); // Colors.red.shade400
  static const Color greenStamp = Color(0xFF66BB6A); // Colors.green.shade400
  static const Color whiteStamp = Colors.white;
  static const Color yellowStamp = Color(0xFFFFCA28); // Colors.yellow.shade400
  static const Color emptyCellBackground = Color(0xFFFAFAFA);

  // Border & Accent Colors
  static const Color redBorder = Color(0xFFE53935); // Colors.red.shade600
  static const Color greenBorder = Color(0xFF43A047); // Colors.green.shade600
  static const Color yellowBorder = Color(0xFFFDD835); // Colors.yellow.shade600
  static const Color babyIconGreen = Color(0xFF2E7D32); // Colors.green.shade800
  static const Color babyIconDarkGreen = Color(
    0xFF388E3C,
  ); // Colors.green.shade700
  static const Color peakBadgeRed = Color(0xFFD32F2F); // Colors.red.shade700

  /// Resolves background color for a given Creighton StampType
  static Color getStampColor(
    StampType? stampType, {
    Color defaultColor = emptyCellBackground,
  }) {
    if (stampType == null) return defaultColor;
    switch (stampType) {
      case StampType.red:
        return redStamp;
      case StampType.green:
        return greenStamp;
      case StampType.whiteBaby:
        return whiteStamp;
      case StampType.greenBaby:
        return greenStamp;
      case StampType.yellow:
      case StampType.yellowBaby:
        return yellowStamp;
    }
  }

  /// Resolves border color for a given Creighton StampType
  static Color getBorderColor(
    StampType? stampType, {
    Color defaultColor = const Color(0xFFE0E0E0),
  }) {
    if (stampType == null) return defaultColor;
    switch (stampType) {
      case StampType.red:
        return redBorder;
      case StampType.green:
      case StampType.whiteBaby:
      case StampType.greenBaby:
        return greenBorder;
      case StampType.yellow:
      case StampType.yellowBaby:
        return yellowBorder;
    }
  }

  /// Resolves baby icon color for a given Creighton StampType
  static Color getBabyIconColor(StampType? stampType) {
    if (stampType == null) return Colors.black87;
    switch (stampType) {
      case StampType.whiteBaby:
        return babyIconDarkGreen;
      case StampType.greenBaby:
        return Colors.white;
      case StampType.yellowBaby:
        return babyIconGreen;
      case StampType.red:
      case StampType.green:
      case StampType.yellow:
        return Colors.black87;
    }
  }

  /// Whether the given stamp type renders a baby symbol
  static bool hasBabyIcon(StampType? stampType) {
    return stampType == StampType.whiteBaby ||
        stampType == StampType.greenBaby ||
        stampType == StampType.yellowBaby;
  }
}
