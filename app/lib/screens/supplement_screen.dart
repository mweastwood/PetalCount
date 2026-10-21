import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/logic.dart';
import 'supplements/supplements.dart';

class SupplementScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Cycle? activeCycle;
  final UserRole? initialRole;
  final Stream<String?>? userRoleStream;

  const SupplementScreen({
    super.key,
    this.initialDate,
    this.activeCycle,
    this.initialRole,
    this.userRoleStream,
  });

  @override
  State<SupplementScreen> createState() => _SupplementScreenState();
}

class _SupplementScreenState extends State<SupplementScreen> {
  late DateTime _selectedDate;
  late UserRole _activeRole;
  bool _hasManuallyChangedRole = false;
  StreamSubscription<String?>? _userRoleSubscription;
  late final Stream<List<Cycle>> _cyclesStream;
  late final Stream<List<SupplementItem>> _supplementsStream;
  late final Stream<Map<String, DailySupplementLog>> _supplementLogsStream;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _activeRole = widget.initialRole ?? UserRole.wife;
    _cyclesStream = Services.db.streamCycles();
    _supplementsStream = Services.db.streamSupplements();
    _supplementLogsStream = Services.db.streamDailySupplementLogs();
    if (widget.initialRole == null) {
      final roleStream =
          widget.userRoleStream ??
          (Services.db is InMemoryDatabaseService
              ? Services.db.streamUserRole().skip(1)
              : Services.db.streamUserRole());
      _userRoleSubscription = roleStream.listen((roleString) {
        if (!mounted || _hasManuallyChangedRole || roleString == null) {
          return;
        }
        final resolvedRole = UserRole.fromString(roleString);
        if (_activeRole != resolvedRole) {
          setState(() {
            _activeRole = resolvedRole;
          });
        }
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _userRoleSubscription?.cancel();
    super.dispose();
  }

  void _changeDate(int offset) {
    setState(() {
      _selectedDate = _selectedDate.addCalendarDays(offset);
    });
  }

  void _goToToday() {
    final now = widget.initialDate ?? DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  Cycle? _findCycleForDate(List<Cycle> cycles, DateTime date) {
    return SupplementForecastEngine.findCycleForDate(
      cycles,
      date,
      fallbackCycle: widget.activeCycle,
    );
  }

  int _calculateCycleDay(Cycle? cycle, DateTime date) {
    if (cycle == null) return 1;
    return calendarDaysBetween(cycle.startDate, date) + 1;
  }

  int? _calculateDaysPastPeak(Cycle? cycle, DateTime date) {
    return SupplementForecastEngine.calculateDaysPastPeak(cycle, date);
  }

  void _showResetPresetsConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Supplement Presets?'),
        content: const Text(
          'This will reset your supplement list to the standard Creighton / NaPro prescription and supplement instructions for wife and husband.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await Services.db.resetDefaultSupplements();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supplements reset to standard presets.'),
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSupplementDialog(BuildContext context, SupplementItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: Text(
          'Are you sure you want to remove this supplement from your ${item.targetRole.displayName.toLowerCase()} formulary?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await Services.db.deleteSupplement(item.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditSupplementPlanSheet(
    BuildContext context,
    List<SupplementItem> initialSupplements,
  ) {
    final sheetStream = Services.db.streamSupplements();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Edit Supplement Plan'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => Navigator.pop(sheetContext),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  tooltip: 'Reset Default Presets',
                  onPressed: () => _showResetPresetsConfirmation(context),
                ),
              ],
            ),
            body: StreamBuilder<List<SupplementItem>>(
              stream: sheetStream,
              initialData: initialSupplements,
              builder: (context, snapshot) {
                final supplements = snapshot.data ?? initialSupplements;
                return FormularyTab(
                  supplements: supplements,
                  initialRoleFilter: null,
                  onEdit: (item) =>
                      AddEditSupplementDialog.show(sheetContext, item),
                  onDelete: (item) =>
                      _showDeleteSupplementDialog(sheetContext, item),
                );
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              key: const Key('btn_add_supplement_fab'),
              onPressed: () => AddEditSupplementDialog.show(
                sheetContext,
                null,
                null,
                _activeRole,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Supplement'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Cycle>>(
      stream: _cyclesStream,
      builder: (context, cycleSnapshot) {
        final cycles = cycleSnapshot.data ?? [];
        final activeCycle = _findCycleForDate(cycles, _selectedDate);
        final cycleDay = _calculateCycleDay(activeCycle, _selectedDate);
        final daysPastPeak = _calculateDaysPastPeak(activeCycle, _selectedDate);
        final hasPeakOccurred = daysPastPeak != null && daysPastPeak >= 0;

        return StreamBuilder<List<SupplementItem>>(
          stream: _supplementsStream,
          builder: (context, supplementsSnapshot) {
            final supplements = supplementsSnapshot.data ?? [];

            return Scaffold(
              appBar: AppBar(
                title: const Text('Supplements & Protocols'),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit_plan') {
                        _showEditSupplementPlanSheet(context, supplements);
                      } else if (value == 'reset') {
                        _showResetPresetsConfirmation(context);
                      } else if (value == 'add') {
                        AddEditSupplementDialog.show(
                          context,
                          null,
                          null,
                          _activeRole,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit_plan',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit Supplement Plan'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text('Add Supplement'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.restore, size: 20),
                            SizedBox(width: 8),
                            Text('Reset Default Presets'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: StreamBuilder<Map<String, DailySupplementLog>>(
                stream: _supplementLogsStream,
                builder: (context, logSnapshot) {
                  final logs = logSnapshot.data ?? {};
                  final dateKey = _selectedDate.dateKey;
                  final dailyLog =
                      logs[dateKey] ??
                      DailySupplementLog(date: _selectedDate, takenDoses: {});
                  return DailyIntakeTab(
                    selectedDate: _selectedDate,
                    cycle: activeCycle,
                    cycles: cycles,
                    cycleDay: cycleDay,
                    daysPastPeak: daysPastPeak,
                    hasPeakOccurred: hasPeakOccurred,
                    supplements: supplements,
                    dailyLog: dailyLog,
                    initialRole: _activeRole,
                    onRoleChanged: (role) {
                      setState(() {
                        _hasManuallyChangedRole = true;
                        _activeRole = role;
                      });
                    },
                    onDateChanged: _changeDate,
                    onGoToToday: _goToToday,
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                key: const Key('btn_edit_supplement_plan_fab'),
                tooltip: 'Edit Supplement Plan',
                onPressed: () =>
                    _showEditSupplementPlanSheet(context, supplements),
                child: const Icon(Icons.edit),
              ),
            );
          },
        );
      },
    );
  }
}
