import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/chart_selection_screen.dart';
import '../screens/settings_screen.dart';
import 'models/cycle.dart';

enum ViewMode { observations, chart }

class AppRouteManager {
  final Uri? mockUri;

  AppRouteManager({this.mockUri});

  /// Updates the web URL path matching the current ViewMode (/observations or /chart)
  void updateUrlPath(ViewMode viewMode) {
    if (!kIsWeb) return;
    String path;
    switch (viewMode) {
      case ViewMode.observations:
        path = '/observations';
        break;
      case ViewMode.chart:
        path = '/chart';
        break;
    }
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(path),
      replace: true,
    );
  }

  /// Updates the web URL path matching an explicit route string
  void updateUrlPathRaw(String path) {
    if (!kIsWeb) return;
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(path),
      replace: true,
    );
  }

  /// Parses initial web URL parameters/paths to restore screen route on app load
  void handleUrlParameters({
    required BuildContext context,
    required ValueChanged<ViewMode> onViewModeChanged,
    required ViewMode currentViewMode,
    Cycle? activeCycle,
  }) {
    final uri = mockUri ?? Uri.base;

    String path = uri.path;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final routes = <String, VoidCallback>{
      'observations': () {
        onViewModeChanged(ViewMode.observations);
        updateUrlPath(ViewMode.observations);
      },
      'chart': () {
        onViewModeChanged(ViewMode.chart);
        updateUrlPath(ViewMode.chart);
      },
      'settings': () {
        onViewModeChanged(ViewMode.observations);
        updateUrlPathRaw('/settings');
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/settings'),
            builder: (context) => SettingsScreen(activeCycle: activeCycle),
          ),
        ).then((_) {
          if (!context.mounted) return;
          updateUrlPath(currentViewMode);
        });
      },
      'charts': () {
        onViewModeChanged(ViewMode.observations);
        updateUrlPathRaw('/charts');
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/charts'),
            builder: (context) => const ChartSelectionScreen(),
          ),
        ).then((_) {
          if (!context.mounted) return;
          updateUrlPath(currentViewMode);
        });
      },
    };

    final handler = routes[path];
    if (handler != null) {
      handler();
    }
  }
}
