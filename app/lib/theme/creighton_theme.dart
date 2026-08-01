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
  static const Color greenBorder = Color(0xFF43A047); // Colors.green.shade600
  static const Color babyIconGreen = Color(0xFF2E7D32); // Colors.green.shade800
  static const Color peakBadgeRed = Color(0xFFD32F2F); // Colors.red.shade700

  /// Resolves background color for a given Creighton StampType
  static Color getStampColor(StampType stampType) {
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
  static Color getBorderColor(StampType? stampType) {
    if (stampType == null) return Colors.grey.shade300;
    if (stampType == StampType.whiteBaby) return greenBorder;
    return Colors.grey.shade300;
  }
}
