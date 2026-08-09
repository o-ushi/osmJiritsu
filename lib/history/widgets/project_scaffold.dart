import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_language_notifier.dart';
import '../project_navigation.dart';
import '../project_toolbar_actions.dart';
export 'project_bottom_toolbar.dart';
import 'project_bottom_toolbar.dart';

/// Scaffold wrapper for the project dashboard and screens opened from it.
class ProjectScaffold extends ConsumerWidget {
  const ProjectScaffold({
    super.key,
    this.appBar,
    required this.body,
    required this.projectId,
    required this.mode,
    this.onReflection,
    this.guideMessageKey,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final String projectId;
  final ProjectToolbarMode mode;
  final VoidCallback? onReflection;

  /// Translation key for this screen's 操作方法 sheet content — see
  /// [OperationGuideSheet.bodyKey]. Null falls back to the generic guide.
  final String? guideMessageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final actions = ProjectToolbarActions(ref, lang, projectId);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appBar,
      body: body,
      bottomNavigationBar: keyboardOpen
          ? null
          : ProjectBottomToolbar(
              lang: lang,
              mode: mode,
              onShare: () => actions.pickShareFormat(context),
              onReflection: onReflection,
              onReturn: () => ProjectNavigation.popToDashboard(context),
              onSettings: () => actions.openSettings(context),
              onHelp: () => actions.openHelp(context),
              guideMessageKey: guideMessageKey,
            ),
    );
  }
}
