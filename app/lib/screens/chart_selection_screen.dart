import 'package:flutter/material.dart';
import '../logic/logic.dart';

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

  Future<void> _acceptInvite(String invitationId) async {
    setState(() => _isLoading = true);
    try {
      await Services.db.acceptInvitation(invitationId);
      await _loadInvitations();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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

  Future<void> _declineInvite(String invitationId) async {
    setState(() => _isLoading = true);
    try {
      await Services.db.declineInvitation(invitationId);
      await _loadInvitations();
    } catch (e) {
      debugPrint('Error declining invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Error declining invitation: $e'),
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
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first chart to start tracking cycles, or accept a partner\'s invitation.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Pending invitations list
                if (_pendingInvites.isNotEmpty) ...[
                  Card(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.mail,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pending Chart Invitations',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pendingInvites.length,
                            itemBuilder: (context, index) {
                              final invite = _pendingInvites[index];
                              final invitationId =
                                  (invite['invitationId'] ??
                                          invite['id'] ??
                                          invite['chartId'])
                                      as String;
                              final chartId = invite['chartId'] as String;
                              final senderEmail =
                                  invite['senderEmail'] as String;

                              return Card(
                                child: ListTile(
                                  title: Text('Chart from $senderEmail'),
                                  subtitle: Text('ID: $chartId'),
                                  trailing: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _declineInvite(invitationId),
                                              child: const Text('Decline'),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton(
                                              onPressed: () =>
                                                  _acceptInvite(invitationId),
                                              child: const Text('Accept'),
                                            ),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Create Chart action
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.icon(
                        onPressed: _createChart,
                        icon: const Icon(Icons.add_chart),
                        label: Text(
                          charts.isEmpty
                              ? 'Create First Chart'
                              : 'Create New Chart',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
