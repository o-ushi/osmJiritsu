import 'package:flutter/material.dart';

import '../help/screens/help_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../navigation/osm_page_route.dart';
import 'home_split.dart';
import 'project_navigation.dart';
import 'widgets/home_split_pane.dart';

/// Pushes [SettingsScreen] — shared by [HistoryToolbarActions] and
/// [ProjectToolbarActions] so the two bottom toolbars (home and project)
/// don't each carry their own copy of this one-line navigation.
/// In home's split (iPad landscape) it opens in the right pane only.
void openSettingsScreen(BuildContext context) =>
    _openPaneScreen(context, (_) => const SettingsScreen());

/// Pushes [HelpScreen] — see [openSettingsScreen].
void openHelpScreen(BuildContext context) =>
    _openPaneScreen(context, (_) => const HelpScreen());

void _openPaneScreen(BuildContext context, WidgetBuilder builder) {
  if (HomeSplitScope.isActive(context)) {
    HomeSplitScope.paneOrNavigatorOf(
      context,
    ).push(osmPageRoute(builder: builder));
    return;
  }
  // Full screen. Opened from home or a full-screen dashboard, it may move
  // into the split's right pane later (see [_MoveToHomeSplit]). Opened from
  // anything else (a wizard, a child screen), it stays put: closing it
  // would leave that screen full screen anyway.
  final opener = ModalRoute.of(context);
  final movable =
      opener == null ||
      opener.isFirst ||
      opener.settings.name == ProjectNavigation.dashboardRouteName;
  Navigator.of(context).push(
    osmPageRoute(
      builder: movable
          ? (_) => _MoveToHomeSplit(builder: builder)
          : builder,
    ),
  );
}

/// A full-screen 設定 / ヘルプ that ends up on top while the window is wide
/// enough for home's split (rotated to landscape, or back from one of its
/// own sub-screens) closes and reopens in the split's right pane. A
/// full-screen dashboard under it then moves into the split on its own.
class _MoveToHomeSplit extends StatelessWidget {
  const _MoveToHomeSplit({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null &&
        route.isCurrent &&
        homeSplitActive(MediaQuery.sizeOf(context))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pane = HomeSplitScope.activePane;
        if (!context.mounted || !route.isCurrent || pane == null) return;
        Navigator.of(context).pop();
        pane.push(osmPageRoute(builder: builder));
      });
    }
    return builder(context);
  }
}
