import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/cycle.dart';
import 'models/daily_entry.dart';
import 'models/observation.dart';
import 'services/services.dart';
import 'services/pdf_export_service.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Services.init();
  mainCommon();
}

void mainCommon() {
  runApp(const PetalCountApp());
}

enum AppEnvironment { dev, prod }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.dev;
}

class PetalCountApp extends StatelessWidget {
  const PetalCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: Colors.pink,
            primary: const Color(0xFFD81B60),
            secondary: const Color(0xFF8E24AA),
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.pink,
            primary: const Color(0xFFF48FB1),
            secondary: const Color(0xFFCE93D8),
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'PetalCount',
          theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Services.db.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        final chartId = Services.db.currentChartId;
        if (chartId == null) {
          return const ChartSelectionScreen();
        }

        return const DashboardScreen();
      },
    );
  }
}

// ==========================================
// 1. LOGIN & SIGNUP SCREENS
// ==========================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Services.db.signInWithGoogle();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_vintage,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'PetalCount',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'Collaborative Creighton Charting',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              if (_errorMessage.isNotEmpty) ...[
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _loginWithGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. CHART SELECTION & ONBOARDING SCREEN
// ==========================================

// ==========================================
// 3. DASHBOARD SCREEN & CHART GRID
// ==========================================

enum ViewMode { timeline, creightonGrid }

class _TimelineItem {
  final DateTime date;
  final DailyEntry? entry;
  final Cycle? cycle;
  final int dayNumber;
  final bool isCycleStart;

  _TimelineItem({
    required this.date,
    required this.entry,
    required this.cycle,
    required this.dayNumber,
    required this.isCycleStart,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<List<Cycle>> _cyclesStream;
  ViewMode _viewMode = ViewMode.timeline;

  @override
  void initState() {
    super.initState();
    _cyclesStream = Services.db.streamCycles();
  }

  void _showAddObservationDialog(BuildContext context, Cycle? cycle) {
    showDialog(
      context: context,
      builder: (context) =>
          AddObservationDialog(cycle: cycle, defaultDate: DateTime.now()),
    );
  }

  void _showAddObservationDialogForDate(
    BuildContext context,
    Cycle? cycle,
    DateTime date,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          AddObservationDialog(cycle: cycle, defaultDate: date),
    );
  }

  void _showDailyDetailSheet(
    BuildContext context,
    DailyEntry entry,
    Cycle cycle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DailyDetailSheet(entry: entry, cycle: cycle),
    );
  }

