import 'package:flutter/material.dart';

import '../../logic/utils/app_version.dart';

/// Navigation drawer displayed on the dashboard screen.
///
/// Provides navigation items to switch charts, manage supplements and schedule,
/// open app settings, and sign out, as well as displaying the current [AppVersion].
class DashboardDrawer extends StatelessWidget {
  /// Callback invoked when navigating to the chart management view.
  final VoidCallback onNavigateToCharts;

  /// Callback invoked when opening the supplements and schedule modal or screen.
  final VoidCallback onSelectSupplements;

  /// Callback invoked when navigating to the settings screen.
  final VoidCallback onNavigateToSettings;

  /// Optional callback invoked when the user taps Sign Out.
  ///
  /// When null, the Sign Out list tile is disabled (`enabled: false`, `onTap: null`),
  /// which allows the drawer to be rendered in unauthenticated, read-only, or guest
  /// contexts where signing out is not applicable.
  final VoidCallback? onSignOut;

  /// Creates a [DashboardDrawer].
  const DashboardDrawer({
    super.key,
    required this.onNavigateToCharts,
    required this.onSelectSupplements,
    required this.onNavigateToSettings,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          ListTile(
            key: const Key('drawer_switch_chart_tile'),
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch Chart'),
            onTap: onNavigateToCharts,
          ),
          ListTile(
            key: const Key('drawer_supplements_tile'),
            leading: const Icon(Icons.medication_outlined),
            title: const Text('Supplements & Schedule'),
            onTap: onSelectSupplements,
          ),
          ListTile(
            key: const Key('drawer_settings_tile'),
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: onNavigateToSettings,
          ),
          ListTile(
            key: const Key('drawer_logout_tile'),
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            enabled: onSignOut != null,
            onTap: onSignOut,
          ),
          const Divider(),
          ListTile(
            key: const Key('drawer_version_tile'),
            leading: const Icon(Icons.info_outline),
            title: Text(AppVersion.display),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
