import 'package:flutter/material.dart';

import '../logic/logic.dart';
import 'add_observation_dialog.dart';
import 'creighton_stamp_widget.dart';

class DailyDetailSheet extends StatelessWidget {
  final DailyEntry entry;
  final Cycle cycle;
  final Stream<String?>? userRoleStream;
  final String? currentUserRole;
  final String? currentUserId;

  const DailyDetailSheet({
    super.key,
    required this.entry,
    required this.cycle,
    this.userRoleStream,
    this.currentUserRole,
    this.currentUserId,
  });

  static String resolveAuthor(
    Observation observation, {
    String? currentUserRole,
    String? currentUserId,
  }) {
    // 1. Direct Role: If observation.userRole is present, display resolved displayName ("Husband" or "Wife").
    if (observation.userRole != null && observation.userRole!.isNotEmpty) {
      return UserRole.fromString(observation.userRole).displayName;
    }

    // 2. Mock UID Fallback: For in-memory / legacy mock UIDs.
    if (observation.userId == 'husband_uid') {
      return UserRole.husband.displayName;
    }
    if (observation.userId == 'wife_uid') {
      return UserRole.wife.displayName;
    }

    // 3. Current User / Partner Fallback:
    // If current user role is not yet available (e.g. stream loading), return empty string
    // to avoid prematurely defaulting to "Wife".
    if (currentUserRole == null || currentUserRole.trim().isEmpty) {
      return '';
    }

    // If observation has no userId or currentUserId is unavailable, do not falsely attribute.
    if (currentUserId == null ||
        currentUserId.isEmpty ||
        observation.userId.isEmpty) {
      return '';
    }

    // Attribute to current user's known role if matching, or partner's opposite role.
    final currentRole = UserRole.fromString(currentUserRole);
    if (observation.userId == currentUserId) {
      return currentRole.displayName;
    } else {
      return currentRole.partnerRole.displayName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCurrentUserId =
        currentUserId ?? Services.db.currentUser?.uid;

    return StreamBuilder<List<Cycle>>(
      stream: Services.db.streamCycles(),
      builder: (context, cyclesSnapshot) {
        final dateKey = entry.date.dateKey;
        Cycle? matchedCycle;
        DailyEntry? matchedEntry;
        final streamedCycles = cyclesSnapshot.data;
        if (streamedCycles != null && streamedCycles.isNotEmpty) {
          for (final candidateCycle in streamedCycles) {
            if (candidateCycle.dailyEntries.containsKey(dateKey)) {
              matchedCycle = candidateCycle;
              matchedEntry = candidateCycle.dailyEntries[dateKey];
              break;
            }
          }
          if (matchedCycle == null) {
            for (final candidateCycle in streamedCycles) {
              if (candidateCycle.id == cycle.id) {
                matchedCycle = candidateCycle;
                matchedEntry = candidateCycle.dailyEntries[dateKey];
                break;
              }
            }
          }
        }
        final activeCycle = matchedCycle ?? cycle;
        final activeEntry = matchedEntry ?? entry;

        return StreamBuilder<String?>(
          stream: userRoleStream ?? Services.db.streamUserRole(),
          initialData: currentUserRole,
          builder: (context, snapshot) {
            final currentRole = snapshot.data;
            return _buildContent(
              context,
              activeCycle,
              activeEntry,
              currentRole,
              effectiveCurrentUserId,
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Cycle activeCycle,
    DailyEntry activeEntry,
    String? currentRole,
    String? effectiveCurrentUserId,
  ) {
    final theme = Theme.of(context);
    final observations = activeEntry.observations;

    return SingleChildScrollView(
      child: Padding(
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
                  'Observations for ${AppDateFormats.weekdayMonthDay.format(activeEntry.date)}',
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
                CreightonStampWidget.badge(
                  stampType: activeEntry.stampType,
                  peakDayLabel: activeEntry.peakDayLabel,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resolved Code: ${activeEntry.resolvedVdrsCode}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activeEntry.hasIntercourse) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.pink.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.pink.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Intercourse (I)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (activeEntry.comments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes Summary: ${activeEntry.comments}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            if (activeEntry.painLevel > 0) ...[
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
                    'Pain Level: ${activeEntry.painLevel.toInt()}/10 (${activeEntry.painTypes.join(", ")})',
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
                  final observation = observations[index];
                  final details = <String>[
                    'Sensation: ${observation.sensation.label}',
                    'Stretch: ${observation.stretch.label}',
                    if (observation.frequency != Frequency.none)
                      'Freq: ${observation.frequency.label}',
                    if (observation.intercourse) 'Intercourse (I)',
                  ];
                  final author = resolveAuthor(
                    observation,
                    currentUserRole: currentRole,
                    currentUserId: effectiveCurrentUserId,
                  );
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ListTile(
                      title: Text('Code: ${observation.vdrsCode}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(details.join(' | ')),
                          if (observation.comment.isNotEmpty)
                            Text('Notes: ${observation.comment}'),
                          Text(
                            author.isNotEmpty
                                ? 'Logged at ${AppDateFormats.timeOfDayPadded.format(observation.timestamp)} by $author'
                                : 'Logged at ${AppDateFormats.timeOfDayPadded.format(observation.timestamp)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          final shouldCloseSheet = observations.length <= 1;
                          await Services.db.deleteObservation(
                            cycleId: activeCycle.id,
                            date: activeEntry.date,
                            observationId: observation.id,
                          );
                          if (shouldCloseSheet && context.mounted) {
                            Navigator.of(context).pop();
                          }
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
                  builder: (context) => AddObservationDialog(
                    cycle: activeCycle,
                    defaultDate: activeEntry.date,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Another Observation for This Day'),
            ),
          ],
        ),
      ),
    );
  }
}
