import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../logic/models/observation.dart';

class ObservationSummaryStepCard extends StatelessWidget {
  final DateTime combinedDateTime;
  final bool showBleeding;
  final bool hasBleeding;
  final Bleeding? bleedingFlow;
  final String? bleedingColor;
  final bool showMucus;
  final Sensation? sensation;
  final bool hasLubrication;
  final bool hasMucus;
  final Stretch? stretch;
  final List<MucusColor> selectedColors;
  final bool showPain;
  final bool hasPain;
  final List<String> formattedPainTypes;
  final double painLevel;
  final bool showIntercourse;
  final bool? hasIntercourse;
  final TextEditingController commentController;

  const ObservationSummaryStepCard({
    super.key,
    required this.combinedDateTime,
    this.showBleeding = true,
    this.hasBleeding = false,
    this.bleedingFlow,
    this.bleedingColor,
    this.showMucus = true,
    this.sensation,
    this.hasLubrication = false,
    this.hasMucus = false,
    this.stretch,
    this.selectedColors = const [],
    this.showPain = true,
    this.hasPain = false,
    this.formattedPainTypes = const [],
    this.painLevel = 0.0,
    this.showIntercourse = true,
    this.hasIntercourse,
    required this.commentController,
  });

  String _formatMucusColor() {
    if (selectedColors.isEmpty) return MucusColor.cloudy.label;
    if (selectedColors.length == 2 &&
        selectedColors.contains(MucusColor.cloudy) &&
        selectedColors.contains(MucusColor.clear)) {
      return 'Cloudy/Clear';
    }
    if (selectedColors.contains(MucusColor.clear)) return MucusColor.clear.label;
    if (selectedColors.contains(MucusColor.cloudy)) return MucusColor.cloudy.label;
    if (selectedColors.contains(MucusColor.yellow)) return MucusColor.yellow.label;
    if (selectedColors.contains(MucusColor.red)) return MucusColor.red.label;
    if (selectedColors.contains(MucusColor.brown)) return MucusColor.brown.label;
    return selectedColors.map((c) => c.label).join('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final flowLabel = bleedingFlow != null ? bleedingFlow!.label : 'Light';

    String bleedingColorName = '';
    if (bleedingColor == 'R') bleedingColorName = 'Red';
    if (bleedingColor == 'B') bleedingColorName = 'Brown';
    if (bleedingColor == 'K') bleedingColorName = 'Black';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary & Additional Notes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Summary Badge Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Observation Summary:',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Date: ${DateFormat('MMM dd, yyyy • h:mm a').format(combinedDateTime)}',
                style: const TextStyle(fontSize: 12),
              ),
              if (showBleeding)
                Text(
                  'Bleeding: ${hasBleeding ? "$flowLabel${bleedingColorName.isNotEmpty ? ', $bleedingColorName' : ''}" : "None"}',
                  style: const TextStyle(fontSize: 12),
                ),
              if (showMucus) ...[
                Text(
                  'Sensation: ${sensation?.label ?? "Dry"}${hasLubrication ? " (Lubricative)" : ""}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Mucus: ${hasMucus ? "${stretch?.label ?? 'Sticky'}, ${_formatMucusColor()}" : "None"}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (showPain)
                Text(
                  'Pain: ${hasPain ? "${formattedPainTypes.isNotEmpty ? formattedPainTypes.join(', ') : 'Logged'} (${painLevel.toInt()}/10)" : "None"}',
                  style: const TextStyle(fontSize: 12),
                ),
              if (showIntercourse && hasIntercourse != null)
                Text(
                  'Intercourse: ${hasIntercourse == true ? "Yes" : "No"}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Comments / Notes (Optional):',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: commentController,
            maxLines: null,
            minLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Add extra details or observations...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
