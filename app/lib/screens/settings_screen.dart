import 'package:flutter/material.dart';

import '../logic/logic.dart';
import 'settings/settings.dart';

class SettingsScreen extends StatefulWidget {
  final Cycle? activeCycle;

  const SettingsScreen({super.key, this.activeCycle});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Stream<List<Map<String, dynamic>>> _chartsStream;
  late final Stream<String?> _roleStream;

  @override
  void initState() {
    super.initState();
    _chartsStream = Services.db.streamAvailableCharts();
    _roleStream = Services.db.streamUserRole();
  }

  @override
  Widget build(BuildContext context) {
    final chartId = Services.db.currentChartId;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Configuration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User profile info card
            ProfileSettingsCard(roleStream: _roleStream),
            const SizedBox(height: 24),

            // Base Infertile Pattern (BIP) Configuration
            if (widget.activeCycle != null) ...[
              BipConfigCard(activeCycle: widget.activeCycle!),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
            ],

            // Invite Partner Form
            const PartnerInviteCard(),

            // Notification preferences & Danger zone
            if (chartId != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chartsStream,
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 24),
                      NotificationPreferencesSection(
                        chartId: chartId,
                        activeCycle: widget.activeCycle,
                        chartsStream: _chartsStream,
                      ),
                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 24),
                      DangerZoneCard(
                        chartId: chartId,
                        hasOtherCollaborators: hasOtherCollaborators,
                      ),
                    ],
                  );
                },
              ),

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
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            // Debug & Diagnostics Card
            const DebugDiagnosticsCard(),
          ],
        ),
      ),
    );
  }
}
