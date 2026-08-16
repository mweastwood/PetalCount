import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'app_config.dart';
import 'app_logger.dart';
import 'models/cycle.dart';
import 'models/daily_entry.dart';
import 'models/observation.dart';
import 'services/database_service.dart';
import 'services/services.dart';
import 'services/web_download_helper.dart';

typedef FileSaver = Future<void> Function(String filename, List<int> bytes);

class AppStateExporter {
  final DatabaseService _db;
  final AppLogger? _logger;
  final FileSaver? fileSaver;

  AppStateExporter({DatabaseService? db, AppLogger? logger, this.fileSaver})
    : _db = db ?? Services.db,
      _logger = logger ?? (Services.loggerInitialized ? Services.logger : null);

  static AppStateExporter get instance => AppStateExporter();

  static String maskEmail(String email) {
    if (!email.contains('@')) return '***';
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) {
      return '${name[0]}***@$domain';
    }
    return '${name[0]}***${name[name.length - 1]}@$domain';
  }

  static String maskPii(String text) {
    final emailRegex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    );
    return text.replaceAllMapped(emailRegex, (match) {
      return maskEmail(match.group(0)!);
    });
  }

  dynamic sanitizeForJson(dynamic value, {bool sanitizePii = false}) {
    if (value == null) return null;

    if (value is bool || value is num) {
      return value;
    }

    if (value is String) {
      return sanitizePii ? maskPii(value) : value;
    }

    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }

    if (value is DocumentReference) {
      return value.path;
    }

    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }

    if (value is Enum) {
      return value.name;
    }

    if (value is Duration) {
      return value.inMilliseconds;
    }

    if (value is Cycle) {
      return sanitizeForJson(value.toMap(), sanitizePii: sanitizePii);
    }

    if (value is DailyEntry) {
      return sanitizeForJson(value.toMap(), sanitizePii: sanitizePii);
    }

    if (value is Observation) {
      return sanitizeForJson(value.toMap(), sanitizePii: sanitizePii);
    }

    if (value is AppLogEvent) {
      return sanitizeForJson(value.toJson(), sanitizePii: sanitizePii);
    }

    if (value is Map) {
      final sanitizedMap = <String, dynamic>{};
      value.forEach((k, v) {
        final keyStr = k.toString();
        final isEmailKey =
            sanitizePii &&
            (keyStr.toLowerCase().contains('email') || keyStr == 'emails');

        if (isEmailKey) {
          if (v is String) {
            sanitizedMap[keyStr] = maskEmail(v);
          } else if (v is Iterable) {
            sanitizedMap[keyStr] = v
                .map((e) => e != null ? maskEmail(e.toString()) : null)
                .toList();
          } else {
            sanitizedMap[keyStr] = sanitizeForJson(v, sanitizePii: sanitizePii);
          }
        } else {
          sanitizedMap[keyStr] = sanitizeForJson(v, sanitizePii: sanitizePii);
        }
      });
      return sanitizedMap;
    }

    if (value is Iterable) {
      return value
          .map((item) => sanitizeForJson(item, sanitizePii: sanitizePii))
          .toList();
    }

    return value.toString();
  }

  Future<Map<String, dynamic>> exportStateRaw({
    bool sanitizePii = false,
  }) async {
    final user = _db.currentUser;
    final chartId = _db.currentChartId;

    final metadata = <String, dynamic>{
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'environment': AppConfig.environment.name,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'appVersion': '1.0.0',
    };

    bool isAnon = false;
    try {
      isAnon = user?.isAnonymous ?? false;
    } catch (_) {}

    final authState = <String, dynamic>{
      'isSignedIn': user != null,
      'uid': user?.uid,
      'email': user?.email != null
          ? (sanitizePii ? maskEmail(user!.email!) : user!.email)
          : null,
      'isAnonymous': isAnon,
      'activeChartId': chartId,
    };

    final databaseState = <String, dynamic>{};

    if (_db is FirebaseDatabaseService && user != null) {
      final firestore = FirebaseFirestore.instance;

      try {
        // User profile document
        final userDocSnap = await firestore
            .collection('users')
            .doc(user.uid)
            .get();
        databaseState['userDoc'] = userDocSnap.exists
            ? userDocSnap.data()
            : {'_exists': false};

        // Current active chart document
        Map<String, dynamic>? activeChartData;
        List<String> activeChartUserIds = [];
        if (chartId != null) {
          final chartDocSnap = await firestore
              .collection('charts')
              .doc(chartId)
              .get();
          if (chartDocSnap.exists) {
            activeChartData = chartDocSnap.data();
            activeChartUserIds = List<String>.from(
              activeChartData?['userIds'] ?? [],
            );
            databaseState['activeChartDoc'] = activeChartData;
          } else {
            databaseState['activeChartDoc'] = {'_exists': false, 'id': chartId};
          }

          // Cycles subcollection
          final cyclesSnap = await firestore
              .collection('charts')
              .doc(chartId)
              .collection('cycles')
              .get();
          databaseState['cycles'] = cyclesSnap.docs
              .map((doc) => doc.data())
              .toList();
        } else {
          databaseState['activeChartDoc'] = null;
          databaseState['cycles'] = [];
        }

        // Available charts where user is in userIds
        final availableChartsSnap = await firestore
            .collection('charts')
            .where('userIds', arrayContains: user.uid)
            .get();
        databaseState['availableCharts'] = availableChartsSnap.docs
            .map((doc) => doc.data())
            .toList();

        // Pending invitations for user email
        if (user.email != null && user.email!.isNotEmpty) {
          final cleanEmail = user.email!.trim().toLowerCase();
          final invitesSnap = await firestore
              .collection('invitations')
              .where('invitationId', isEqualTo: cleanEmail)
              .get();
          databaseState['invitations'] = invitesSnap.docs
              .map((doc) => doc.data())
              .toList();
        }

        // Diagnostic rule assessment
        final bool isUserInChart = activeChartUserIds.contains(user.uid);
        final bool chartExists = activeChartData != null;
        final String diagnosis;
        if (chartId == null) {
          diagnosis = 'NO_ACTIVE_CHART: activeChartId is null.';
        } else if (!chartExists) {
          diagnosis =
              'CHART_NOT_FOUND: Chart "$chartId" does not exist in Firestore. get() rule lookup will fail with permission-denied.';
        } else if (!isUserInChart) {
          diagnosis =
              'USER_NOT_IN_CHART_USERIDS: User "${user.uid}" is NOT in chart.userIds ($activeChartUserIds). Writes to /charts/$chartId/cycles will be denied by firestore.rules.';
        } else {
          diagnosis =
              'MEMBERSHIP_VALID: User is authorized in chart.userIds. If permission errors persist, check deployed firestore.rules in Firebase Console.';
        }

        databaseState['diagnostics'] = {
          'hasUserDoc': userDocSnap.exists,
          'hasActiveChartDoc': chartExists,
          'isUserInActiveChartUserIds': isUserInChart,
          'activeChartUserIds': activeChartUserIds,
          'diagnosis': diagnosis,
        };
      } catch (e, st) {
        databaseState['error'] = 'Error fetching Firestore state: $e';
        databaseState['stackTrace'] = st.toString();
      }
    } else {
      // In-memory or offline state export
      databaseState['mode'] = 'in_memory_or_mock';
      try {
        final cycles = await _db.streamCycles().first.timeout(
          const Duration(seconds: 1),
          onTimeout: () => [],
        );
        databaseState['cycles'] = cycles.map((c) => c.toMap()).toList();
      } catch (_) {
        databaseState['cycles'] = [];
      }
    }

    final rawLogs = _logger?.logs ?? [];
    final eventLogs = rawLogs
        .map((e) => sanitizeForJson(e.toJson(), sanitizePii: sanitizePii))
        .toList();

    return {
      'exportMetadata': metadata,
      'auth': authState,
      'databaseState': databaseState,
      'eventLogs': eventLogs,
    };
  }

  Future<String> exportStateJson({
    bool pretty = true,
    bool sanitizePii = false,
  }) async {
    final raw = await exportStateRaw(sanitizePii: sanitizePii);
    final sanitized = sanitizeForJson(raw, sanitizePii: sanitizePii);
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(sanitized);
  }

  Future<void> shareDebugState(
    BuildContext context, {
    FileSaver? fileSaver,
  }) async {
    _logger?.info('Debug state export initiated', category: 'export');

    // Show loading progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting diagnostic state...'),
              ],
            ),
          ),
        ),
      ),
    );

    String jsonContent;
    try {
      jsonContent = await exportStateJson(pretty: true, sanitizePii: false);
    } catch (e, st) {
      _logger?.error(
        'Failed to generate export JSON',
        category: 'export',
        error: e,
        stackTrace: st,
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Dismiss loading dialog before file saving/sharing to avoid double-pop bugs
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final timestampStr = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '_');
    final filename = 'debug_app_state_$timestampStr.json';
    final bytes = utf8.encode(jsonContent);

    final saver = fileSaver ?? this.fileSaver;

    try {
      if (saver != null) {
        await saver(filename, bytes);
        _logger?.info(
          'Debug state saved via custom fileSaver',
          category: 'export',
        );
      } else if (kIsWeb) {
        downloadFileWeb(bytes, filename, mimeType: 'application/json');
        _logger?.info(
          'Debug state downloaded on web platform',
          category: 'export',
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/json')],
            subject: 'PetalCount Debug State',
          ),
        );
        _logger?.info(
          'Debug state shared via native share sheet',
          category: 'export',
        );
      }
    } catch (e, st) {
      _logger?.warning(
        'File save/share failed, falling back to clipboard copy',
        category: 'export',
        error: e,
        stackTrace: st,
      );

      await Clipboard.setData(ClipboardData(text: jsonContent));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debug state JSON copied to clipboard (file share failed).',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
