import 'package:flutter/material.dart';

import '../../logic/utils/app_version.dart';

class DashboardDrawer extends StatelessWidget {
  final VoidCallback onNavigateToCharts;
  final VoidCallback onSelectSupplements;
  final VoidCallback onNavigateToSettings;
  final Future<void> Function()? onSignOut;

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
            onTap: onSignOut != null ? () => onSignOut!() : null,
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
