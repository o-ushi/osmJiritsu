import 'package:flutter/material.dart';
import '../navigation/osm_page_route.dart';

/// Route names for the project dashboard navigation stack.
///
/// Child screens pushed from [DashboardScreen] use [childRouteName] so
/// [popToDashboard] can unwind back to the dashboard without leaving
/// the home list underneath.
abstract final class ProjectNavigation {
  static const dashboardRouteName = 'project-dashboard';
  static const childRouteName = 'project-child';

  static Route<T> dashboardRoute<T>(Widget child) => osmPageRoute<T>(
    settings: const RouteSettings(name: dashboardRouteName),
    builder: (_) => child,
  );

  static Route<T> childRoute<T>(Widget child) => osmPageRoute<T>(
    settings: const RouteSettings(name: childRouteName),
    builder: (_) => child,
  );

  static void popToDashboard(BuildContext context) {
    Navigator.of(context).popUntil(
      // No named dashboard route (opened from home's split right pane):
      // stop at home instead of popping it too.
      (route) => route.settings.name == dashboardRouteName || route.isFirst,
    );
  }
}
