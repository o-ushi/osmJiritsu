import 'package:flutter/material.dart';

import '../help/screens/help_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../navigation/osm_page_route.dart';

/// Pushes [SettingsScreen] — shared by [HistoryToolbarActions] and
/// [ProjectToolbarActions] so the two bottom toolbars (home and project)
/// don't each carry their own copy of this one-line navigation.
void openSettingsScreen(BuildContext context) {
  Navigator.of(
    context,
  ).push(osmPageRoute(builder: (_) => const SettingsScreen()));
}

/// Pushes [HelpScreen] — see [openSettingsScreen].
void openHelpScreen(BuildContext context) {
  Navigator.of(context).push(osmPageRoute(builder: (_) => const HelpScreen()));
}
