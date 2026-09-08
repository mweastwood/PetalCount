import 'package:flutter/material.dart';

import '../../logic/logic.dart';

enum ObservationCategory {
  full('Log Single Observation'),
  mucus('Log Mucus Observation'),
  bleeding('Log Bleeding'),
  intercourse('Log Intercourse'),
  pain('Log Pain');

  final String dialogTitle;
  const ObservationCategory(this.dialogTitle);
}

enum WizardStep {
  bleedingFlow('Bleeding'),
  bleedingColor('Blood Color'),
  sensation('Sensation'),
  lubrication('Lubrication'),
  mucus('Mucus'),
  mucusStretch('Stretch'),
  mucusColor('Mucus Color'),
  mucusConsistency('Consistency'),
  frequency('Frequency'),
  intercourse('Intercourse'),
  pain('Pain'),
  painDetails('Pain Details'),
  comments('Comments & Save');

  final String title;
  const WizardStep(this.title);

  /// Card-driven selection steps that automatically advance upon option selection.
  bool get isSelfAdvancing =>
      this != WizardStep.painDetails && this != WizardStep.comments;
}

class WizardController extends ChangeNotifier {
  final ObservationCategory category;
  final Cycle? cycle;
  final DateTime defaultDate;
  final DatabaseService _dbService;

  int _currentStepIndex = 0;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  // Bleeding (nullable so no option is pre-selected)
  bool? _hasBleeding;
  Bleeding? _bleedingFlow;
  String? _bleedingColor;

  // Sensation (nullable so no option is pre-selected)
  Sensation? _sensation;
  bool? _hasLubrication;

  // Mucus Observation (nullable so no option is pre-selected)
  bool? _hasMucus;
  Stretch? _stretch;
  List<MucusColor> _selectedColors = [];
  bool _isGummy = false;
  bool _isPasty = false;
  bool _hasSelectedConsistency = false;

  // Pain (nullable so no option is pre-selected)
  bool? _hasPain;
  final List<String> _painTypes = [];
  bool _abdominalLeft = false;
  bool _abdominalRight = false;
  double _painLevel = 3.0;

  // Frequency
  Frequency _frequency = Frequency.none;

  // Intercourse (nullable so no option is pre-selected)
  bool? _hasIntercourse;

  // Comments
  final TextEditingController _commentController = TextEditingController();
  bool _isSaving = false;
  bool _isDisposed = false;

  WizardController({
    this.category = ObservationCategory.full,
    this.cycle,
    required this.defaultDate,
    DatabaseService? dbService,
  }) : _dbService = dbService ?? Services.db {
    _selectedDate = DateTime(
      defaultDate.year,
      defaultDate.month,
      defaultDate.day,
    );
    _selectedTime = TimeOfDay(
      hour: defaultDate.hour,
      minute: defaultDate.minute,
    );

    if (category == ObservationCategory.intercourse) {
      _hasIntercourse = true;
    } else if (category == ObservationCategory.bleeding) {
      _hasBleeding = true;
    } else if (category == ObservationCategory.pain) {
      _hasPain = true;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _commentController.dispose();
    super.dispose();
  }

  // --- Date & Time ---

  DateTime get selectedDate => _selectedDate;
  set selectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    selectedDate = date;
  }

