import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../help/widgets/expand_card.dart';
import '../../history/state/start_screen_settings_notifier.dart';
import '../../icloud_sync/screens/icloud_sync_settings_screen.dart';
import '../../icloud_sync/services/icloud_sync_service.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../privacy/screens/privacy_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/subpage_scaffold.dart';

/// osmJiritsu's settings entry point: the language list, then collapsible
/// groups — 案内 / データ. プライバシー is opened from Help.
///
/// Full data wipe lives only on [PrivacyScreen] (one destructive entry).
/// Language here is the canonical picker; the start-screen flag is a
/// shortcut to the same [appLanguageProvider].
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.startExpanded = false});

  /// すべてのグループを開いた状態で始める。
  final bool startExpanded;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// 開いているグループ（見出しの翻訳キー）。
  final Set<String> _open = {};

  Widget _group(
    String titleKey,
    IconData icon,
    Color accent,
    AppLanguage lang,
    List<Widget> children,
  ) {
    return Padding(
      key: ValueKey('settings-group-$titleKey'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: JiritsuExpandCard(
        title: titleKey.tr(lang),
        icon: icon,
        accent: accent,
        open: widget.startExpanded || _open.contains(titleKey),
        onToggle: () => setState(() {
          if (!_open.remove(titleKey)) _open.add(titleKey);
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final alwaysShowStartScreen = ref.watch(startScreenAlwaysShowProvider);
    final alwaysShowUsageScreen = ref.watch(usageScreenAlwaysShowProvider);

    return SubpageScaffold(
      appBar: OsmAppBar(title: Text('設定'.tr(lang))),
      body: ListView(
        children: [
          _SectionHeader(label: '言語'.tr(lang), icon: Icons.language_rounded),
          for (final language in AppLanguage.values)
            ListTile(
              leading: Text(
                language.flag,
                style: const TextStyle(fontSize: 22),
              ),
              title: Text(language.displayName),
              trailing: language == lang
                  ? Icon(Icons.check_circle_rounded, color: AppPalette.mintDark)
                  : null,
              selected: language == lang,
              selectedTileColor: AppPalette.mint.withValues(alpha: 0.12),
              onTap: () =>
                  ref.read(appLanguageProvider.notifier).setLanguage(language),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: Text(
              '言語_設定が正式'.tr(lang),
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.subpageTextMuted,
              ),
            ),
          ),

          const SizedBox(height: 8),
          _group('案内', Icons.flag_outlined, Colors.orange, lang, [
            SwitchListTile(
              secondary: const Icon(Icons.flag_outlined),
              title: Text('起動時にスタート画面を表示'.tr(lang)),
              subtitle: Text('案件があっても、起動時はスタート画面から始めます。'.tr(lang)),
              activeThumbColor: AppPalette.mintDark,
              value: alwaysShowStartScreen,
              onChanged: (value) =>
                  ref.read(startScreenAlwaysShowProvider.notifier).set(value),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.menu_book_outlined),
              title: Text('使い方画面'.tr(lang)),
              subtitle: Text('使い方画面_説明'.tr(lang)),
              activeThumbColor: AppPalette.mintDark,
              // スタートが OFF のときは使い方だけ ON にできない（不変条件）ので
              // 操作自体を無効にする — `usageScreenAlwaysShowProvider.notifier.set`
              // 側のガードは、それでも来た経路への保険。
              value: alwaysShowUsageScreen,
              onChanged: alwaysShowStartScreen
                  ? (value) => ref
                        .read(usageScreenAlwaysShowProvider.notifier)
                        .set(value)
                  : null,
            ),
          ]),
          _group('データ', Icons.storage_outlined, Colors.indigo, lang, [
            if (IcloudSyncService.isSupported)
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: Text('iCloud同期'.tr(lang)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const IcloudSyncSettingsScreen(),
                  ),
                ),
              ),
            ListTile(
              title: Text(
                'すべてのデータを削除'.tr(lang),
                style: TextStyle(color: Colors.red.shade800),
              ),
              subtitle: Text('設定_削除はプライバシーへ'.tr(lang)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Small caps-style label above a group of rows.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppPalette.subpageTextMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: AppPalette.subpageTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
