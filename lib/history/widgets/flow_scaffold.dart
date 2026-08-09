import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_language_notifier.dart';
import '../history_toolbar_actions.dart';
import 'history_bottom_toolbar.dart';

/// Scaffold wrapper for Stage-1 pipeline screens: same bottom toolbar as home,
/// but the centre button returns home (saving the wizard draft first).
class FlowScaffold extends ConsumerWidget {
  const FlowScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.persistWizardOnHome = true,
    this.toolbarMode = HistoryToolbarMode.flow,
    this.onToolbarAdd,
    this.onToolbarUndo,
    this.canUndo = false,
    this.guideMessageKey,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool persistWizardOnHome;
  final HistoryToolbarMode toolbarMode;
  final VoidCallback? onToolbarAdd;
  final VoidCallback? onToolbarUndo;
  final bool canUndo;

  /// Translation key for this screen's 操作方法 sheet content — see
  /// [OperationGuideSheet.bodyKey]. Null falls back to the generic guide.
  final String? guideMessageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final actions = HistoryToolbarActions(ref, lang);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appBar,
      body: body,
      bottomNavigationBar: keyboardOpen
          ? null
          : HistoryBottomToolbar(
              lang: lang,
              mode: toolbarMode,
              onHome: () => actions.goHome(
                context,
                persistWizard: persistWizardOnHome,
              ),
              onAdd: onToolbarAdd,
              onUndo: onToolbarUndo,
              canUndo: canUndo,
              onExport: () => actions.export(context),
              onImport: () => actions.import(context),
              onAddNew: () => actions.startNew(context),
              onSettings: () => actions.openSettings(context),
              onHelp: () => actions.openHelp(context),
              guideMessageKey: guideMessageKey,
            ),
    );
  }
}
