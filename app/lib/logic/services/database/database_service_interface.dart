import 'package:firebase_auth/firebase_auth.dart';

import '../../models/cycle.dart';
import '../../models/notification_preferences.dart';
import '../../models/observation.dart';

abstract class DatabaseService {
  User? get currentUser;
  String? get currentChartId;
  Stream<User?> get authStateChanges;

  Future<void> signInWithGoogle();
  Future<void> signOut();

  Future<void> createChart();
  Future<void> invitePartner(String partnerEmail);
  Future<List<Map<String, dynamic>>> getPendingInvitations();
  Future<void> acceptInvitation(String invitationId);
  Future<void> declineInvitation(String invitationId);
  Future<void> unlinkChart();
  Stream<List<Map<String, dynamic>>> streamAvailableCharts();
  Future<void> setActiveChart(String chartId);
  Future<void> deleteChart(String chartId);
  Future<void> leaveChart(String chartId);
  Future<void> updateChartReminderSettings(String chartId, bool enabled);
  Stream<bool> streamChartReminderEnabled(String chartId);
  Future<void> updateNotificationPreferences(
    String chartId,
    NotificationPreferences preferences,
  );
  Stream<NotificationPreferences> streamNotificationPreferences(String chartId);
  Future<void> updateUserRole(String role);
  Stream<String?> streamUserRole();
  Future<void> saveFcmToken(String token);
  Future<void> removeFcmToken(String token);
  Future<void> updateUserTimezone(String timezone);

  Stream<List<Cycle>> streamCycles();
  Future<void> startNewCycle(DateTime startDate, List<String> bipCodes);
  Future<void> deleteCycle(String cycleId);
  Future<void> updateBipCodes(String cycleId, List<String> bipCodes);
  Future<void> updateCycleStartDate(String cycleId, DateTime newStartDate);
  Future<void> mergeCycleWithPrevious(String cycleId);

  Future<void> saveObservation({
    String? cycleId,
    required DateTime date,
    required Sensation sensation,
    required Stretch stretch,
    required List<MucusColor> colors,
    required List<Consistency> consistencies,
    required Bleeding bleeding,
    required String bleedingColor,
    required double painLevel,
    required List<String> painTypes,
    required String comment,
    bool? isVdrsExplicit,
  });

  Future<void> deleteObservation({
    required String cycleId,
    required DateTime date,
    required String observationId,
  });
}
