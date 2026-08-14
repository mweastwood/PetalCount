import 'package:flutter/material.dart';

class OptionCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.label,
    this.icon,
    this.subtitle,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.85)
                        : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OptionGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final List<int>? fullWidthIndexes;

  const OptionGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.6,
    this.fullWidthIndexes,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsiveColumns = constraints.maxWidth < 380
            ? 1
            : crossAxisCount;
        final responsiveAspectRatio = constraints.maxWidth < 380
            ? 2.8
            : childAspectRatio;

        if (fullWidthIndexes != null &&
            fullWidthIndexes!.isNotEmpty &&
            responsiveColumns > 1) {
          final gridItems = <Widget>[];
          for (int i = 0; i < children.length; i++) {
            if (fullWidthIndexes!.contains(i)) {
              gridItems.add(
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: children[i],
                ),
              );
            } else {
              int pairEnd = i;
              final pair = <Widget>[];
              while (pairEnd < children.length &&
                  !fullWidthIndexes!.contains(pairEnd) &&
                  pair.length < responsiveColumns) {
                pair.add(Expanded(child: children[pairEnd]));
                pairEnd++;
              }
              i = pairEnd - 1;
              gridItems.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int p = 0; p < pair.length; p++) ...[
                      if (p > 0) const SizedBox(width: 10),
                      pair[p],
                    ],
                    if (pair.length < responsiveColumns)
                      for (
                        int pad = 0;
                        pad < responsiveColumns - pair.length;
                        pad++
                      ) ...[const SizedBox(width: 10), const Spacer()],
                  ],
                ),
              );
            }
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int k = 0; k < gridItems.length; k++) ...[
                if (k > 0) const SizedBox(height: 10),
                gridItems[k],
              ],
            ],
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: responsiveColumns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: responsiveAspectRatio,
          children: children,
        );
      },
    );
  }
}
