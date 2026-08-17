import '../models/cycle.dart';
import '../models/observation.dart';
import '../models/daily_entry.dart';
import '../utils/date_utils.dart';

class CreightonLogic {
  // Helper values for comparing fertility levels of observations
  static int _stretchValue(Stretch s) {
    switch (s) {
      case Stretch.stretchy:
        return 3;
      case Stretch.tacky:
        return 2;
      case Stretch.sticky:
        return 1;
      case Stretch.none:
        return 0;
    }
  }

  static int _sensationValue(Sensation s) {
    switch (s) {
      case Sensation.shiny:
        return 3;
      case Sensation.wet:
        return 2;
      case Sensation.damp:
        return 1;
      case Sensation.dry:
        return 0;
    }
  }

  // Compares two observations. Returns > 0 if a is more fertile than b,
  // < 0 if b is more fertile than a, and 0 if they are equivalent.
  static int compareFertility(Observation a, Observation b) {
    // 1. Peak-type mucus is more fertile than non-peak
    if (a.isPeakType && !b.isPeakType) return 1;
    if (!a.isPeakType && b.isPeakType) return -1;

    // 2. Compare stretch level
    final stretchA = _stretchValue(a.stretch);
    final stretchB = _stretchValue(b.stretch);
    if (stretchA != stretchB) {
      return stretchA.compareTo(stretchB);
    }

    // 3. Compare sensation level
    final sensationA = _sensationValue(a.sensation);
    final sensationB = _sensationValue(b.sensation);
    if (sensationA != sensationB) {
      return sensationA.compareTo(sensationB);
    }

    // 4. Lubricative sensation check
    final hasLA = a.consistencies.contains(Consistency.lubricative);
    final hasLB = b.consistencies.contains(Consistency.lubricative);
    if (hasLA && !hasLB) return 1;
    if (!hasLA && hasLB) return -1;

    // 5. Clear color check
    final hasKA = a.colors.contains(MucusColor.clear);
    final hasKB = b.colors.contains(MucusColor.clear);
    if (hasKA && !hasKB) return 1;
    if (!hasKA && hasKB) return -1;

    return 0;
  }

  // Resolves a list of observations recorded on a single day to the most
  // fertile one, while combining any bleeding records so they aren't lost.
  static DailyEntry resolveDailyEntry({
    required DateTime date,
    required List<Observation> observations,
  }) {
    if (observations.isEmpty) {
      return DailyEntry(
        date: date,
        resolvedVdrsCode: '0',
        stampType: StampType.green,
        observations: const [],
        painLevel: 0.0,
        painTypes: const [],
        comments: '',
      );
    }

    // 1. Find the most fertile observation for sensation and mucus
    Observation bestObs = observations.first;
    for (int i = 1; i < observations.length; i++) {
      if (compareFertility(observations[i], bestObs) > 0) {
        bestObs = observations[i];
      }
    }

    // 2. Check if bleeding was observed at any point during the day
    bool hasAnyBleeding = false;
    Bleeding worstBleeding = Bleeding.none;
    String worstBleedingColor = '';

    for (var obs in observations) {
      if (obs.hasBleeding) {
        hasAnyBleeding = true;
        // Compare bleeding intensity
        if (worstBleeding == Bleeding.none ||
            obs.bleeding.index > worstBleeding.index) {
          worstBleeding = obs.bleeding;
          worstBleedingColor = obs.bleedingColor;
        }
      }
    }

    // 3. Combine VDRS codes
    String resolvedCode;
    if (hasAnyBleeding) {
      final bCode = worstBleeding.code;
      final colorSuffix =
          (worstBleedingColor.isNotEmpty &&
              worstBleedingColor != Bleeding.red.code)
          ? '-$worstBleedingColor'
          : '';
      final bleedingPart = '$bCode$colorSuffix';

      if (bestObs.hasMucus) {
        resolvedCode = '$bleedingPart ${bestObs.mucusPart()}';
      } else {
        resolvedCode = bleedingPart;
      }
    } else {
      resolvedCode = bestObs.vdrsCode;
    }

    // 4. Combine pain indicators and comments
    double maxPainLevel = 0.0;
    final allPainTypes = <String>{};
    final commentsList = <String>[];

    for (var obs in observations) {
      if (obs.painLevel > maxPainLevel) {
        maxPainLevel = obs.painLevel;
      }
      allPainTypes.addAll(obs.painTypes);
      if (obs.comment.trim().isNotEmpty) {
        commentsList.add(obs.comment.trim());
      }
    }

    // Determine initial basic stamp type prior to full cycle recalculation
    StampType initialStamp;
    if (hasAnyBleeding) {
      initialStamp = StampType.red;
    } else if (bestObs.hasMucus) {
      initialStamp = StampType.whiteBaby;
    } else {
      initialStamp = StampType.green;
    }

    return DailyEntry(
      date: date,
      resolvedVdrsCode: resolvedCode,
      stampType: initialStamp,
      observations: observations,
      painLevel: maxPainLevel,
      painTypes: allPainTypes.toList(),
      comments: commentsList.join('; '),
    );
  }

