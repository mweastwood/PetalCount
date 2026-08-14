import 'package:flutter/material.dart';

import '../logic/models/daily_entry.dart';
import '../theme/creighton_theme.dart';

enum _StampWidgetMode { badge, gridSticker, timelineNode }

/// A unified widget for rendering Creighton Model FertilityCare stamps across
/// badges, grid spreadsheet sticker headers, and timeline nodes.
class CreightonStampWidget extends StatelessWidget {
  final StampType? stampType;
  final String? peakDayLabel;
  final int? dayNumber;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final _StampWidgetMode _mode;

  /// Default constructor for general-purpose Creighton stamp rendering.
  const CreightonStampWidget({
    super.key,
    required this.stampType,
    this.peakDayLabel,
    this.dayNumber,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.boxShadow,
  }) : _mode = _StampWidgetMode.badge;

  /// Standalone badge mode used in sheets, dialogs, and detail views.
  const CreightonStampWidget.badge({
    super.key,
    required this.stampType,
    this.peakDayLabel,
    this.width = 44.0,
    this.height = 48.0,
    this.borderRadius,
    this.border,
  }) : dayNumber = null,
       boxShadow = null,
       _mode = _StampWidgetMode.badge;

  /// Grid sticker cell mode used at the top of spreadsheet cells in ChartScreen.
  const CreightonStampWidget.gridSticker({
    super.key,
    this.stampType,
    this.peakDayLabel,
    this.height = 46.0,
    this.width = double.infinity,
    this.borderRadius,
  }) : dayNumber = null,
       border = null,
       boxShadow = null,
       _mode = _StampWidgetMode.gridSticker;

  /// Timeline node mode used in chronological feed in ObservationsScreen.
  const CreightonStampWidget.timelineNode({
    super.key,
    this.stampType,
    this.peakDayLabel,
    this.dayNumber,
    double size = 52.0,
    this.borderRadius,
    this.border,
    this.boxShadow,
  }) : width = size,
       height = size,
       _mode = _StampWidgetMode.timelineNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (_mode) {
      case _StampWidgetMode.badge:
        return _buildBadge(context, theme);
      case _StampWidgetMode.gridSticker:
        return _buildGridSticker(context, theme);
      case _StampWidgetMode.timelineNode:
        return _buildTimelineNode(context, theme);
    }
  }

  Widget _buildBadge(BuildContext context, ThemeData theme) {
    final bg = CreightonTheme.getStampColor(
      stampType,
      defaultColor: Colors.grey.shade400,
    );
    final borderColor =
        border ??
        Border.all(
          color: CreightonTheme.getBorderColor(
            stampType,
            defaultColor: Colors.grey.shade600,
          ),
          width: 2,
        );
    final hasBaby = CreightonTheme.hasBabyIcon(stampType);
    final babyColor = CreightonTheme.getBabyIconColor(stampType);

    return Container(
      width: width ?? 44.0,
      height: height ?? 48.0,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius ?? BorderRadius.circular(6),
        border: borderColor,
        boxShadow: boxShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (peakDayLabel != null && peakDayLabel!.isNotEmpty)
            Positioned(
              top: 2,
              child: Text(
                peakDayLabel!,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          if (hasBaby)
            Positioned(
              bottom: 4,
              child: Icon(Icons.child_care, size: 20, color: babyColor),
            ),
        ],
      ),
    );
  }

  Widget _buildGridSticker(BuildContext context, ThemeData theme) {
    final stampColor = CreightonTheme.getStampColor(
      stampType,
      defaultColor: theme.colorScheme.surfaceContainerLowest,
    );
    final hasBaby = CreightonTheme.hasBabyIcon(stampType);
    final babyColor = CreightonTheme.getBabyIconColor(stampType);

    return Container(
      width: width ?? double.infinity,
      height: height ?? 46.0,
      decoration: BoxDecoration(
        color: stampColor,
        borderRadius:
            borderRadius ??
            const BorderRadius.vertical(
              top: Radius.circular(CreightonTheme.stickerBorderRadius),
            ),
      ),
      child: Stack(
        children: [
          // Peak Day Badge at top-left
          if (peakDayLabel != null && peakDayLabel!.isNotEmpty)
            Positioned(
              top: 2,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: peakDayLabel == 'P'
                      ? CreightonTheme.peakBadgeRed
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  peakDayLabel!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // Baby Icon in center for fertile stamps, or '?' for unlogged days
          if (hasBaby)
            Center(child: Icon(Icons.child_care, size: 26, color: babyColor))
          else if (stampType == null)
            Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.outline.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(BuildContext context, ThemeData theme) {
    final stampColor = CreightonTheme.getStampColor(
      stampType,
      defaultColor: theme.colorScheme.surfaceContainerLowest,
    );
    final borderColor = stampType != null
        ? (stampType == StampType.whiteBaby
              ? CreightonTheme.greenBorder
              : Colors.grey.shade400)
        : theme.colorScheme.outlineVariant;
    final hasBaby = CreightonTheme.hasBabyIcon(stampType);
    final babyColor = CreightonTheme.getBabyIconColor(stampType);

    return Container(
      width: width ?? 52.0,
      height: height ?? 52.0,
      decoration: BoxDecoration(
        color: stampColor,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        border: border ?? Border.all(color: borderColor, width: 1.5),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (peakDayLabel != null && peakDayLabel!.isNotEmpty)
            Positioned(
              top: 2,
              right: 4,
              child: Text(
                peakDayLabel!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: peakDayLabel == 'P' ? Colors.red : Colors.black87,
                ),
              ),
            ),
          if (hasBaby)
            Icon(Icons.child_care, size: 24, color: babyColor)
          else if (dayNumber != null)
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: stampType != null && stampType != StampType.whiteBaby
                    ? Colors.white
                    : Colors.grey.shade800,
              ),
            ),
        ],
      ),
    );
  }
}
