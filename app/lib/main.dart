import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/cycle.dart';
import 'models/daily_entry.dart';
import 'models/observation.dart';
import 'services/services.dart';
import 'services/pdf_export_service.dart';

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
    return MaterialApp(
      title: 'PetalCount',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: const Color(0xFFD81B60),
          secondary: const Color(0xFF8E24AA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: const Color(0xFFF48FB1),
          secondary: const Color(0xFFCE93D8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
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
          return const SetupChartScreen();
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Services.db.signIn(_emailController.text, _passwordController.text);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text('Create an Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Services.db.signUp(_emailController.text, _passwordController.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_vintage,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty) ...[
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _signUp,
                        child: const Text('Create Account'),
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
// 2. SETUP CHART / LINK PARTNER SCREEN
// ==========================================

class SetupChartScreen extends StatefulWidget {
  const SetupChartScreen({super.key});

  @override
  State<SetupChartScreen> createState() => _SetupChartScreenState();
}

class _SetupChartScreenState extends State<SetupChartScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingInvites = [];

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    final invites = await Services.db.getPendingInvitations();
    setState(() {
      _pendingInvites = invites;
    });
  }

  Future<void> _createChart() async {
    setState(() => _isLoading = true);
    await Services.db.createChart();
    setState(() => _isLoading = false);
  }

  Future<void> _acceptInvite(String chartId) async {
    setState(() => _isLoading = true);
    await Services.db.acceptInvitation(chartId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Chart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Services.db.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 48),
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
                        subtitle: const Text('To link to their cycle chart'),
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
      ),
    );
  }
}

