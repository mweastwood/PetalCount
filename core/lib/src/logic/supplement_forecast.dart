import '../models/cycle.dart';
import '../models/supplement.dart';
import '../models/user_role.dart';
import '../utils/date_utils.dart';

/// Represents the projected supplement plan for a single calendar date.
class SupplementDayForecast {
  final DateTime date;
  final int dayOffset;
  final int cycleDay;
  final int? daysPastPeak;
  final bool hasPeakOccurred;

  /// Supplements that are deterministically scheduled for [date].
  ///
  /// On Today ([dayOffset] == 0), this includes all active supplements for the
  /// role so the user can check off doses taken today.
  /// On upcoming days ([dayOffset] > 0) when [hasPeakOccurred] is false,
  /// peak-dependent supplements are separated into [conditionalOnPeakSupplements].
  final List<SupplementItem> scheduledSupplements;

  /// Peak-dependent supplements whose inclusion or stop/start window on [date]
  /// depends on when Peak Day is observed (empty when [hasPeakOccurred] is true).
  final List<SupplementItem> conditionalOnPeakSupplements;

  const SupplementDayForecast({
    required this.date,
    required this.dayOffset,
    required this.cycleDay,
    required this.daysPastPeak,
    required this.hasPeakOccurred,
    required this.scheduledSupplements,
    required this.conditionalOnPeakSupplements,
  });

  List<SupplementItem> scheduledForTime(SupplementTimeOfDay time) {
    return scheduledSupplements
        .where((item) => item.doseForTime(time) > 0)
        .toList();
  }
}

/// Pure-Dart projection engine for computing multi-day supplement schedules
/// across active cycles and Peak Day transitions.
class SupplementForecastEngine {
  const SupplementForecastEngine._();

  static bool isPeakDependentRule(SupplementScheduleRuleType ruleType) {
    return ruleType == SupplementScheduleRuleType.peakOffset ||
        ruleType == SupplementScheduleRuleType.cycleDaysOrPeak;
  }

  static Cycle? findCycleForDate(
    List<Cycle> cycles,
    DateTime date, {
    Cycle? fallbackCycle,
  }) {
    final normalizedDate = date.toNormalizedDate();
    final candidates = <Cycle>[
      ...cycles,
      if (fallbackCycle != null && !cycles.any((c) => c.id == fallbackCycle.id))
        fallbackCycle,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));
    for (int i = candidates.length - 1; i >= 0; i--) {
      if (!candidates[i].startDate.toNormalizedDate().isAfter(normalizedDate)) {
        return candidates[i];
      }
    }
    return null;
  }

  static int? calculateDaysPastPeak(Cycle? cycle, DateTime date) {
    if (cycle == null) return null;
    DateTime? peakDate;
    for (final entry in cycle.sortedEntries) {
      if (entry.isPeakDay) {
        peakDate = entry.date;
        break;
      }
    }
    if (peakDate == null) return null;
    return calendarDaysBetween(peakDate, date);
  }

  /// Projects the supplement schedule for [days] consecutive days starting at
  /// [startDate] (defaulting to 7 days: Today + next 6 days).
  static List<SupplementDayForecast> buildForecast({
    required DateTime startDate,
    required List<SupplementItem> supplements,
    required UserRole role,
    List<Cycle> cycles = const [],
    Cycle? fallbackCycle,
    int days = 7,
  }) {
    final normalizedStart = startDate.toNormalizedDate();
    final roleSupplements = supplements
        .where((s) => s.isActive && s.targetRole == role)
        .toList();

    return List<SupplementDayForecast>.generate(days, (dayOffset) {
      final date = normalizedStart.addCalendarDays(dayOffset);
      final cycle = findCycleForDate(
        cycles,
        date,
        fallbackCycle: fallbackCycle,
      );
      final cycleDay = cycle != null
          ? calendarDaysBetween(cycle.startDate, date) + 1
          : 1;
      final daysPastPeak = calculateDaysPastPeak(cycle, date);
      final hasPeakOccurred = daysPastPeak != null && daysPastPeak >= 0;

      if (hasPeakOccurred) {
        final scheduled = roleSupplements
            .where(
              (item) => item.isScheduledFor(
                cycleDay: cycleDay,
                daysPastPeak: daysPastPeak,
                hasPeakOccurred: true,
              ),
            )
            .toList();
        return SupplementDayForecast(
          date: date,
          dayOffset: dayOffset,
          cycleDay: cycleDay,
          daysPastPeak: daysPastPeak,
          hasPeakOccurred: true,
          scheduledSupplements: scheduled,
          conditionalOnPeakSupplements: const [],
        );
      }

      // Peak has not yet occurred as of `date`.
      final scheduled = <SupplementItem>[];
      final conditional = <SupplementItem>[];

      for (final item in roleSupplements) {
        final activeByFallback = item.isScheduledFor(
          cycleDay: cycleDay,
          daysPastPeak: daysPastPeak,
          hasPeakOccurred: false,
        );

        if (!isPeakDependentRule(item.ruleType)) {
          if (activeByFallback) {
            scheduled.add(item);
          }
          continue;
        }

        // Peak-dependent item (`peakOffset` or `cycleDaysOrPeak`)
        if (dayOffset == 0 && activeByFallback) {
          // On Today, keep active fallback items in scheduledSupplements so the
          // user can check off their doses today, while also noting their Peak
          // condition.
          scheduled.add(item);
        }

        bool couldStartIfPeakSoon = false;
        if (item.ruleType == SupplementScheduleRuleType.peakOffset &&
            item.startPeakOffset != null) {
          final startOffset = item.startPeakOffset!;
          final endOffset = item.durationDays != null
              ? (startOffset + item.durationDays! - 1)
              : (item.endPeakOffset ?? startOffset);
          couldStartIfPeakSoon =
              daysPastPeak == null &&
              dayOffset > 0 &&
              startOffset <= dayOffset &&
              endOffset >= 0 &&
              startOffset <= endOffset;
        }

        if (activeByFallback || couldStartIfPeakSoon) {
          conditional.add(item);
        }
      }

      return SupplementDayForecast(
        date: date,
        dayOffset: dayOffset,
        cycleDay: cycleDay,
        daysPastPeak: daysPastPeak,
        hasPeakOccurred: false,
        scheduledSupplements: scheduled,
        conditionalOnPeakSupplements: conditional,
      );
    });
  }
}