  // Recalculates stamps and Peak-Day labels for an entire cycle
  static Map<String, DailyEntry> recalculateCycle({
    required List<DailyEntry> entries,
    required List<String> bipCodes,
  }) {
    if (entries.isEmpty) return {};

    // Sort entries chronologically
    final sorted = List<DailyEntry>.from(entries);
    sorted.sort((a, b) => a.date.compareTo(b.date));

    // Initialize map of dates to entries
    final map = <String, DailyEntry>{
      for (var entry in sorted) entry.date.dateKey: entry,
    };

    // --- STEP A: IDENTIFY THE PEAK DAY ---
    // The Peak Day is the last day of Peak-type mucus (10, K, or L)
    // followed by a shift of at least 3 consecutive days of non-Peak/dry
    // patterns.
    int peakIndex = -1;

    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].isPeakType) {
        // Check if followed by at least 3 days of non-Peak observations
        bool has3DaysShift = true;
        int count = 0;

        for (int j = i + 1; j < sorted.length; j++) {
          if (sorted[j].isPeakType) {
            has3DaysShift = false;
            break;
          }
          count++;
          if (count >= 3) break;
        }

        // Standard rules allow identifying Peak Day if we have seen the shift
        if (has3DaysShift && count >= 3) {
          peakIndex = i;
          break; // Found the last true Peak Day in the cycle
        }
      }
    }

    // --- STEP B: ASSIGN STAMPS AND LABELS ---
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];

      // Determine Peak Day Label
      String? label;
      if (peakIndex != -1) {
        if (i == peakIndex) {
          label = 'P';
        } else if (i == peakIndex + 1) {
          label = '1';
        } else if (i == peakIndex + 2) {
          label = '2';
        } else if (i == peakIndex + 3) {
          label = '3';
        }
      }

      // Assign Stamp Color
      StampType stamp;

      if (entry.hasBleeding) {
        stamp = StampType.red;
      } else if (entry.hasMucus) {
        Observation? bestObs;
        for (final obs in entry.observations) {
          if (obs.hasMucus) {
            if (bestObs == null || compareFertility(obs, bestObs) > 0) {
              bestObs = obs;
            }
          }
        }

        final isBip =
            bestObs != null &&
            bipCodes.any((bip) => bestObs!.mucusPart().startsWith(bip));

        if (isBip) {
          // Under Yellow Stamp Protocol:
          // BIP mucus gets a Yellow stamp (infertile)
          // Unless it is the Peak Day or in the Peak+1/2/3 fertile window
          if (label != null) {
            // During the post-Peak window, even if it's BIP mucus, it's
            // considered fertile
            stamp = StampType.whiteBaby;
          } else {
            stamp = StampType.yellow;
          }
        } else {
          // Mucus day representing potential fertility
          stamp = StampType.whiteBaby;
        }
      } else {
        // Dry day (0, 2, 2W, 4)
        // Is it in the post-Peak fertile window?
        if (label != null && label != 'P') {
          stamp =
              StampType.greenBaby; // Dry but fertile (Green with baby symbol)
        } else {
          stamp = StampType.green; // Dry and infertile (Plain Green)
        }
      }

      // Update the entry in our map
      final updatedEntry = entry.copyWith(
        stampType: stamp,
        peakDayLabel: label,
      );
      map[entry.date.dateKey] = updatedEntry;
    }

    return map;
  }

  /// Evaluates whether a new cycle should be automatically started based on
  /// Creighton bleeding rules (16+ days since previous cycle start, rolling back
  /// over consecutive prior days with bleeding).
  static DateTime? evaluateAutoCycleStart(Cycle latestCycle, DateTime date) {
    final daysDiff = date.difference(latestCycle.startDate).inDays;
    if (daysDiff >= 16) {
      DateTime newCycleStart = date;
      DateTime checkDate = date.subtract(const Duration(days: 1));
      while (checkDate.difference(latestCycle.startDate).inDays >= 16) {
        final checkKey = checkDate.dateKey;
        final checkEntry = latestCycle.dailyEntries[checkKey];
        if (checkEntry != null && checkEntry.hasBleeding) {
          newCycleStart = checkDate;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return newCycleStart;
    }
    return null;
  }

  /// Reallocates all daily entries across cycles chronologically based on their
  /// start dates, and recalculates Creighton stamps / peak labels for each cycle.
  static List<Cycle> reallocateAndRecalculateCycles(List<Cycle> cycles) {
    if (cycles.isEmpty) return [];

    final sortedCycles = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final allEntries = <String, DailyEntry>{};
    for (final cycle in sortedCycles) {
      allEntries.addAll(cycle.dailyEntries);
    }

    final cycleEntriesMap = <String, Map<String, DailyEntry>>{
      for (final cycle in sortedCycles) cycle.id: <String, DailyEntry>{},
    };

    allEntries.forEach((dateKey, entry) {
      final entryDate = entry.date;
      Cycle targetCycle = sortedCycles.first;
      for (int i = sortedCycles.length - 1; i >= 0; i--) {
        if (sortedCycles[i].startDate.compareTo(entryDate) <= 0) {
          targetCycle = sortedCycles[i];
          break;
        }
      }

      cycleEntriesMap[targetCycle.id]![dateKey] = entry;
    });

    final result = <Cycle>[];
    for (final cycle in sortedCycles) {
      final updatedEntries = recalculateCycle(
        entries: cycleEntriesMap[cycle.id]!.values.toList(),
        bipCodes: cycle.bipCodes,
      );
      result.add(cycle.copyWith(dailyEntries: updatedEntries));
    }
    return result;
  }
}
