import 'package:flutter/material.dart';

import '../../logic/logic.dart';
import 'widgets/daily_intake_forecast_cards.dart';
import 'widgets/daily_intake_header_cards.dart';
import 'widgets/daily_intake_time_section.dart';

class DailyIntakeTab extends StatefulWidget {
  final DateTime selectedDate;
  final Cycle? cycle;
  final List<Cycle> cycles;
  final int cycleDay;
  final int? daysPastPeak;
  final bool hasPeakOccurred;
  final List<SupplementItem> supplements;
  final DailySupplementLog dailyLog;
  final ValueChanged<int>? onDateChanged;
  final VoidCallback? onGoToToday;
  final void Function(
    SupplementItem item,
    SupplementTimeOfDay time,
    bool taken,
  )?
  onToggleDose;
  final UserRole? initialRole;
  final ValueChanged<UserRole>? onRoleChanged;

  const DailyIntakeTab({
    super.key,
    required this.selectedDate,
    this.cycle,
    this.cycles = const [],
    required this.cycleDay,
    this.daysPastPeak,
    required this.hasPeakOccurred,
    required this.supplements,
    required this.dailyLog,
    this.onDateChanged,
    this.onGoToToday,
    this.onToggleDose,
    this.initialRole,
    this.onRoleChanged,
  });

  @override
  State<DailyIntakeTab> createState() => _DailyIntakeTabState();
}

class _DailyIntakeTabState extends State<DailyIntakeTab> {
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.wife;
  }

  @override
  void didUpdateWidget(DailyIntakeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRole != null &&
        widget.initialRole != oldWidget.initialRole) {
      _selectedRole = widget.initialRole!;
    }
  }

  Future<void> _handleToggleDose(
    SupplementItem item,
    SupplementTimeOfDay time,
    bool taken,
  ) async {
    if (widget.onToggleDose != null) {
      widget.onToggleDose!(item, time, taken);
      return;
    }
    try {
      await Services.db.logSupplementDose(
        date: widget.selectedDate,
        supplementId: item.id,
        timeOfDay: time,
        taken: taken,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update supplement dose: $e')),
        );
      }
    }
  }

  List<SupplementDayForecast> _buildSevenDayForecast() {
    Cycle? effectiveFallbackCycle = widget.cycle;
    if (effectiveFallbackCycle == null &&
        widget.cycles.isEmpty &&
        (widget.cycleDay > 1 || widget.daysPastPeak != null)) {
      final syntheticStart = widget.selectedDate.subtractCalendarDays(
        widget.cycleDay - 1,
      );
      final Map<String, DailyEntry> entries = {};
      if (widget.daysPastPeak != null) {
        final peakDate = widget.selectedDate.subtractCalendarDays(
          widget.daysPastPeak!,
        );
        entries[peakDate.dateKey] = DailyEntry.raw(
          date: peakDate,
          peakDayLabel: 'P',
        );
      }
      effectiveFallbackCycle = Cycle(
        id: syntheticStart.dateKey,
        startDate: syntheticStart,
        dailyEntries: entries,
      );
    }

    return SupplementForecastEngine.buildForecast(
      startDate: widget.selectedDate,
      supplements: widget.supplements,
      role: _selectedRole,
      cycles: widget.cycles,
      fallbackCycle: effectiveFallbackCycle,
      days: 7,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleSupplements = widget.supplements
        .where((s) => s.targetRole == _selectedRole)
        .toList();
    final hasRoleSupplements = roleSupplements.any((s) => s.isActive);

    final activeSupplements = roleSupplements
        .where(
          (s) => s.isScheduledFor(
            cycleDay: widget.cycleDay,
            daysPastPeak: widget.daysPastPeak,
            hasPeakOccurred: widget.hasPeakOccurred,
          ),
        )
        .toList();

    final sevenDayForecast = _buildSevenDayForecast();
    final todayForecast = sevenDayForecast.first;
    final upcomingDays = sevenDayForecast.skip(1).toList();

    int totalDoses = 0;
    int takenDoses = 0;

    for (final time in SupplementTimeOfDay.values) {
      for (final supp in activeSupplements) {
        if (supp.doseForTime(time) > 0) {
          totalDoses++;
          if (widget.dailyLog.isTaken(supp.id, time)) {
            takenDoses++;
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        DailyIntakeDateNavigatorCard(
          selectedDate: widget.selectedDate,
          cycleDay: widget.cycleDay,
          daysPastPeak: widget.daysPastPeak,
          onDateChanged: widget.onDateChanged,
          onGoToToday: widget.onGoToToday,
        ),
        const SizedBox(height: 12),

        SegmentedButton<UserRole>(
          key: const Key('daily_intake_role_segmented_button'),
          segments: const [
            ButtonSegment<UserRole>(
              value: UserRole.wife,
              label: Text('👩 Wife'),
              icon: Icon(Icons.female),
            ),
            ButtonSegment<UserRole>(
              value: UserRole.husband,
              label: Text('👨 Husband'),
              icon: Icon(Icons.male),
            ),
          ],
          selected: {_selectedRole},
          onSelectionChanged: (Set<UserRole> newSelection) {
            setState(() {
              _selectedRole = newSelection.first;
            });
            widget.onRoleChanged?.call(_selectedRole);
          },
        ),
        const SizedBox(height: 12),

        if (!hasRoleSupplements)
          DailyIntakeEmptyPlanCard(selectedRole: _selectedRole)
        else ...[
          DailyIntakeAdherenceCard(
            takenDoses: takenDoses,
            totalDoses: totalDoses,
          ),
          const SizedBox(height: 16),

          ...SupplementTimeOfDay.values.map((time) {
            final itemsForTime = activeSupplements
                .where((s) => s.doseForTime(time) > 0)
                .toList();

            return DailyIntakeTimeOfDaySection(
              time: time,
              items: itemsForTime,
              dailyLog: widget.dailyLog,
              onToggleDose: _handleToggleDose,
            );
          }),

          if (todayForecast.conditionalOnPeakSupplements.isNotEmpty) ...[
            const SizedBox(height: 4),
            ConditionalOnPeakSection(
              dayOffset: 0,
              items: todayForecast.conditionalOnPeakSupplements,
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 28),

          Text(
            'Next 6 Days',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.hasPeakOccurred
                ? 'Peak Day is recorded — peak-based supplements are locked in for the upcoming week.'
                : 'Read-only 6-day preview. Peak-dependent supplements are listed under "Conditional on Peak" until Peak Day is recorded.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          ...upcomingDays.map(
            (dayForecast) => UpcomingDayForecastCard(day: dayForecast),
          ),
        ],
      ],
    );
  }
}
