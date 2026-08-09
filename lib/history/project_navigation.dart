import 'package:flutter/material.dart';

/// Route names for the project dashboard navigation stack.
///
/// Child screens pushed from [DashboardScreen] use [childRouteName] so
/// [popToDashboard] can unwind back to the dashboard without leaving
/// the home list underneath.
abstract final class ProjectNavigation {
  static const dashboardRouteName = 'project-dashboard';
  static const childRouteName = 'project-child';

  static Route<T> dashboardRoute<T>(Widget child) => MaterialPageRoute<T>(
        settings: const RouteSettings(name: dashboardRouteName),
        builder: (_) => child,
      );

  static Route<T> childRoute<T>(Widget child) => MaterialPageRoute<T>(
        settings: const RouteSettings(name: childRouteName),
        builder: (_) => child,
      );

  static void popToDashboard(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == dashboardRouteName,
    );
  }
}
