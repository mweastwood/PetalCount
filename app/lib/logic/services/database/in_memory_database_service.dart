import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/cycle.dart';
import '../../models/daily_entry.dart';
import '../../models/notification_preferences.dart';
import '../../models/observation.dart';
import '../../models/supplement.dart';
import '../../models/user_role.dart';
import '../../utils/date_utils.dart';
import '../creighton_logic.dart';
import '../cycle_coordinator.dart';
import 'database_helpers.dart';
import 'database_service_interface.dart';

part 'in_memory/in_memory_auth_user_ops.dart';
part 'in_memory/in_memory_chart_ops.dart';
part 'in_memory/in_memory_cycle_ops.dart';
part 'in_memory/in_memory_seed_data.dart';
part 'in_memory/in_memory_supplement_ops.dart';

// Local mock user object matching Firebase structure
class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool isAnonymous;
  MockUser({required this.uid, this.email, this.isAnonymous = false});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

abstract class _InMemoryDatabaseServiceBase implements DatabaseService {
  final _authController = StreamController<User?>.broadcast();
  final _chartsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _roleController = StreamController<String?>.broadcast();
  final _cyclesController = StreamController<List<Cycle>>.broadcast();
  final _supplementsController =
      StreamController<List<SupplementItem>>.broadcast();
  final _supplementLogsController =
      StreamController<Map<String, DailySupplementLog>>.broadcast();
  User? _currentUser;
  String? _chartId;

  // Fake Cloud database in-memory
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _charts = {};
  final Map<String, Map<String, Map<String, dynamic>>> _cycles =
      {}; // chartId -> { cycleId -> cycleData }
  final Map<String, Map<String, SupplementItem>> _supplements =
      {}; // chartId -> { supplementId -> SupplementItem }
  final Map<String, Map<String, DailySupplementLog>> _supplementLogs =
      {}; // chartId -> { dateKey -> DailySupplementLog }
  final List<Map<String, dynamic>> _invitations = [];
  final List<String> _fcmTokens = [];
  String? _userTimezone;

  void _emitCharts() {
    final user = _currentUser;
    if (user == null) {
      _chartsController.add([]);
      return;
    }
    final list = _charts.values
        .where((chart) => (chart['userIds'] as List).contains(user.uid))
        .toList();
    _chartsController.add(list);
  }

  void _emitCycles() {
    final chartId = _chartId;
    if (chartId == null) {
      _cyclesController.add([]);
      return;
    }

    final chartCyclesData = _cycles[chartId] ?? {};
    final list = chartCyclesData.values.map((d) => Cycle.fromMap(d)).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    _cyclesController.add(list);
  }

  void _emitSupplements() {
    final chartId = _chartId;
    if (chartId == null) {
      _supplementsController.add([]);
      return;
    }
    final chartSupplements = _supplements[chartId] ?? {};
    _supplementsController.add(chartSupplements.values.toList());
  }

  void _emitSupplementLogs() {
    final chartId = _chartId;
    if (chartId == null) {
      _supplementLogsController.add({});
      return;
    }
    final chartLogs = _supplementLogs[chartId] ?? {};
    _supplementLogsController.add(Map.unmodifiable(chartLogs));
  }
}

class InMemoryDatabaseService extends _InMemoryDatabaseServiceBase
    with
        _InMemorySeedData,
        _InMemoryAuthUserOps,
        _InMemoryChartOps,
        _InMemoryCycleOps,
        _InMemorySupplementOps {
  InMemoryDatabaseService() {
    // Start with a mock user logged in by default for instant local preview/usability
    _currentUser = MockUser(uid: 'husband_uid', email: 'husband@example.com');
    _users['husband_uid'] = {
      'uid': 'husband_uid',
      'email': 'husband@example.com',
      'role': 'husband',
      'chartId': 'mock_shared_chart',
    };
    _users['wife_uid'] = {
      'uid': 'wife_uid',
      'email': 'wife@example.com',
      'role': 'wife',
      'chartId': 'mock_shared_chart',
    };
    _chartId = 'mock_shared_chart';

    _charts['mock_shared_chart'] = {
      'id': 'mock_shared_chart',
      'userIds': ['husband_uid', 'wife_uid'],
      'emails': ['husband@example.com', 'wife@example.com'],
      'reminderEnabled': true,
      'notificationPreferences': {
        'fertilePatternAlerts': true,
        'partnerSupportReminders': true,
        'dailyLoggingReminder': true,
      },
    };

    // Prepopulate with a mock cycle so the app opens with data immediately
    final mockCycleStart = DateTime(2026, 6, 1);
    final mockCycle = Cycle(
      id: mockCycleStart.dateKey,
      startDate: mockCycleStart,
      bipCodes: const ['6C'],
      dailyEntries: {},
    );

    _cycles['mock_shared_chart'] = {mockCycle.id: mockCycle.toMap()};

    // Add some mock daily observations to represent a standard cycle
    _prepopulateMockData(mockCycle.id, mockCycleStart);

    // Prepopulate supplements for mock chart
    _supplements['mock_shared_chart'] = {
      for (final item in SupplementPresets.defaultList) item.id: item,
    };

    _authController.stream.listen((user) {
      _emitCycles();
    });
    _authController.add(_currentUser);
  }
}