  Widget _buildNoCyclesView(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Observations Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your self-reported observations to automatically track and detect your cycles.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddObservationDialog(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Log First Observation'),
            ),
          ],
        ),
      ),
    );
  }

  // --- VIEW MODE 1: VERTICAL TIMELINE VIEW ---
  // Days are laid out vertically. Today (current day) is at the bottom,
  // and swiping UP scrolls back in time to previous days.
  Widget _buildVerticalTimelineView(BuildContext context, List<Cycle> cycles) {
    final theme = Theme.of(context);

    // Extract all logged daily entries across all cycles
    final timelineItems = <_TimelineItem>[];

    for (var cycle in cycles) {
      final sortedEntries = cycle.sortedEntries;

      if (sortedEntries.isNotEmpty) {
        for (int i = 0; i < sortedEntries.length; i++) {
          final entry = sortedEntries[i];
          timelineItems.add(
            _TimelineItem(
              date: entry.date,
              entry: entry,
              cycle: cycle,
              dayNumber: i + 1,
              isCycleStart: i == 0,
            ),
          );
        }
      } else {
        timelineItems.add(
          _TimelineItem(
            date: cycle.startDate,
            entry: null,
            cycle: cycle,
            dayNumber: 1,
            isCycleStart: true,
          ),
        );
      }
    }

    // Determine current/anchor date (latest entry date or today)
    final DateTime today;
    if (timelineItems.isNotEmpty) {
      DateTime maxDate = timelineItems.first.date;
      for (final item in timelineItems) {
        if (item.date.isAfter(maxDate)) {
          maxDate = item.date;
        }
      }
      today = DateTime(maxDate.year, maxDate.month, maxDate.day);
    } else {
      final now = DateTime.now();
      today = DateTime(now.year, now.month, now.day);
    }

    final hasToday = timelineItems.any(
      (item) =>
          item.date.year == today.year &&
          item.date.month == today.month &&
          item.date.day == today.day,
    );

    if (!hasToday) {
      final activeCycle = cycles.isNotEmpty ? cycles.first : null;
      int dayNum = 1;
      if (activeCycle != null) {
        dayNum = today.difference(activeCycle.startDate).inDays + 1;
      }
      timelineItems.add(
        _TimelineItem(
          date: today,
          entry: null,
          cycle: activeCycle,
          dayNumber: dayNum > 0 ? dayNum : 1,
          isCycleStart: false,
        ),
      );
    }

    // Sort ascending chronologically (oldest date first, today/latest date last)
    timelineItems.sort((a, b) => a.date.compareTo(b.date));

    // Reverse list so index 0 = Today (latest), which reverse: true places at the BOTTOM of the screen!
    final reversedItems = timelineItems.reversed.toList();

    return ListView.builder(
      reverse: true, // Today at bottom, scroll UP to see previous days
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
      itemCount: reversedItems.length,
      itemBuilder: (context, index) {
        final item = reversedItems[index];
        final entry = item.entry;
        final isToday =
            item.date.year == today.year &&
            item.date.month == today.month &&
            item.date.day == today.day;

        Color stampColor = theme.colorScheme.surfaceContainerLowest;
        Color borderColor = theme.colorScheme.outlineVariant;
        IconData? stampIcon;
        Color stampIconColor = Colors.black87;

        if (entry != null) {
          borderColor = Colors.grey.shade400;
          switch (entry.stampType) {
            case StampType.red:
              stampColor = Colors.red.shade400;
              break;
            case StampType.green:
              stampColor = Colors.green.shade400;
              break;
            case StampType.whiteBaby:
              stampColor = Colors.white;
              borderColor = Colors.green.shade600;
              stampIcon = Icons.child_care;
              stampIconColor = Colors.green.shade700;
              break;
            case StampType.greenBaby:
              stampColor = Colors.green.shade400;
              stampIcon = Icons.child_care;
              stampIconColor = Colors.white;
              break;
            case StampType.yellow:
              stampColor = Colors.yellow.shade400;
              break;
            case StampType.yellowBaby:
              stampColor = Colors.yellow.shade400;
              stampIcon = Icons.child_care;
              stampIconColor = Colors.green.shade800;
              break;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: isToday
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isToday ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (entry != null && item.cycle != null) {
                _showDailyDetailSheet(context, entry, item.cycle!);
              } else {
                _showAddObservationDialogForDate(
                  context,
                  item.cycle,
                  item.date,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Stamp Badge
                  Container(
                    width: 54,
                    height: 58,
                    decoration: BoxDecoration(
                      color: stampColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (entry?.peakDayLabel != null)
                          Text(
                            entry!.peakDayLabel!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: entry.peakDayLabel == 'P'
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        if (stampIcon != null)
                          Icon(stampIcon, size: 20, color: stampIconColor)
                        else
                          Text(
                            entry?.resolvedVdrsCode ?? '-',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  entry != null &&
                                      entry.stampType != StampType.whiteBaby
                                  ? Colors.white
                                  : Colors.grey.shade800,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isToday
                                  ? 'Today – ${DateFormat('EEE, MMM dd').format(item.date)}'
                                  : DateFormat(
                                      'EEEE, MMM dd, yyyy',
                                    ).format(item.date),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (item.isCycleStart) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Cycle starting ${DateFormat('MMMM dd, yyyy').format(item.date)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry != null
                              ? 'Day ${item.dayNumber} • ${entry.resolvedVdrsCode.isNotEmpty ? entry.resolvedVdrsCode : 'Logged'}${entry.comments.isNotEmpty ? ' • "${entry.comments}"' : ''}'
                              : 'Day ${item.dayNumber} • Tap to log observation',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: entry != null
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.outline,
                            fontStyle: entry == null ? FontStyle.italic : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- VIEW MODE 2: CLASSIC CREIGHTON MODEL GRID VIEW ---
  // Adaptive layout:
  // - Narrow screen (portrait): most recent cycle going DOWN starting from the LEFT,
  //   previous cycle just to the right, next cycle to the right of that, etc.
  // - Wider screen (landscape): most recent cycle going LEFT-TO-RIGHT at the TOP,
  //   previous cycle just below it, next cycle below that, etc.
  Widget _buildCreightonGridView(BuildContext context, List<Cycle> cycles) {
    final media = MediaQuery.of(context);
    final isNarrow =
        media.size.width < media.size.height || media.size.width < 600;

    if (isNarrow) {
      // Narrow screen: side-by-side vertical columns (most recent cycle on left, going down)
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cycles.map((cycle) {
              return _buildVerticalCycleColumn(context, cycle);
            }).toList(),
          ),
        ),
      );
    } else {
      // Wider screen: stacked horizontal rows (most recent cycle at top, going left-to-right)
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
        itemCount: cycles.length,
        itemBuilder: (context, index) {
          final cycle = cycles[index];
          return _buildHorizontalCycleRow(context, cycle);
        },
      );
    }
  }

  Widget _buildVerticalCycleColumn(BuildContext context, Cycle cycle) {
    final entries = cycle.sortedEntries;
    final totalCells = entries.length < 35 ? 35 : entries.length;

    return Container(
      width: 68,
      margin: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM dd').format(cycle.startDate),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${cycle.startDate.year}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(totalCells, (index) {
            DailyEntry? entry;
            if (index < entries.length) {
              entry = entries[index];
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildGridStampCell(context, entry, index + 1, cycle),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHorizontalCycleRow(BuildContext context, Cycle cycle) {
    final entries = cycle.sortedEntries;
    final totalCells = entries.length < 35 ? 35 : entries.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cycle starting ${DateFormat('MMMM dd, yyyy').format(cycle.startDate)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  tooltip: 'Export Cycle PDF',
                  onPressed: () => PdfExportService.exportCyclesToPdf([cycle]),
                ),
              ],
            ),
            Text(
              '${cycle.dailyEntries.length} entries logged  |  BIP: ${cycle.bipCodes.isEmpty ? 'None' : cycle.bipCodes.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(totalCells, (index) {
                  DailyEntry? entry;
                  if (index < entries.length) {
                    entry = entries[index];
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _buildGridStampCell(
                      context,
                      entry,
                      index + 1,
                      cycle,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStampCell(
    BuildContext context,
    DailyEntry? entry,
    int dayNum,
    Cycle cycle,
  ) {
    final theme = Theme.of(context);

    Color stampColor = theme.colorScheme.surfaceContainerLowest;
    Color borderCol = theme.colorScheme.outlineVariant;
    bool hasBaby = false;
    bool hasGreenBaby = false;
    Color babyIconColor = Colors.black87;

    if (entry != null) {
      borderCol = Colors.grey.shade400;
      switch (entry.stampType) {
        case StampType.red:
          stampColor = Colors.red.shade400;
          break;
        case StampType.green:
          stampColor = Colors.green.shade400;
          break;
        case StampType.whiteBaby:
          stampColor = Colors.white;
          borderCol = Colors.green.shade600;
          hasBaby = true;
          babyIconColor = Colors.green.shade700;
          break;
        case StampType.greenBaby:
          stampColor = Colors.green.shade400;
          hasGreenBaby = true;
          break;
        case StampType.yellow:
          stampColor = Colors.yellow.shade400;
          break;
        case StampType.yellowBaby:
          stampColor = Colors.yellow.shade400;
          hasBaby = true;
          babyIconColor = Colors.green.shade800;
          break;
      }
    }

    final hasPain = entry != null && entry.painLevel > 0;
    final hasComments = entry != null && entry.comments.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (entry != null) {
          _showDailyDetailSheet(context, entry, cycle);
        } else {
          final mockDate = cycle.startDate.add(Duration(days: dayNum - 1));
          _showAddObservationDialogForDate(context, cycle, mockDate);
        }
      },
      child: Container(
        width: 58,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 18,
              alignment: Alignment.center,
              child: Text(
                entry?.peakDayLabel ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: entry?.peakDayLabel == 'P'
                      ? Colors.red
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 56,
              decoration: BoxDecoration(
                color: stampColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: borderCol,
                  width: entry != null ? 1.5 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 8,
                          color:
                              entry != null &&
                                  entry.stampType != StampType.whiteBaby
                              ? Colors.white70
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (hasBaby)
                    Icon(Icons.child_care, size: 24, color: babyIconColor)
                  else if (hasGreenBaby)
                    const Icon(Icons.child_care, size: 24, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                entry != null ? DateFormat('MMM dd').format(entry.date) : '-',
                style: const TextStyle(fontSize: 8, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              height: 24,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                entry?.resolvedVdrsCode ?? '',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              height: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasPain)
                    const Icon(
                      Icons.local_fire_department,
                      size: 10,
                      color: Colors.redAccent,
                    ),
                  if (hasComments) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.notes, size: 10, color: Colors.blueAccent),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Cycle>>(
      stream: _cyclesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final cycles = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Petal Count'),
            leading: IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch Chart',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChartSelectionScreen(),
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export Chart to PDF',
                onPressed: cycles.isNotEmpty
                    ? () => PdfExportService.exportCyclesToPdf(cycles)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        activeCycle: cycles.isNotEmpty ? cycles.first : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: cycles.isEmpty
              ? _buildNoCyclesView(context)
              : (_viewMode == ViewMode.timeline
                    ? _buildVerticalTimelineView(context, cycles)
                    : _buildCreightonGridView(context, cycles)),
          bottomNavigationBar: cycles.isEmpty
              ? null
              : NavigationBar(
                  selectedIndex: _viewMode.index,
                  onDestinationSelected: (index) {
                    setState(() {
                      _viewMode = ViewMode.values[index];
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.view_timeline_outlined),
                      selectedIcon: Icon(Icons.view_timeline),
                      label: 'Timeline',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.grid_on_outlined),
                      selectedIcon: Icon(Icons.grid_on),
                      label: 'Creighton Grid',
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddObservationDialog(
              context,
              cycles.isNotEmpty ? cycles.first : null,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Log Observation'),
          ),
        );
      },
    );
  }
}

class ChartSelectionScreen extends StatefulWidget {
  const ChartSelectionScreen({super.key});

  @override
  State<ChartSelectionScreen> createState() => _ChartSelectionScreenState();
}

class _ChartSelectionScreenState extends State<ChartSelectionScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingInvites = [];

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    final invites = await Services.db.getPendingInvitations();
    if (mounted) {
      setState(() {
        _pendingInvites = invites;
      });
    }
  }

  Future<void> _createChart() async {
    setState(() => _isLoading = true);
    try {
      await Services.db.createChart();
    } catch (e) {
      debugPrint('Error creating chart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Error creating chart: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 20),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptInvite(String chartId) async {
    setState(() => _isLoading = true);
    try {
      await Services.db.acceptInvitation(chartId);
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Error accepting invitation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 20),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserEmail = Services.db.currentUser?.email ?? '';
    final currentChartId = Services.db.currentChartId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Chart'),
        leading: currentChartId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          if (currentChartId == null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Services.db.signOut(),
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Services.db.streamAvailableCharts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final charts = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (charts.isNotEmpty) ...[
                  Text(
                    'Your Charts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select an active chart to view and log observations:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: charts.length,
                    itemBuilder: (context, index) {
                      final chart = charts[index];
                      final chartId = chart['id'] as String;
                      final isActive = currentChartId == chartId;

                      final emails = List<String>.from(chart['emails'] ?? []);
                      final partners = emails
                          .where((e) => e != currentUserEmail)
                          .toList();
                      final titleText = partners.isEmpty
                          ? 'My Solo Chart'
                          : 'Shared with: ${partners.join(", ")}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: isActive
                            ? RoundedRectangleBorder(
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: ListTile(
                          title: Text(
                            titleText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Chart ID: $chartId'),
                          trailing: isActive
                              ? Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Services.db.setActiveChart(chartId);
                            if (context.mounted &&
                                Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                ] else ...[
                  Text(
                    'Welcome to PetalCount!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get started by creating a new shared cycle chart, or join one that your partner has already created.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  FilledButton.icon(
                    onPressed: _createChart,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Shared Chart'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    'Pending Invitations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_pendingInvites.isEmpty)
                    Text(
                      'No pending invites. Ask your partner to add you using your email: ${Services.db.currentUser?.email}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingInvites.length,
                      itemBuilder: (context, index) {
                        final invite = _pendingInvites[index];
                        return Card(
                          child: ListTile(
                            title: Text('Invite from ${invite['senderEmail']}'),
                            subtitle: const Text(
                              'To link to their cycle chart',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _acceptInvite(invite['chartId']),
                              child: const Text('Accept & Link'),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loadInvitations,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Invites'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class CycleChartScreen extends StatefulWidget {
  final String cycleId;
  const CycleChartScreen({super.key, required this.cycleId});

  @override
  State<CycleChartScreen> createState() => _CycleChartScreenState();
}

class _CycleChartScreenState extends State<CycleChartScreen> {
  late final Stream<List<Cycle>> _cyclesStream;

  @override
  void initState() {
    super.initState();
    _cyclesStream = Services.db.streamCycles();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Cycle>>(
      stream: _cyclesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final cycles = snapshot.data ?? [];
        final cycleIndex = cycles.indexWhere((c) => c.id == widget.cycleId);

        if (cycleIndex == -1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final cycle = cycles[cycleIndex];
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Cycle: ${DateFormat('MMM dd, yyyy').format(cycle.startDate)}',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export Chart to PDF',
                onPressed: () => PdfExportService.exportCyclesToPdf([cycle]),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(activeCycle: cycle),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Cycle',
                onPressed: () => _confirmDeleteCycle(context, cycle),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Center(
                  child: Text(
                    'Cycle Day: ${cycle.dailyEntries.length} logged  |  BIP: ${cycle.bipCodes.isEmpty ? 'None' : cycle.bipCodes.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreightonGrid(context, cycle),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddObservationDialog(context, cycle),
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Log Observation'),
          ),
        );
      },
    );
  }

  Widget _buildCreightonGrid(BuildContext context, Cycle cycle) {
    final entries = cycle.sortedEntries;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cycle Chart View',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: List.generate(entries.length < 35 ? 35 : entries.length, (
            index,
          ) {
            DailyEntry? entry;
            if (index < entries.length) {
              entry = entries[index];
            }

            final dayNum = index + 1;
            return _buildGridStampCell(context, entry, dayNum, cycle);
          }),
        ),
      ],
    );
  }

  Widget _buildGridStampCell(
    BuildContext context,
    DailyEntry? entry,
    int dayNum,
    Cycle cycle,
  ) {
    final theme = Theme.of(context);

    Color stampColor = theme.colorScheme.surfaceContainerLowest;
    Color borderCol = theme.colorScheme.outlineVariant;
    bool hasBaby = false;
    bool hasGreenBaby = false;
    Color babyIconColor = Colors.black87;

    if (entry != null) {
      borderCol = Colors.grey.shade400;
      switch (entry.stampType) {
        case StampType.red:
          stampColor = Colors.red.shade400;
          break;
        case StampType.green:
          stampColor = Colors.green.shade400;
          break;
        case StampType.whiteBaby:
          stampColor = Colors.white;
          borderCol = Colors.green.shade600;
          hasBaby = true;
          babyIconColor = Colors.green.shade700;
          break;
        case StampType.greenBaby:
          stampColor = Colors.green.shade400;
          hasGreenBaby = true;
          break;
        case StampType.yellow:
          stampColor = Colors.yellow.shade400;
          break;
        case StampType.yellowBaby:
          stampColor = Colors.yellow.shade400;
          hasBaby = true;
          babyIconColor = Colors.green.shade800;
          break;
      }
    }

    final hasPain = entry != null && entry.painLevel > 0;
    final hasComments = entry != null && entry.comments.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (entry != null) {
          _showDailyDetailSheet(context, entry, cycle);
        } else {
          final mockDate = cycle.startDate.add(Duration(days: dayNum - 1));
          _showAddObservationDialogForDate(context, cycle, mockDate);
        }
      },
      child: Container(
        width: 58,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 18,
              alignment: Alignment.center,
              child: Text(
                entry?.peakDayLabel ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: entry?.peakDayLabel == 'P'
                      ? Colors.red
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 56,
              decoration: BoxDecoration(
                color: stampColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: borderCol,
                  width: entry != null ? 1.5 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 8,
                          color:
                              entry != null &&
                                  entry.stampType != StampType.whiteBaby
                              ? Colors.white70
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (hasBaby)
                    Icon(Icons.child_care, size: 24, color: babyIconColor)
                  else if (hasGreenBaby)
                    const Icon(Icons.child_care, size: 24, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                entry != null ? DateFormat('MMM dd').format(entry.date) : '-',
                style: const TextStyle(fontSize: 8, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              height: 24,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                entry?.resolvedVdrsCode ?? '',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              height: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasPain)
                    const Icon(
                      Icons.local_fire_department,
                      size: 10,
                      color: Colors.redAccent,
                    ),
                  if (hasComments) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.notes, size: 10, color: Colors.blueAccent),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCycle(BuildContext context, Cycle cycle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Cycle?'),
          content: Text(
            'Are you sure you want to delete the cycle starting ${DateFormat('yyyy-MM-dd').format(cycle.startDate)}? All observations will be lost permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await Services.db.deleteCycle(cycle.id);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddObservationDialog(BuildContext context, Cycle? cycle) {
    showDialog(
      context: context,
      builder: (context) =>
          AddObservationDialog(cycle: cycle, defaultDate: DateTime.now()),
    );
  }

  void _showAddObservationDialogForDate(
    BuildContext context,
    Cycle? cycle,
    DateTime date,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          AddObservationDialog(cycle: cycle, defaultDate: date),
    );
  }

  void _showDailyDetailSheet(
    BuildContext context,
    DailyEntry entry,
    Cycle cycle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DailyDetailSheet(entry: entry, cycle: cycle),
    );
  }
}

// ==========================================
// 4. ADD OBSERVATION DIALOG
// ==========================================

enum WizardStep {
  bleedingFlow('Bleeding'),
  bleedingColor('Blood Color'),
  sensation('Sensation'),
  lubrication('Lubrication'),
  mucus('Mucus'),
  mucusStretch('Stretch'),
  mucusColor('Mucus Color'),
  mucusConsistency('Consistency'),
  pain('Pain'),
  painDetails('Pain Details'),
  comments('Comments & Save');

  final String title;
  const WizardStep(this.title);
}

class AddObservationDialog extends StatefulWidget {
  final Cycle? cycle;
  final DateTime defaultDate;

  const AddObservationDialog({
    super.key,
    this.cycle,
    required this.defaultDate,
  });

  @override
  State<AddObservationDialog> createState() => _AddObservationDialogState();
}

class _AddObservationDialogState extends State<AddObservationDialog> {
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
  String? _colorSelection; // 'cloudy', 'clear', 'cloudy_clear', 'yellow'
  bool _isGummy = false;
  bool _isPasty = false;
  bool _hasSelectedConsistency = false;

  // Pain (nullable so no option is pre-selected)
  bool? _hasPain;
  final List<String> _painTypes = [];
  bool _abdominalLeft = false;
  bool _abdominalRight = false;
  double _painLevel = 3.0;

  List<String> get _formattedPainTypes {
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

  // Comments
  final _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.defaultDate.year,
      widget.defaultDate.month,
      widget.defaultDate.day,
    );
    _selectedTime = TimeOfDay(
      hour: widget.defaultDate.hour,
      minute: widget.defaultDate.minute,
    );
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  bool get _isHeavyOrModerateBleeding =>
      _hasBleeding == true &&
      (_bleedingFlow == Bleeding.heavy || _bleedingFlow == Bleeding.moderate);

  List<WizardStep> get _activeSteps {
    final steps = [WizardStep.bleedingFlow];
    if (_hasBleeding == true) {
      steps.add(WizardStep.bleedingColor);
    }
    if (!_isHeavyOrModerateBleeding) {
      steps.add(WizardStep.sensation);
      if (_sensation != null && _sensation != Sensation.dry) {
        steps.add(WizardStep.lubrication);
      }
      steps.add(WizardStep.mucus);
      if (_hasMucus == true) {
        steps.add(WizardStep.mucusStretch);
        steps.add(WizardStep.mucusColor);
        steps.add(WizardStep.mucusConsistency);
      }
    }
    steps.add(WizardStep.pain);
    if (_hasPain == true) {
      steps.add(WizardStep.painDetails);
    }
    steps.add(WizardStep.comments);
    return steps;
  }

  WizardStep get _currentStep {
    final active = _activeSteps;
    if (_currentStepIndex >= active.length) {
      return active.last;
    }
    return active[_currentStepIndex];
  }

  void _nextStep() {
    final active = _activeSteps;
    if (_currentStepIndex < active.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSteps = _activeSteps;
    if (_currentStepIndex >= activeSteps.length) {
      _currentStepIndex = activeSteps.length - 1;
    }
    final step = _currentStep;
    final isLastStep = _currentStepIndex == activeSteps.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 500,
        height: 540,
        child: Column(
          children: [
            // WIZARD HEADER WITH PERSISTENT DATE/TIME BAR & TOP-RIGHT CLOSE BUTTON
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Log Observation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Step ${_currentStepIndex + 1} of ${activeSteps.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Persistent Date & Time Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'EEE, MMM dd, yyyy • h:mm a',
                            ).format(_combinedDateTime),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.edit_calendar,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Change Date',
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate:
                                  widget.cycle?.startDate ??
                                  DateTime.now().subtract(
                                    const Duration(days: 730),
                                  ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                            );
                            if (pickedDate != null) {
                              setState(() => _selectedDate = pickedDate);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.access_time,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Change Time',
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (pickedTime != null) {
                              setState(() => _selectedTime = pickedTime);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Linear Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStepIndex + 1) / activeSteps.length,
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),

            // STEP CONTENT AREA
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey<WizardStep>(step),
                    child: _buildStepContent(context, step),
                  ),
                ),
              ),
            ),

            // WIZARD FOOTER NAVIGATION
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStepIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                    ),
                  const Spacer(),
                  if (step == WizardStep.painDetails)
                    FilledButton.icon(
                      onPressed: _nextStep,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Continue'),
                    ),
                  if (isLastStep)
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveLog,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('Save Log'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGrid({
    required List<Widget> children,
    double spacing = 10,
    double targetMinItemWidth = 180.0,
    List<int> fullWidthIndexes = const [],
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int crossAxisCount = (availableWidth / (targetMinItemWidth + spacing))
            .floor();
        if (crossAxisCount < 1) crossAxisCount = 1;

        final itemWidth =
            (availableWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;

        final gridChildren = <Widget>[];
        for (int i = 0; i < children.length; i++) {
          final isFullWidth = fullWidthIndexes.contains(i);
          final width = isFullWidth ? availableWidth : itemWidth;
          gridChildren.add(SizedBox(width: width, child: children[i]));
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: gridChildren,
        );
      },
    );
  }

  Widget _buildStepContent(BuildContext context, WizardStep step) {
    final theme = Theme.of(context);

    switch (step) {
      case WizardStep.bleedingFlow:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bleeding or Menstrual Flow',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'What bleeding or flow did you observe at this check?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildOptionGrid(
                fullWidthIndexes: const [0],
                children: [
                  _OptionCard(
                    label: 'No Bleeding',
                    icon: Icons.check_circle_outline,
                    subtitle: 'No menstrual flow or spotting observed',
                    isSelected: _hasBleeding == false,
                    onTap: () {
                      setState(() {
                        _hasBleeding = false;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Spotting',
                    icon: Icons.water_drop_outlined,
                    subtitle: 'Very light spotting or trace bleeding',
                    isSelected:
                        _hasBleeding == true &&
                        _bleedingFlow == Bleeding.spotting,
                    onTap: () {
                      setState(() {
                        _hasBleeding = true;
                        _bleedingFlow = Bleeding.spotting;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Light',
                    icon: Icons.water_drop,
                    subtitle: 'Light menstrual flow',
                    isSelected:
                        _hasBleeding == true && _bleedingFlow == Bleeding.light,
                    onTap: () {
                      setState(() {
                        _hasBleeding = true;
                        _bleedingFlow = Bleeding.light;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Moderate',
                    icon: Icons.water_drop,
                    subtitle: 'Moderate menstrual flow',
                    isSelected:
                        _hasBleeding == true &&
                        _bleedingFlow == Bleeding.moderate,
                    onTap: () {
                      setState(() {
                        _hasBleeding = true;
                        _bleedingFlow = Bleeding.moderate;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Heavy',
                    icon: Icons.opacity,
                    subtitle: 'Heavy menstrual flow',
                    isSelected:
                        _hasBleeding == true && _bleedingFlow == Bleeding.heavy,
                    onTap: () {
                      setState(() {
                        _hasBleeding = true;
                        _bleedingFlow = Bleeding.heavy;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.bleedingColor:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What color is the blood?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the blood color observed during this check:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildOptionGrid(
                fullWidthIndexes: const [0],
                children: [
                  _OptionCard(
                    label: 'Red',
                    icon: Icons.water_drop,
                    subtitle: 'Bright red or normal blood',
                    isSelected: _bleedingColor == 'R',
                    onTap: () {
                      setState(() => _bleedingColor = 'R');
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Brown',
                    icon: Icons.water_drop_outlined,
                    subtitle: 'Dark brown or oxidized blood',
                    isSelected: _bleedingColor == 'B',
                    onTap: () {
                      setState(() => _bleedingColor = 'B');
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Black',
                    icon: Icons.water_drop_sharp,
                    subtitle: 'Very dark or black blood',
                    isSelected: _bleedingColor == 'Black',
                    onTap: () {
                      setState(() => _bleedingColor = 'Black');
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.sensation:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sensation at Vulva',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the sensation felt at the vulva during this check:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'Dry',
                    icon: Icons.wb_sunny_outlined,
                    subtitle: 'No moisture or sensation felt',
                    isSelected: _sensation == Sensation.dry,
                    onTap: () {
                      setState(() {
                        _sensation = Sensation.dry;
                        _hasLubrication = false;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Damp',
                    icon: Icons.water_drop_outlined,
                    subtitle: 'Slight moisture felt',
                    isSelected: _sensation == Sensation.damp,
                    onTap: () {
                      setState(() => _sensation = Sensation.damp);
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Wet',
                    icon: Icons.opacity,
                    subtitle: 'Noticeable wet sensation',
                    isSelected: _sensation == Sensation.wet,
                    onTap: () {
                      setState(() => _sensation = Sensation.wet);
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Shiny',
                    icon: Icons.auto_awesome,
                    subtitle: 'Glistening or shiny appearance',
                    isSelected: _sensation == Sensation.shiny,
                    onTap: () {
                      setState(() => _sensation = Sensation.shiny);
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.lubrication:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lubricative Sensation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Was there a smooth, slippery, or lubricative feel during this check?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'No Lubrication',
                    icon: Icons.block,
                    subtitle: 'No lubricative or slippery feel',
                    isSelected: _hasLubrication == false,
                    onTap: () {
                      setState(() => _hasLubrication = false);
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Yes Lubrication',
                    icon: Icons.auto_awesome,
                    subtitle: 'Smooth, slippery, or lubricative feel',
                    isSelected: _hasLubrication == true,
                    onTap: () {
                      setState(() => _hasLubrication = true);
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.mucus:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mucus Observation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Was there any mucus present during this check?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'No Mucus',
                    icon: Icons.block,
                    subtitle: 'No mucus observed on tissue/fingers',
                    isSelected: _hasMucus == false,
                    onTap: () {
                      setState(() {
                        _hasMucus = false;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Yes Mucus',
                    icon: Icons.science_outlined,
                    subtitle: 'Mucus observed during this check',
                    isSelected: _hasMucus == true,
                    onTap: () {
                      setState(() {
                        _hasMucus = true;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.mucusStretch:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finger Test Stretch',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How far does the mucus stretch between your fingers during this check?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: _OptionCard(
                      label: 'Sticky',
                      icon: Icons.straighten,
                      subtitle: '1/4" | 0.5 cm',
                      isSelected: _stretch == Stretch.sticky,
                      onTap: () {
                        setState(() => _stretch = Stretch.sticky);
                        _nextStep();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 0.75,
                    child: _OptionCard(
                      label: 'Tacky',
                      icon: Icons.straighten,
                      subtitle: '1/2 - 3/4" | 1.0 - 2.0 cm',
                      isSelected: _stretch == Stretch.tacky,
                      onTap: () {
                        setState(() => _stretch = Stretch.tacky);
                        _nextStep();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 1.0,
                    child: _OptionCard(
                      label: 'Stretchy',
                      icon: Icons.straighten,
                      subtitle: '1"+ | 2.5+ cm',
                      isSelected: _stretch == Stretch.stretchy,
                      onTap: () {
                        setState(() => _stretch = Stretch.stretchy);
                        _nextStep();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.mucusColor:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mucus Color',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'What color was the mucus observed during this check?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'Cloudy',
                    icon: Icons.cloud_outlined,
                    subtitle: 'Off-white or cloudy appearance',
                    isSelected: _colorSelection == 'cloudy',
                    onTap: () {
                      setState(() => _colorSelection = 'cloudy');
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Clear',
                    icon: Icons.water_drop_outlined,
                    subtitle: 'Transparent or clear appearance',
                    isSelected: _colorSelection == 'clear',
                    onTap: () {
                      setState(() => _colorSelection = 'clear');
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Cloudy / Clear',
                    icon: Icons.bubble_chart_outlined,
                    subtitle: 'Mix of cloudy and clear mucus',
                    isSelected: _colorSelection == 'cloudy_clear',
                    onTap: () {
                      setState(() => _colorSelection = 'cloudy_clear');
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Yellow',
                    icon: Icons.wb_sunny_outlined,
                    subtitle: 'Yellowish tint observed',
                    isSelected: _colorSelection == 'yellow',
                    onTap: () {
                      setState(() => _colorSelection = 'yellow');
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.mucusConsistency:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mucus Consistency',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the consistency of the mucus observed during this check:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildOptionGrid(
                fullWidthIndexes: const [0],
                children: [
                  _OptionCard(
                    label: 'Neither',
                    icon: Icons.check_circle_outline,
                    subtitle: 'Neither gummy nor pasty (normal)',
                    isSelected:
                        !_isGummy && !_isPasty && _hasSelectedConsistency,
                    onTap: () {
                      setState(() {
                        _isGummy = false;
                        _isPasty = false;
                        _hasSelectedConsistency = true;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Gummy (Gluey)',
                    icon: Icons.bubble_chart_outlined,
                    subtitle: 'Rubber-like or gluey texture',
                    isSelected: _isGummy && !_isPasty,
                    onTap: () {
                      setState(() {
                        _isGummy = true;
                        _isPasty = false;
                        _hasSelectedConsistency = true;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Pasty (Creamy)',
                    icon: Icons.format_paint_outlined,
                    subtitle: 'Creamy or pasty texture',
                    isSelected: _isPasty && !_isGummy,
                    onTap: () {
                      setState(() {
                        _isGummy = false;
                        _isPasty = true;
                        _hasSelectedConsistency = true;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.pain:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pain or Symptoms',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you experiencing any physical pain or cramps right now?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'No Pain',
                    icon: Icons.sentiment_satisfied_alt,
                    subtitle: 'No discomfort experienced',
                    isSelected: _hasPain == false,
                    onTap: () {
                      setState(() {
                        _hasPain = false;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Yes (Log Pain)',
                    icon: Icons.healing,
                    subtitle: 'Cramps, abdominal pain, etc.',
                    isSelected: _hasPain == true,
                    onTap: () {
                      setState(() {
                        _hasPain = true;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.painDetails:
        final isAbdominalSelected = _painTypes.contains('Abdominal Pain');

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pain Location & Severity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select pain location and severity rating:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Location / Type:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Cramps',
                      'Abdominal Pain',
                      'Backache',
                      'Headache',
                      'Pelvic Pain',
                    ].map((p) {
                      final isSelected = _painTypes.contains(p);
                      return FilterChip(
                        showCheckmark: false,
                        label: Text(p),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _painTypes.add(p);
                            } else {
                              _painTypes.remove(p);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              if (isAbdominalSelected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Abdominal Side (Optional):',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        showCheckmark: false,
                        label: const Text('Left'),
                        selected: _abdominalLeft,
                        onSelected: (val) {
                          setState(() => _abdominalLeft = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        showCheckmark: false,
                        label: const Text('Right'),
                        selected: _abdominalRight,
                        onSelected: (val) {
                          setState(() => _abdominalRight = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Severity Rating:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _painLevel,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: '${_painLevel.toInt()}/10',
                      onChanged: (val) => setState(() => _painLevel = val),
                    ),
                  ),
                  Text(
                    '${_painLevel.toInt()}/10',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.comments:
        final hasBleeding = _hasBleeding ?? false;
        final flowLabel = _bleedingFlow != null
            ? _bleedingFlow!.label
            : 'Light';
        final colorLabel = _bleedingColor ?? 'R';
        final hasMucus = _hasMucus ?? false;
        final hasPain = _hasPain ?? false;
        final hasLubrication = _hasLubrication ?? false;

        return SingleChildScrollView(
          child: Column(
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
                      'Date: ${DateFormat('MMM dd, yyyy • h:mm a').format(_combinedDateTime)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Bleeding: ${hasBleeding ? "$flowLabel ($colorLabel)" : "None"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (!_isHeavyOrModerateBleeding) ...[
                      Text(
                        'Sensation: ${_sensation?.label ?? "Dry"}${hasLubrication ? " (Lubricative)" : ""}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Mucus: ${hasMucus ? "${_stretch?.label ?? 'Sticky'}, ${_colorSelection ?? 'cloudy'}" : "None"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    Text(
                      'Pain: ${hasPain ? "${_formattedPainTypes.isNotEmpty ? _formattedPainTypes.join(', ') : 'Logged'} (${_painLevel.toInt()}/10)" : "None"}',
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
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add extra details or observations...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        );
    }
  }

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);

    final bool hasBleeding = _hasBleeding ?? false;
    // Compute bleeding enum
    final Bleeding bleeding = hasBleeding
        ? (_bleedingFlow ?? Bleeding.light)
        : Bleeding.none;
    final String bleedingColorStr = hasBleeding ? (_bleedingColor ?? 'R') : '';

    // Compute sensation, stretch, colors, consistencies
    Sensation sensation = Sensation.dry;
    Stretch stretch = Stretch.none;
    final List<MucusColor> colors = [];
    final List<Consistency> consistencies = [];

    if (!_isHeavyOrModerateBleeding) {
      sensation = _sensation ?? Sensation.dry;

      if ((_hasLubrication ?? false) && sensation != Sensation.dry) {
        consistencies.add(Consistency.lubricative);
      }

      if (_hasMucus ?? false) {
        stretch = _stretch ?? Stretch.sticky;

        // Color mapping
        if (_colorSelection == 'cloudy') {
          colors.add(MucusColor.cloudy);
        } else if (_colorSelection == 'clear') {
          colors.add(MucusColor.clear);
        } else if (_colorSelection == 'cloudy_clear') {
          colors.add(MucusColor.cloudy);
          colors.add(MucusColor.clear);
        } else if (_colorSelection == 'yellow') {
          colors.add(MucusColor.yellow);
        }

        // Consistency mapping
        if (_isGummy) consistencies.add(Consistency.gummy);
        if (_isPasty) consistencies.add(Consistency.pasty);
      }
    }

    final bool hasPain = _hasPain ?? false;
    final double painLevel = hasPain ? _painLevel : 0.0;
    final List<String> painTypes = hasPain ? _formattedPainTypes : [];

    try {
      await Services.db.saveObservation(
        cycleId: widget.cycle?.id,
        date: _combinedDateTime,
        sensation: sensation,
        stretch: stretch,
        colors: colors,
        consistencies: consistencies,
        bleeding: bleeding,
        bleedingColor: bleedingColorStr,
        painLevel: painLevel,
        painTypes: painTypes,
        comment: _commentController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving observation: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
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
                      size: 18,
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.85)
                        : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
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

// ==========================================
// 5. DAILY DETAIL SHEET
// ==========================================

class DailyDetailSheet extends StatelessWidget {
  final DailyEntry entry;
  final Cycle cycle;

  const DailyDetailSheet({super.key, required this.entry, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final observations = entry.observations;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Observations for ${DateFormat('EEEE, MMM dd').format(entry.date)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStampBadge(entry.stampType, entry.peakDayLabel),
              const SizedBox(width: 12),
              Text(
                'Resolved Code: ${entry.resolvedVdrsCode}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (entry.comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes Summary: ${entry.comments}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          if (entry.painLevel > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Pain Level: ${entry.painLevel.toInt()}/10 (${entry.painTypes.join(", ")})',
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Logged Entries (${observations.length}):',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (observations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No individual observations. (Click grid to add)',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: observations.length,
              itemBuilder: (context, index) {
                final obs = observations[index];
                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    title: Text('Code: ${obs.vdrsCode}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sensation: ${obs.sensation.label} | Stretch: ${obs.stretch.label}',
                        ),
                        if (obs.comment.isNotEmpty)
                          Text('Notes: ${obs.comment}'),
                        Text(
                          'Logged at ${DateFormat('hh:mm a').format(obs.timestamp)} by ${obs.userId == "husband_uid" ? "Husband" : "Wife"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await Services.db.deleteObservation(
                          cycleId: cycle.id,
                          date: entry.date,
                          observationId: obs.id,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) =>
                    AddObservationDialog(cycle: cycle, defaultDate: entry.date),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Another Observation for This Day'),
          ),
        ],
      ),
    );
  }

  Widget _buildStampBadge(StampType type, String? label) {
    Color bg = Colors.grey;
    Color border = Colors.grey;
    bool hasBaby = false;
    Color babyColor = Colors.black;

    switch (type) {
      case StampType.red:
        bg = Colors.red.shade400;
        border = Colors.red.shade600;
        break;
      case StampType.green:
        bg = Colors.green.shade400;
        border = Colors.green.shade600;
        break;
      case StampType.whiteBaby:
        bg = Colors.white;
        border = Colors.green.shade600;
        hasBaby = true;
        babyColor = Colors.green.shade700;
        break;
      case StampType.greenBaby:
        bg = Colors.green.shade400;
        border = Colors.green.shade600;
        hasBaby = true;
        babyColor = Colors.white;
        break;
      case StampType.yellow:
        bg = Colors.yellow.shade400;
        border = Colors.yellow.shade600;
        break;
      case StampType.yellowBaby:
        bg = Colors.yellow.shade400;
        border = Colors.yellow.shade600;
        hasBaby = true;
        babyColor = Colors.green.shade800;
        break;
    }

    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (label != null)
            Positioned(
              top: 2,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          if (hasBaby)
            Positioned(
              bottom: 4,
              child: Icon(Icons.child_care, size: 20, color: babyColor),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. SETTINGS & BIP SCREEN
// ==========================================

class SettingsScreen extends StatefulWidget {
  final Cycle? activeCycle;

  const SettingsScreen({super.key, this.activeCycle});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _inviteEmailController = TextEditingController();
  bool _isInviting = false;
  String _inviteStatus = '';

  // Set of BIP codes
  final List<String> _availableBipOptions = [
    '6-C',
    '6-Y',
    '6-W',
    '8-C',
    '8-Y',
    '8-W',
  ];
  List<String> _selectedBips = [];

  @override
  void initState() {
    super.initState();
    if (widget.activeCycle != null) {
      _selectedBips = List<String>.from(widget.activeCycle!.bipCodes);
    }
  }

  Future<void> _sendInvite() async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isInviting = true;
      _inviteStatus = '';
    });

    try {
      await Services.db.invitePartner(email);
      setState(() {
        _inviteStatus = 'Invitation successfully sent to $email!';
        _inviteEmailController.clear();
      });
    } catch (e) {
      setState(() {
        _inviteStatus =
            'Error: ${e.toString().replaceFirst("Exception: ", "")}';
      });
    } finally {
      setState(() {
        _isInviting = false;
      });
    }
  }

  Future<void> _toggleBipCode(String code, bool selected) async {
    if (widget.activeCycle == null) return;

    setState(() {
      if (selected) {
        _selectedBips.add(code);
      } else {
        _selectedBips.remove(code);
      }
    });

    // Save to database which triggers automatic recalculation of stamps!
    await Services.db.updateBipCodes(widget.activeCycle!.id, _selectedBips);
  }

  void _confirmDeleteChart(BuildContext context, String chartId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Chart?'),
          content: Text(
            'Are you sure you want to permanently delete the chart "$chartId" and all of its cycles/observations? This will delete the data for all collaborators and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                try {
                  await Services.db.deleteChart(chartId);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error deleting chart: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLeaveChart(BuildContext context, String chartId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Chart?'),
          content: Text(
            'Are you sure you want to leave the chart "$chartId"? You will lose access to its cycles and observations, but the data will remain active for other collaborators.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                try {
                  await Services.db.leaveChart(chartId);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error leaving chart: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Leave Chart'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Services.db.currentUser;
    final chartId = Services.db.currentChartId;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Configuration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User profile info card
            Card(
              elevation: 0,
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.4,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user?.email ?? "Offline Mode"}'),
                    Text(
                      'Role: ${user?.uid == "husband_uid" ? "Husband" : "Wife"}',
                    ),
                    Text('Shared Chart ID: ${chartId ?? "Not linked"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Base Infertile Pattern (BIP) Configuration
            if (widget.activeCycle != null) ...[
              Text(
                'Base Infertile Pattern (BIP) Config',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Define which cervical mucus VDRS codes constitute the wife\'s standard BIP. The system will automatically paint matching days with Yellow stamps (denoting infertility) instead of White Baby stamps.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _availableBipOptions.map((code) {
                  final isSelected = _selectedBips.contains(code);
                  return FilterChip(
                    label: Text(code),
                    selected: isSelected,
                    onSelected: (selected) => _toggleBipCode(code, selected),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
            ],

            // Invite Partner Form
            Text(
              'Invite Partner to Collaborate',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your spouse\'s email address. Once they sign up and log in, they will be prompted to join this cycle chart and can view or log observations in real time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inviteEmailController,
              decoration: const InputDecoration(
                labelText: 'Partner Email Address',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _isInviting
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _sendInvite,
                    child: const Text('Send Collaboration Invite'),
                  ),
            if (_inviteStatus.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _inviteStatus,
                style: TextStyle(
                  color: _inviteStatus.startsWith('Error')
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
            if (chartId != null) ...[
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),
              Text(
                'Danger Zone',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Services.db.streamAvailableCharts(),
                builder: (context, snapshot) {
                  final charts = snapshot.data ?? [];
                  final activeChart = charts.firstWhere(
                    (c) => c['id'] == chartId,
                    orElse: () => <String, dynamic>{},
                  );
                  final userIds = List<String>.from(
                    activeChart['userIds'] ?? [],
                  );
                  final hasOtherCollaborators = userIds.length > 1;

                  return Card(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.1,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Permanently delete this chart and all associated cycle logs and observations. This action is destructive and cannot be undone.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () =>
                                _confirmDeleteChart(context, chartId),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete Chart'),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                            ),
                          ),
                          if (hasOtherCollaborators) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              'Leave this chart. You will lose access to its observations, but the data will remain active for other collaborators.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _confirmLeaveChart(context, chartId),
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text('Leave Chart'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () {
                Services.db.signOut();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
