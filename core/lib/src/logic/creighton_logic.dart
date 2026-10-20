import '../models/cycle.dart';
import '../models/daily_entry.dart';
import '../models/observation.dart';
import '../utils/date_utils.dart';

class CreightonLogic {
  // Helper values for comparing fertility levels of observations
  static int _stretchValue(Stretch stretch) {
    switch (stretch) {
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

  static int _sensationValue(Sensation sensation) {
    switch (sensation) {
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

  /// Evaluates whether [mucusCode] matches a Basic Infertile Pattern ([bipCodes])
  /// without allowing a Peak-type suffix (like `'6CK'`) to match a non-Peak prefix (`'6C'`).
  static bool matchesBasicInfertilePattern({
    required Observation observation,
    required List<String> bipCodes,
  }) {
    if (!observation.hasMucus || observation.isPeakType) {
      return false;
    }
    final mucusCode = observation.mucusPart();
    for (final rawCode in bipCodes) {
      final normalizedBipCode = rawCode.trim();
      if (normalizedBipCode.isEmpty) continue;
      if (mucusCode == normalizedBipCode ||
          mucusCode == '${normalizedBipCode}G' ||
          mucusCode == '${normalizedBipCode}P' ||
          mucusCode == '${normalizedBipCode}GP') {
        return true;
      }
    }
    return false;
  }

  // Compares two observations. Returns > 0 if first is more fertile than second,
  // < 0 if second is more fertile than first, and 0 if they are equivalent.
  static int compareFertility(Observation first, Observation second) {
    // 1. Peak-type mucus is more fertile than non-peak
    if (first.isPeakType && !second.isPeakType) return 1;
    if (!first.isPeakType && second.isPeakType) return -1;

    // 2. Any mucus observation is more fertile than a non-mucus observation
    if (first.hasMucus && !second.hasMucus) return 1;
    if (!first.hasMucus && second.hasMucus) return -1;

    // 3. Compare stretch level
    final firstStretch = _stretchValue(first.stretch);
    final secondStretch = _stretchValue(second.stretch);
    if (firstStretch != secondStretch) {
      return firstStretch.compareTo(secondStretch);
    }

    // 4. Compare sensation level
    final firstSensation = _sensationValue(first.sensation);
    final secondSensation = _sensationValue(second.sensation);
    if (firstSensation != secondSensation) {
      return firstSensation.compareTo(secondSensation);
    }

    // 5. Lubricative sensation check
    final firstHasLubricative = first.consistencies.contains(
      Consistency.lubricative,
    );
    final secondHasLubricative = second.consistencies.contains(
      Consistency.lubricative,
    );
    if (firstHasLubricative && !secondHasLubricative) return 1;
    if (!firstHasLubricative && secondHasLubricative) return -1;

    // 6. Clear color check
    final firstHasClear = first.colors.contains(MucusColor.clear);
    final secondHasClear = second.colors.contains(MucusColor.clear);
    if (firstHasClear && !secondHasClear) return 1;
    if (!firstHasClear && secondHasClear) return -1;

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
    Observation mostFertileObservation = observations.first;
    for (int index = 1; index < observations.length; index++) {
      if (compareFertility(observations[index], mostFertileObservation) > 0) {
        mostFertileObservation = observations[index];
      }
    }

    // 2. Check if bleeding was observed at any point during the day
    bool hasAnyBleeding = false;
    Bleeding worstBleeding = Bleeding.none;
    String worstBleedingColor = '';

    for (final observation in observations) {
      if (observation.hasBleeding) {
        hasAnyBleeding = true;
        // Compare bleeding intensity (Heavy > Moderate > Light > Very Light / Spotting)
        final currentFlow = observation.bleeding.flowIntensity;
        final worstFlow = worstBleeding.flowIntensity;

        if (worstBleeding == Bleeding.none || currentFlow > worstFlow) {
          worstBleeding = observation.bleeding;
          worstBleedingColor = observation.bleedingColor;
        } else if (currentFlow == worstFlow &&
            worstBleedingColor.isEmpty &&
            observation.bleedingColor.isNotEmpty) {
          worstBleedingColor = observation.bleedingColor;
        }
      }
    }

    // 3. Combine VDRS codes
    String resolvedCode;
    Frequency resolvedFrequency = mostFertileObservation.frequency;
    if (resolvedFrequency == Frequency.none) {
      for (final observation in observations) {
        final matchesMostFertile = mostFertileObservation.hasMucus
            ? (observation.hasMucus &&
                  observation.mucusPart() == mostFertileObservation.mucusPart())
            : (!observation.hasMucus &&
                  observation.sensation == mostFertileObservation.sensation);
        if (matchesMostFertile && observation.frequency != Frequency.none) {
          resolvedFrequency = observation.frequency;
          break;
        }
      }
    }

    final isPureMenstrualFlow =
        worstBleeding.isMenstrualFlow &&
        !mostFertileObservation.hasMucus &&
        mostFertileObservation.sensation == Sensation.dry;

    if (resolvedFrequency == Frequency.none &&
        !isPureMenstrualFlow &&
        observations.isNotEmpty) {
      final matchingCount = observations.where((observation) {
        if (mostFertileObservation.hasMucus) {
          return observation.hasMucus &&
              observation.mucusPart() == mostFertileObservation.mucusPart();
        } else {
          return !observation.hasMucus &&
              observation.sensation == mostFertileObservation.sensation;
        }
      }).length;

      if (matchingCount == 1) {
        resolvedFrequency = Frequency.once;
      } else if (matchingCount == 2) {
        resolvedFrequency = Frequency.twice;
      } else if (matchingCount == 3) {
        resolvedFrequency = Frequency.thrice;
      } else if (matchingCount >= 4) {
        resolvedFrequency = Frequency.allDay;
      }
    }

    final hasAnyIntercourse = observations.any(
      (observation) => observation.intercourse,
    );

    if (hasAnyBleeding) {
      final bleedingBaseCode = worstBleeding.code;
      final colorSuffix =
          (worstBleedingColor.isNotEmpty &&
              worstBleedingColor != Bleeding.red.code)
          ? '-$worstBleedingColor'
          : '';
      final bleedingPart = '$bleedingBaseCode$colorSuffix';

      final isVeryLightOrSpotting =
          worstBleeding == Bleeding.veryLight ||
          worstBleeding == Bleeding.spotting;

      if (isVeryLightOrSpotting ||
          mostFertileObservation.hasMucus ||
          (mostFertileObservation.isVdrsExplicit &&
              mostFertileObservation.sensation != Sensation.dry) ||
          (resolvedFrequency != Frequency.none &&
              mostFertileObservation.isVdrsExplicit)) {
        resolvedCode = '$bleedingPart ${mostFertileObservation.mucusPart()}';
      } else {
        resolvedCode = bleedingPart;
      }
    } else {
      resolvedCode = mostFertileObservation.mucusPart();
    }

    if (resolvedFrequency != Frequency.none) {
      resolvedCode = resolvedCode.isEmpty
          ? resolvedFrequency.code
          : '$resolvedCode ${resolvedFrequency.code}';
    }

    if (hasAnyIntercourse) {
      resolvedCode = resolvedCode.isEmpty ? 'I' : '$resolvedCode I';
    }

    // 4. Combine pain indicators and comments
    double maxPainLevel = 0.0;
    final allPainTypes = <String>{};
    final commentsList = <String>[];

    for (final observation in observations) {
      if (observation.painLevel > maxPainLevel) {
        maxPainLevel = observation.painLevel;
      }
      allPainTypes.addAll(observation.painTypes);
      if (observation.comment.trim().isNotEmpty) {
        commentsList.add(observation.comment.trim());
      }
    }

    // Determine initial basic stamp type prior to full cycle recalculation
    StampType initialStamp;
    if (hasAnyBleeding) {
      initialStamp = StampType.red;
    } else if (mostFertileObservation.hasMucus) {
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
    final sortedEntries = List<DailyEntry>.from(entries);
    sortedEntries.sort((first, second) => first.date.compareTo(second.date));

    // Initialize map of dates to entries
    final entryMap = <String, DailyEntry>{
      for (final entry in sortedEntries) entry.date.dateKey: entry,
    };

    // --- STEP A: IDENTIFY THE PEAK DAY ---
    // The Peak Day is the last day of Peak-type mucus (10, K, or L)
    // followed by an abrupt shift of non-Peak/dry observations.
    // In the Creighton Model, candidate Peak is inferred immediately on the first day
    // of drying up or non-Peak mucus (Peak+1), labeling 'P' on the Peak Day and starting
    // the post-Peak count ('1', '2', '3'). If Peak-type mucus returns, the prior count
    // is disrupted and resets until another shift is observed.
    int peakIndex = -1;

    for (int index = sortedEntries.length - 1; index >= 0; index--) {
      if (sortedEntries[index].isPeakType) {
        // Check if followed by at least 1 day of non-Peak observations
        bool hasNonPeakShift = true;
        int postPeakObservationCount = 0;

        for (
          int nextIndex = index + 1;
          nextIndex < sortedEntries.length;
          nextIndex++
        ) {
          if (sortedEntries[nextIndex].isPeakType) {
            hasNonPeakShift = false;
            break;
          }
          postPeakObservationCount++;
        }

        // Standard Creighton rules infer Peak Day on the abrupt shift
        // to non-Peak/dry observations (>= 1 post-Peak observation).
        if (hasNonPeakShift && postPeakObservationCount >= 1) {
          peakIndex = index;
          break; // Found the last true Peak Day in the cycle
        }
      }
    }

    // --- STEP B: ASSIGN STAMPS AND LABELS ---
    final peakDate = peakIndex != -1 ? sortedEntries[peakIndex].date : null;

    for (int index = 0; index < sortedEntries.length; index++) {
      final entry = sortedEntries[index];

      // Determine Peak Day Label
      String? label;
      if (peakDate != null) {
        final daysSincePeak = calendarDaysBetween(peakDate, entry.date);
        if (daysSincePeak == 0) {
          label = 'P';
        } else if (daysSincePeak == 1) {
          label = '1';
        } else if (daysSincePeak == 2) {
          label = '2';
        } else if (daysSincePeak == 3) {
          label = '3';
        }
      }

      // Assign Stamp Color
      StampType stamp;

      if (entry.hasBleeding) {
        stamp = StampType.red;
      } else if (entry.hasMucus) {
        Observation? mostFertileMucusObservation;
        for (final observation in entry.observations) {
          if (observation.hasMucus) {
            if (mostFertileMucusObservation == null ||
                compareFertility(observation, mostFertileMucusObservation) >
                    0) {
              mostFertileMucusObservation = observation;
            }
          }
        }

        final isBasicInfertilePattern =
            mostFertileMucusObservation != null &&
            matchesBasicInfertilePattern(
              observation: mostFertileMucusObservation,
              bipCodes: bipCodes,
            );

        if (isBasicInfertilePattern) {
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

      // Update the entry in our map (Freezed copyWith properly clears peakDayLabel when label is null)
      final updatedEntry = entry.copyWith(
        stampType: stamp,
        peakDayLabel: label,
      );
      entryMap[entry.date.dateKey] = updatedEntry;
    }

    return entryMap;
  }

  /// Evaluates whether a new cycle should be automatically started based on
  /// Creighton bleeding rules (16+ days since previous cycle start, rolling back
  /// over consecutive prior days with true menstrual flow: Heavy, Moderate, or Light).
  /// Premenstrual spotting / very light bleeding (VL) does NOT roll back or start a new cycle.
  static DateTime? evaluateAutoCycleStart(Cycle latestCycle, DateTime date) {
    final daysDifference = calendarDaysBetween(latestCycle.startDate, date);
    if (daysDifference >= 16) {
      DateTime newCycleStart = date;
      DateTime checkDate = date.subtractCalendarDays(1);
      while (calendarDaysBetween(latestCycle.startDate, checkDate) >= 16) {
        final checkKey = checkDate.dateKey;
        final checkEntry = latestCycle.dailyEntries[checkKey];
        if (checkEntry != null && checkEntry.hasMenstrualFlow) {
          newCycleStart = checkDate;
          checkDate = checkDate.subtractCalendarDays(1);
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
      ..sort((first, second) => first.startDate.compareTo(second.startDate));

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
      for (int index = sortedCycles.length - 1; index >= 0; index--) {
        if (sortedCycles[index].startDate.compareTo(entryDate) <= 0) {
          targetCycle = sortedCycles[index];
          break;
        }
      }

      cycleEntriesMap[targetCycle.id]![dateKey] = entry;
    });

    final result = <Cycle>[];
    for (int index = 0; index < sortedCycles.length; index++) {
      final cycle = sortedCycles[index];
      final updatedEntries = recalculateCycle(
        entries: cycleEntriesMap[cycle.id]!.values.toList(),
        bipCodes: cycle.bipCodes,
      );
      final updatedEndDate = index < sortedCycles.length - 1
          ? sortedCycles[index + 1].startDate.subtractCalendarDays(1)
          : null;
      result.add(
        cycle.copyWith(endDate: updatedEndDate, dailyEntries: updatedEntries),
      );
    }
    return result;
  }

  /// Evaluates whether a daily entry exhibits a fertile mucus pattern (peak-type
  /// mucus or non-BIP mucus on a non-bleeding day).
  static bool isFertileMucusPattern({
    required DailyEntry entry,
    required List<String> bipCodes,
  }) {
    if (entry.hasBleeding) return false;
    if (!entry.hasMucus) return false;
    if (entry.isPeakType) return true;
    for (final observation in entry.observations) {
      if (observation.hasMucus) {
        final isBasicInfertilePattern = matchesBasicInfertilePattern(
          observation: observation,
          bipCodes: bipCodes,
        );
        if (!isBasicInfertilePattern) return true;
      }
    }
    return entry.stampType == StampType.whiteBaby ||
        entry.stampType == StampType.yellowBaby;
  }

  /// Evaluates whether a daily entry marks a cycle phase transition (e.g.
  /// Peak day, post-peak count P+1..P+3, or start of bleeding).
  static bool isPhaseTransition(DailyEntry entry) {
    return entry.isPeakDay || entry.peakDayLabel != null || entry.hasBleeding;
  }
}
