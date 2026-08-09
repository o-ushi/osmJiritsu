import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../theme/subpage_theme.dart';
import '../wizard/state/wizard_notifier.dart';
import 'app_navigation.dart';
import 'state/analysis_history_notifier.dart';

/// Shared callbacks for [ProjectBottomToolbar].
class ProjectToolbarActions {
  ProjectToolbarActions(this.ref, this.lang, this.projectId);

  final WidgetRef ref;
  final AppLanguage lang;
  final String projectId;

  Project currentProject() {
    final projects = ref.read(analysisHistoryProvider).value ?? const [];
    for (final project in projects) {
      if (project.id == projectId) return project;
    }
    final wizard = ref.read(wizardProvider);
    return wizard.toProject();
  }

  Future<void> pickShareFormat(BuildContext context) async {
    final choice = await showReadableBottomSheet<_ShareFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '共有形式を選んでください'.tr(lang),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '共有_テキスト説明'.tr(lang),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.sceneTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: Text('要報'.tr(lang)),
              subtitle: Text('共有_要報説明'.tr(lang)),
              onTap: () => Navigator.of(context).pop(_ShareFormat.brief),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text('詳報'.tr(lang)),
              subtitle: Text('共有_詳報説明'.tr(lang)),
              onTap: () => Navigator.of(context).pop(_ShareFormat.detailed),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    await _share(choice);
  }

  Future<void> _share(_ShareFormat format) async {
    final project = currentProject();
    final text = switch (format) {
      _ShareFormat.brief => project.shareSummary,
      _ShareFormat.detailed => project.dashboardShareSummary,
    };
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'osmJiritsu 自律計画'),
    );
  }

  void openSettings(BuildContext context) => openSettingsScreen(context);

  void openHelp(BuildContext context) => openHelpScreen(context);
}

enum _ShareFormat { brief, detailed }