  TimeOfDay get selectedTime => _selectedTime;
  set selectedTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay time) {
    selectedTime = time;
  }

  DateTime get combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  // --- Bleeding State & Mutators ---

  bool? get hasBleeding => _hasBleeding;
  Bleeding? get bleedingFlow => _bleedingFlow;
  String? get bleedingColor => _bleedingColor;

  bool get isHeavyOrModerateBleeding =>
      _hasBleeding == true &&
      (_bleedingFlow == Bleeding.heavy || _bleedingFlow == Bleeding.moderate);

  void setNoBleeding() {
    _hasBleeding = false;
    _bleedingFlow = Bleeding.none;
    _bleedingColor = null;
    notifyListeners();
  }

  void setBleedingFlow(Bleeding flow) {
    _hasBleeding = true;
    _bleedingFlow = flow;
    notifyListeners();
  }

  void setBleedingColor(String color) {
    _bleedingColor = color;
    notifyListeners();
  }

  void setHasBleeding(bool hasBleeding) {
    _hasBleeding = hasBleeding;
    if (!hasBleeding) {
      _bleedingFlow = Bleeding.none;
      _bleedingColor = null;
    }
    notifyListeners();
  }

  // --- Sensation & Lubrication State & Mutators ---

  Sensation? get sensation => _sensation;
  bool? get hasLubrication => _hasLubrication;

  void setSensation(Sensation sens) {
    _sensation = sens;
    if (sens == Sensation.dry) {
      _hasLubrication = false;
    }
    notifyListeners();
  }

  void setLubrication(bool lub) {
    _hasLubrication = lub;
    notifyListeners();
  }

  // --- Mucus State & Mutators ---

  bool? get hasMucus => _hasMucus;
  Stretch? get stretch => _stretch;
  List<MucusColor> get selectedColors => List.unmodifiable(_selectedColors);
  bool get isGummy => _isGummy;
  bool get isPasty => _isPasty;
  bool get hasSelectedConsistency => _hasSelectedConsistency;

  void setHasMucus(bool has) {
    _hasMucus = has;
    if (!has) {
      _stretch = Stretch.none;
      _selectedColors = [];
      _isGummy = false;
      _isPasty = false;
      _hasSelectedConsistency = false;
    }
    notifyListeners();
  }

  void setStretch(Stretch s) {
    _stretch = s;
    notifyListeners();
  }

  void setSelectedColors(List<MucusColor> colors) {
    _selectedColors = List.from(colors);
    notifyListeners();
  }

  void setConsistency({required bool isGummy, required bool isPasty}) {
    _isGummy = isGummy;
    _isPasty = isPasty;
    _hasSelectedConsistency = true;
    notifyListeners();
  }

  // --- Frequency State & Mutators ---

  Frequency get frequency => _frequency;

  void setFrequency(Frequency freq) {
    _frequency = freq;
    notifyListeners();
  }

  // --- Intercourse State & Mutators ---

  bool? get hasIntercourse => _hasIntercourse;

  void setHasIntercourse(bool intercourse) {
    _hasIntercourse = intercourse;
    notifyListeners();
  }

  // --- Pain State & Mutators ---

  bool? get hasPain => _hasPain;
  List<String> get painTypes => List.unmodifiable(_painTypes);
  bool get abdominalLeft => _abdominalLeft;
  bool get abdominalRight => _abdominalRight;
  double get painLevel => _painLevel;

  List<String> get formattedPainTypes {
    final list = <String>[];
    for (final p in _painTypes) {
      if (p == 'Abdominal Pain') {
        if (_abdominalLeft && _abdominalRight) {
          list.add('Abdominal Pain (Left & Right)');
        } else if (_abdominalLeft) {
          list.add('Abdominal Pain (Left)');
        } else if (_abdominalRight) {
          list.add('Abdominal Pain (Right)');
        } else {
          list.add('Abdominal Pain');
        }
      } else {
        list.add(p);
      }
    }
    return list;
  }

  void setHasPain(bool has) {
    _hasPain = has;
    notifyListeners();
  }

  void togglePainType(String type, bool selected) {
    if (selected) {
      if (!_painTypes.contains(type)) {
        _painTypes.add(type);
      }
    } else {
      _painTypes.remove(type);
    }
    notifyListeners();
  }

  void setAbdominalLeft(bool val) {
    _abdominalLeft = val;
    notifyListeners();
  }

  void setAbdominalRight(bool val) {
    _abdominalRight = val;
    notifyListeners();
  }

  void setPainLevel(double level) {
    _painLevel = level;
    notifyListeners();
  }

  // --- Comments & Status ---

  TextEditingController get commentController => _commentController;
  bool get isSaving => _isSaving;
  bool get isDisposed => _isDisposed;

  // --- Summary Visibility Helpers ---

  bool get showBleeding =>
      category == ObservationCategory.full ||
      category == ObservationCategory.bleeding;

  bool get showMucus =>
      (category == ObservationCategory.full ||
          category == ObservationCategory.mucus) &&
      !isHeavyOrModerateBleeding;

  bool get showPain =>
      category == ObservationCategory.full ||
      category == ObservationCategory.pain;

  bool get showIntercourse =>
      category == ObservationCategory.full ||
      category == ObservationCategory.intercourse;

  // --- Dynamic Step Routing ---

  List<WizardStep> get activeSteps {
    if (category == ObservationCategory.bleeding) {
      final steps = [WizardStep.bleedingFlow];
      if (_hasBleeding == true) {
        steps.add(WizardStep.bleedingColor);
      }
      steps.add(WizardStep.comments);
      return steps;
    }

    if (category == ObservationCategory.mucus) {
      final steps = <WizardStep>[WizardStep.sensation];
      if (_sensation != null && _sensation != Sensation.dry) {
        steps.add(WizardStep.lubrication);
      }
      steps.add(WizardStep.mucus);
      if (_hasMucus == true) {
        steps.add(WizardStep.mucusStretch);
        steps.add(WizardStep.mucusColor);
        if (_stretch == Stretch.sticky) {
          steps.add(WizardStep.mucusConsistency);
        }
        steps.add(WizardStep.frequency);
      }
      steps.add(WizardStep.comments);
      return steps;
    }

    if (category == ObservationCategory.intercourse) {
      return [WizardStep.comments];
    }

    if (category == ObservationCategory.pain) {
      return [WizardStep.painDetails, WizardStep.comments];
    }

    final steps = [WizardStep.bleedingFlow];
    if (_hasBleeding == true) {
      steps.add(WizardStep.bleedingColor);
    }
    if (!isHeavyOrModerateBleeding) {
      steps.add(WizardStep.sensation);
      if (_sensation != null && _sensation != Sensation.dry) {
        steps.add(WizardStep.lubrication);
      }
      steps.add(WizardStep.mucus);
      if (_hasMucus == true) {
        steps.add(WizardStep.mucusStretch);
        steps.add(WizardStep.mucusColor);
        if (_stretch == Stretch.sticky) {
          steps.add(WizardStep.mucusConsistency);
        }
        steps.add(WizardStep.frequency);
      }
    }
    steps.add(WizardStep.pain);
    if (_hasPain == true) {
      steps.add(WizardStep.painDetails);
    }
    steps.add(WizardStep.comments);
    return steps;
  }

  int get currentStepIndex {
    final steps = activeSteps;
    if (_currentStepIndex >= steps.length) {
      return steps.isEmpty ? 0 : steps.length - 1;
    }
    return _currentStepIndex;
  }

  WizardStep get currentStep {
    final steps = activeSteps;
    if (_currentStepIndex >= steps.length) {
      return steps.last;
    }
    return steps[_currentStepIndex];
  }

  bool get isFirstStep => currentStepIndex == 0;

  bool get isLastStep {
    final steps = activeSteps;
    return currentStepIndex >= steps.length - 1;
  }

  double get progress {
    final steps = activeSteps;
    if (steps.isEmpty) return 0.0;
    return (currentStepIndex + 1) / steps.length;
  }

  void nextStep() {
    final steps = activeSteps;
    final current = currentStepIndex;
    if (current < steps.length - 1) {
      _currentStepIndex = current + 1;
      notifyListeners();
    }
  }

  void previousStep() {
    final current = currentStepIndex;
    if (current > 0) {
      _currentStepIndex = current - 1;
      notifyListeners();
    }
  }

  void goToStep(int index) {
    final steps = activeSteps;
    if (index >= 0 && index < steps.length) {
      _currentStepIndex = index;
      notifyListeners();
    }
  }

  // --- Save & Persistence ---

  Future<bool> saveObservation() async {
    if (_isSaving) return false;
    _isSaving = true;
    notifyListeners();

    final bool hasBleeding = _hasBleeding ?? false;
    final Bleeding bleeding = hasBleeding
        ? (_bleedingFlow ?? Bleeding.light)
        : Bleeding.none;
    final String bleedingColorStr = hasBleeding ? (_bleedingColor ?? 'R') : '';

    Sensation sensation = Sensation.dry;
    Stretch stretch = Stretch.none;
    final List<MucusColor> colors = [];
    final List<Consistency> consistencies = [];

    if (!isHeavyOrModerateBleeding) {
      sensation = _sensation ?? Sensation.dry;

      if ((_hasLubrication ?? false) && sensation != Sensation.dry) {
        consistencies.add(Consistency.lubricative);
      }

      if (_hasMucus ?? false) {
        stretch = _stretch ?? Stretch.sticky;
        colors.addAll(
          _selectedColors.isNotEmpty ? _selectedColors : [MucusColor.cloudy],
        );

        if (_isGummy) consistencies.add(Consistency.gummy);
        if (_isPasty) consistencies.add(Consistency.pasty);
      }
    }

    final bool hasPain = _hasPain ?? false;
    final double painLevel = hasPain ? _painLevel : 0.0;
    final List<String> painTypes = hasPain ? formattedPainTypes : [];

    String commentText = _commentController.text.trim();
    if (_hasIntercourse == true) {
      if (commentText.isEmpty) {
        commentText = 'Intercourse';
      } else if (!commentText.contains('Intercourse')) {
        commentText = 'Intercourse • $commentText';
      }
    }

    final bool isVdrsExplicit =
        _hasBleeding == true ||
        _sensation != null ||
        _hasMucus == true ||
        _frequency != Frequency.none ||
        _hasIntercourse == true ||
        category == ObservationCategory.mucus ||
        category == ObservationCategory.bleeding ||
        category == ObservationCategory.intercourse;

    try {
      await _dbService.saveObservation(
        cycleId: cycle?.id,
        date: combinedDateTime,
        sensation: sensation,
        stretch: stretch,
        colors: colors,
        consistencies: consistencies,
        bleeding: bleeding,
        bleedingColor: bleedingColorStr,
        frequency: _frequency,
        intercourse: _hasIntercourse ?? false,
        painLevel: painLevel,
        painTypes: painTypes,
        comment: commentText,
        isVdrsExplicit: isVdrsExplicit,
      );
      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isSaving = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
}
