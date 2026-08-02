import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cycle.dart';
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
