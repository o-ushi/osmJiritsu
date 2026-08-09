import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../models/project.dart';
import '../wizard/screens/wizard_flow_screen.dart';
import '../wizard/state/wizard_notifier.dart';
import '../wizard/state/wizard_state.dart';
import 'app_navigation.dart';
import 'data/analysis_file_io.dart';
import 'services/analysis_export_service.dart';
import 'state/analysis_history_notifier.dart';

/// Shared callbacks for [HistoryBottomToolbar] — used on the home screen
/// and every Stage-1 flow screen so export/import/settings/help behave the
/// same everywhere.
class HistoryToolbarActions {
  HistoryToolbarActions(this.ref, this.lang);

  final WidgetRef ref;
  final AppLanguage lang;

  void startNew(BuildContext context) {
    ref.read(wizardProvider.notifier).reset();
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WizardFlowScreen()));
  }

  Future<void> export(BuildContext context) async {
    final projects = ref.read(analysisHistoryProvider).value ?? const [];
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エクスポートできる分析がまだありません'.tr(lang))),
      );
      return;
    }
    final projectOrder = projects.map((p) => p.id).toList();
    final jsonText = AnalysisExportService.encodeProjects(
      projects,
      projectOrder: projectOrder,
    );
    final fileName = AnalysisExportService.exportFileName();
    await ref
        .read(analysisFileIOProvider)
        .shareJsonFile(fileName: fileName, jsonText: jsonText);
  }

  Future<void> import(BuildContext context) async {
    final jsonText = await ref.read(analysisFileIOProvider).pickJsonFile();
    if (jsonText == null) return;

    try {
      final backup = AnalysisExportService.decodeBackup(jsonText);
      final importedCount = await ref
          .read(analysisHistoryProvider.notifier)
          .importBackup(backup);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('%lld件の分析を読み込みました'.trFmt(lang, ['$importedCount'])),
        ),
      );
    } on FormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('読み込みに失敗しました: %@'.trFmt(lang, [error.message]))),
      );
    }
  }

  void openSettings(BuildContext context) => openSettingsScreen(context);

  void openHelp(BuildContext context) => openHelpScreen(context);

  /// Saves the in-progress wizard draft (when it has content), then returns
  /// to [HistoryListScreen] without calling [WizardNotifier.reset].
  ///
  /// Uses [WizardState.toProjectPreserving] when a history record already
  /// exists for this session, so a theme/goal-only draft cannot wipe a
  /// previously saved SWOT matrix for the same id.
  void goHome(BuildContext context, {required bool persistWizard}) {
    if (persistWizard) {
      final wizard = ref.read(wizardProvider);
      if (_wizardHasContent(wizard)) {
        final history = ref.read(analysisHistoryProvider).value ?? const [];
        Project? existing;
        for (final project in history) {
          if (project.id == wizard.sessionId) {
            existing = project;
            break;
          }
        }
        final toSave = existing != null
            ? wizard.toProjectPreserving(existing)
            : wizard.toProject();
        ref.read(analysisHistoryProvider.notifier).saveOrUpdate(toSave);
      }
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static bool _wizardHasContent(WizardState wizard) =>
      wizard.theme.trim().isNotEmpty ||
      wizard.desiredGoal.trim().isNotEmpty ||
      wizard.undesiredGoal.trim().isNotEmpty ||
      wizard.ideas.isNotEmpty ||
      wizard.decidedStrategy.trim().isNotEmpty ||
      wizard.decidedFirstStep.trim().isNotEmpty;
}
