import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../subpage_theme.dart';

/// osmGradus's "subpage" shape: settings/help/privacy-style screens that
/// stay on a fixed light background with fixed dark text
/// ([AppPalette.subpageBackground]/[AppPalette.subpageText]) rather than
/// following the dynamic [AppPalette.scene] — so they read reliably no
/// matter how dark or unusual a scene/frame the user has chosen. Wraps a
/// local [Theme] override (not just `Scaffold.backgroundColor`) so every
/// descendant that reads `Theme.of(context)` — including [ListTile] /
/// [SwitchListTile], which take their colors from [ColorScheme.onSurface]
/// in Material 3 — stays correctly dark on this always-light background.
class SubpageScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  const SubpageScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return SubpageTheme.wrap(
      context: context,
      child: Scaffold(
        backgroundColor: AppPalette.subpageBackground,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
