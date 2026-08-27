import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class ProfileSettingsCard extends StatelessWidget {
  final Stream<String?>? roleStream;

  const ProfileSettingsCard({super.key, this.roleStream});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Services.db.currentUser;
    final chartId = Services.db.currentChartId;

    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<String?>(
          stream: roleStream ?? Services.db.streamUserRole(),
          builder: (context, roleSnapshot) {
            final currentRole = UserRole.fromString(
              roleSnapshot.data ??
                  (user?.uid == "husband_uid" ? "husband" : "wife"),
            );
            return Column(
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
                Text('Role: ${currentRole.displayName}'),
                Text('Shared Chart ID: ${chartId ?? "Not linked"}'),
                const SizedBox(height: 12),
                Text(
                  'Partner Role',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<UserRole>(
                  key: const Key('role_segmented_button'),
                  segments: const [
                    ButtonSegment<UserRole>(
                      value: UserRole.wife,
                      label: Text('Wife / Tracker'),
                      icon: Icon(Icons.female),
                    ),
                    ButtonSegment<UserRole>(
                      value: UserRole.husband,
                      label: Text('Husband / Partner'),
                      icon: Icon(Icons.male),
                    ),
                  ],
                  selected: {currentRole},
                  onSelectionChanged: (Set<UserRole> newSelection) async {
                    final selected = newSelection.first;
                    await Services.db.updateUserRole(selected.code);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
