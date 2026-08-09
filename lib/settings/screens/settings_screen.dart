import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// osmJiritsu's settings entry point, grouped into labeled sections —
/// 言語 / スタートアップ画面 / データ / プライバシー.
///
/// Full data wipe lives only on [PrivacyScreen] (one destructive entry).
/// Language here is the canonical picker; the start-screen flag is a
/// shortcut to the same [appLanguageProvider].
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final alwaysShowStartScreen = ref.watch(startScreenAlwaysShowProvider);

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
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: AppPalette.mintDark,
                    )
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

          _SectionHeader(
            label: 'スタートアップ画面'.tr(lang),
            icon: Icons.flag_outlined,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.flag_outlined),
            title: Text('起動時にスタート画面を表示'.tr(lang)),
            subtitle: Text('案件があっても、起動時はスタート画面から始めます。'.tr(lang)),
            activeThumbColor: AppPalette.mintDark,
            value: alwaysShowStartScreen,
            onChanged: (value) =>
                ref.read(startScreenAlwaysShowProvider.notifier).set(value),
          ),

          _SectionHeader(label: 'データ'.tr(lang), icon: Icons.storage_outlined),
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
          ),

          _SectionHeader(
            label: 'プライバシー'.tr(lang),
            icon: Icons.privacy_tip_outlined,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('プライバシーとデータ'.tr(lang)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
          ),
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