// ==========================================
// 3. DASHBOARD SCREEN & CHART GRID
// ==========================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedCycleIndex = 0;
  late final Stream<List<Cycle>> _cyclesStream;

  @override
  void initState() {
    super.initState();
    _cyclesStream = Services.db.streamCycles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            title: Row(
              children: [
                Icon(Icons.filter_vintage, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'PetalCount Chart',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              if (cycles.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export Chart to PDF',
                  onPressed: () => PdfExportService.exportCyclesToPdf(cycles),
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        activeCycle: cycles.isNotEmpty
                            ? cycles[_selectedCycleIndex]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: cycles.isEmpty
              ? _buildNoCyclesView(context)
              : _buildDashboard(context, cycles),
          floatingActionButton: cycles.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddObservationDialog(
                    context,
                    cycles[_selectedCycleIndex],
                  ),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Log Observation'),
                )
              : null,
        );
      },
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
              Icons.calendar_today_outlined,
              size: 80,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Cycles Started Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click the button below to start your very first cycle chart. Typically, Day 1 is the first day of menstruation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _startNewCycleDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Start First Cycle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<Cycle> cycles) {
    // Ensure selected index is within bounds
    if (_selectedCycleIndex >= cycles.length) {
      _selectedCycleIndex = 0;
    }

    final cycle = cycles[_selectedCycleIndex];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cycle Switcher & Header
        Container(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: _selectedCycleIndex < cycles.length - 1
                    ? () {
                        setState(() {
                          _selectedCycleIndex++;
                        });
                      }
                    : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Cycle starting ${DateFormat('MMM dd, yyyy').format(cycle.startDate)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cycle Day: ${cycle.dailyEntries.length} logged  |  BIP: ${cycle.bipCodes.isEmpty ? 'None' : cycle.bipCodes.join(', ')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: _selectedCycleIndex > 0
                    ? () {
                        setState(() {
                          _selectedCycleIndex--;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),

        // The Scrollable Grid Chart
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCreightonGrid(context, cycle),
                const SizedBox(height: 32),
                _buildActionButtons(context, cycle),
                const SizedBox(height: 80), // Offset for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreightonGrid(BuildContext context, Cycle cycle) {
    final entries = cycle.sortedEntries;
    final theme = Theme.of(context);

    // Let's lay it out as a responsive GridView or custom Wrap that represents the standard row of stamps
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

    // Setup stamp aesthetics
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
          // Log directly for this day
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
            // Peak Day Label (P, 1, 2, 3)
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
            // Stamp Card
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
                  // Cycle day number in light overlay
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
            // Date / VDRS Code
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
            // Comments / Pain indicator footer
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

  Widget _buildActionButtons(BuildContext context, Cycle cycle) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _startNewCycleDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Start Next Cycle'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmDeleteCycle(context, cycle),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              'Delete Cycle',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  // Dialog to start a new cycle (picks a start date and pre-populates BIP from current)
  void _startNewCycleDialog(BuildContext context) {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-DD').format(DateTime.now()),
    );
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start New Cycle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will close the active cycle and start a new one on Day 1.',
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date (Day 1)'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 90),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                    dateController.text = DateFormat(
                      'yyyy-MM-dd',
                    ).format(picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await Services.db.startNewCycle(selectedDate, const [
                  '6-C',
                ]); // Default BIP
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
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

  void _showAddObservationDialog(BuildContext context, Cycle cycle) {
    showDialog(
      context: context,
      builder: (context) =>
          AddObservationDialog(cycle: cycle, defaultDate: DateTime.now()),
    );
  }

  void _showAddObservationDialogForDate(
    BuildContext context,
    Cycle cycle,
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

class AddObservationDialog extends StatefulWidget {
  final Cycle cycle;
  final DateTime defaultDate;

  const AddObservationDialog({
    super.key,
    required this.cycle,
    required this.defaultDate,
  });

  @override
  State<AddObservationDialog> createState() => _AddObservationDialogState();
}

class _AddObservationDialogState extends State<AddObservationDialog> {
  late DateTime _selectedDate;
  Bleeding _bleeding = Bleeding.none;
  String _bleedingColor = '';
  Sensation _sensation = Sensation.dry;
  Stretch _stretch = Stretch.none;
  final List<MucusColor> _colors = [];
  final List<Consistency> _consistencies = [];
  double _painLevel = 0.0;
  final List<String> _painTypes = [];
  final _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.defaultDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add Daily Log',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Date of Observation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: widget.cycle.startDate,
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
            const Divider(),

            // 1. Bleeding Selection
            const Text(
              'Bleeding or Spotting',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Bleeding.values.map((b) {
                if (b == Bleeding.none) return const SizedBox();
                final isSelected = _bleeding == b;
                return ChoiceChip(
                  label: Text(b.label),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _bleeding = val ? b : Bleeding.none;
                      if (_bleeding == Bleeding.none) {
                        _bleedingColor = '';
                      } else if (_bleedingColor.isEmpty) {
                        _bleedingColor = 'R'; // Default to red
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_bleeding != Bleeding.none) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Blood Color: '),
                  ChoiceChip(
                    label: const Text('Red'),
                    selected: _bleedingColor == 'R',
                    onSelected: (val) =>
                        setState(() => _bleedingColor = val ? 'R' : ''),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Brown/Black'),
                    selected: _bleedingColor == 'B',
                    onSelected: (val) =>
                        setState(() => _bleedingColor = val ? 'B' : ''),
                  ),
                ],
              ),
            ],
            const Divider(),

            // 2. Sensation Selection
            const Text(
              'Sensation at Vulva',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Sensation>(
              initialValue: _sensation,
              items: Sensation.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _sensation = val;
                    // If lubricative, automatically check stretchy stretch & lubricative consistency
                    if (_sensation == Sensation.shiny) {
                      // default to no mucus, but shiny
                    }
                  });
                }
              },
            ),
            const Divider(),

            // 3. Mucus Stretch (Show if user checks mucus presence or damp/wet/shiny sensation)
            const Text(
              'Mucus Stretch (Finger Test)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Stretch>(
              initialValue: _stretch,
              items: Stretch.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _stretch = val;
                  });
                }
              },
            ),
            const Divider(),

            // 4. Color & Consistency (Show only if stretch is not none)
            if (_stretch != Stretch.none) ...[
              const Text(
                'Mucus Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: MucusColor.values.map((c) {
                  final isSelected = _colors.contains(c);
                  return FilterChip(
                    label: Text(c.label),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _colors.add(c);
                        } else {
                          _colors.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mucus Consistency/Texture',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: Consistency.values.map((c) {
                  final isSelected = _consistencies.contains(c);
                  return FilterChip(
                    label: Text(c.label),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _consistencies.add(c);
                        } else {
                          _consistencies.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Divider(),
            ],

            // 5. Pain Tracker
            const Text(
              'Pain/Symptoms',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Cramps', 'Ovulation Pain', 'Headache', 'Backache'].map((
                p,
              ) {
                final isSelected = _painTypes.contains(p);
                return FilterChip(
                  label: Text(p),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _painTypes.add(p);
                        if (_painLevel == 0) {
                          _painLevel =
                              3.0; // Give a default pain level if they checked a pain type
                        }
                      } else {
                        _painTypes.remove(p);
                        if (_painTypes.isEmpty) _painLevel = 0.0;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_painTypes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Pain Intensity: '),
                  Expanded(
                    child: Slider(
                      value: _painLevel,
                      min: 0.0,
                      max: 10.0,
                      divisions: 10,
                      label: _painLevel.toInt().toString(),
                      onChanged: (val) {
                        setState(() => _painLevel = val);
                      },
                    ),
                  ),
                  Text('${_painLevel.toInt()}/10'),
                ],
              ),
            ],
            const Divider(),

            // 6. Comments
            const Text(
              'Comments/Notes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText:
                    'Enter notes about symptoms, intercourse, dry feel, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveLog,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Log'),
        ),
      ],
    );
  }

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);
    try {
      await Services.db.saveObservation(
        cycleId: widget.cycle.id,
        date: _selectedDate,
        sensation: _sensation,
        stretch: _stretch,
        colors: _colors,
        consistencies: _consistencies,
        bleeding: _bleeding,
        bleedingColor: _bleedingColor,
        painLevel: _painLevel,
        painTypes: _painTypes,
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
      setState(() => _isSaving = false);
    }
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
