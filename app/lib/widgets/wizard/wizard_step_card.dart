import 'package:flutter/material.dart';

class WizardStepCard extends StatelessWidget {
  final String title;
  final String? stepIndicator;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool isNextEnabled;
  final String nextButtonText;

  const WizardStepCard({
    super.key,
    required this.title,
    this.stepIndicator,
    required this.child,
    this.onBack,
    this.onNext,
    this.isNextEnabled = true,
    this.nextButtonText = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stepIndicator != null) ...[
            Text(
              stepIndicator!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onBack != null)
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                )
              else
                const SizedBox.shrink(),
              if (onNext != null)
                FilledButton.icon(
                  onPressed: isNextEnabled ? onNext : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(nextButtonText),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
