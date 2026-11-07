import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';
import '../../theme/subpage_theme.dart';

/// 新規作成の入口で出す2択 — 簡易モード / フルモード.
///
/// Resolves to [Project.modeSimple] / [Project.modeFull], or null when the
/// sheet was just dismissed. Every 新規追加 path funnels through
/// [HistoryToolbarActions.startNew], so this is the single place the choice
/// is made — including the 案件0件 landing, which used to open the wizard
/// outright.
Future<String?> showEntryModeSheet({
  required BuildContext context,
  required AppLanguage lang,
}) {
  // Rooted deliberately: 案件0件 のときは `landOnHome` の直後に
  // [HistoryListScreen] 側が rebuild するので、その配下の Navigator に
  // 積むとシートごと消えてしまう。
  return showReadableBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => _EntryModeSheet(lang: lang),
  );
}

class _EntryModeSheet extends StatelessWidget {
  const _EntryModeSheet({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'モードを選ぶ'.tr(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppPalette.subpageText,
              ),
            ),
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.bolt_rounded,
                      fill: AppPalette.amber,
                      foreground: AppPalette.primaryTextOn(AppPalette.amber),
                      title: '簡易モード'.tr(lang),
                      description: '簡易モード説明'.tr(lang),
                      onTap: () =>
                          Navigator.of(context).pop(Project.modeSimple),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.account_tree_rounded,
                      fill: AppPalette.mint,
                      foreground: Colors.white,
                      title: 'フルモード'.tr(lang),
                      description: 'フルモード説明'.tr(lang),
                      onTap: () => Navigator.of(context).pop(Project.modeFull),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.fill,
    required this.foreground,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color fill;
  final Color foreground;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34, color: foreground),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: foreground.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
