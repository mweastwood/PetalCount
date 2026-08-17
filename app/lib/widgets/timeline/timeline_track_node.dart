import 'package:flutter/material.dart';

import '../../logic/logic.dart';
import '../creighton_stamp_widget.dart';

/// Left 56px timeline column with continuous vertical track connector and stamp node.
class TimelineTrackNode extends StatelessWidget {
  final StampType? stampType;
  final String? peakDayLabel;
  final int dayNumber;
  final VoidCallback? onTap;

  const TimelineTrackNode({
    super.key,
    this.stampType,
    this.peakDayLabel,
    required this.dayNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 56,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Vertical Connector Line
          Positioned(
            left: 26,
            width: 4,
            top: 0,
            bottom: 0,
            child: Container(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          // Stamp Box Node
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onTap,
              child: CreightonStampWidget.timelineNode(
                stampType: stampType,
                peakDayLabel: peakDayLabel,
                dayNumber: dayNumber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
