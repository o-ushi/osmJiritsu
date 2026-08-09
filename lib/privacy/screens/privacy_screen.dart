import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../icloud_sync/services/icloud_sync_service.dart';
import '../../icloud_sync/state/icloud_sync_notifier.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../settings/app_reset.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/app_dialog.dart';
import '../../theme/widgets/subpage_scaffold.dart';

/// Disclosure · policy · on-device retention · full wipe.
///
/// JSON backup / import live only on the home/flow toolbar「データ」menu —
/// this screen keeps the destructive wipe as the single factory-reset
/// entry (Settings links here instead of duplicating the action).
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  static const privacyPolicyUrl =
      'https://docs.google.com/document/d/'
      '1eyrLvDL245Z_eBaAI1vTKqbCjraTcJdOMzBUn0Orrrs/edit?usp=sharing';
  static const googlePrivacyUrl = 'https://policies.google.com/privacy';
  static const applePrivacyUrl = 'https://www.apple.com/legal/privacy/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    return SubpageScaffold(
      appBar: OsmAppBar(title: Text('プライバシーとデータ'.tr(lang))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _SectionHeader('プライバシー_外部送信'.tr(lang)),
          _InfoCard(
            title: 'Google AIによる方策提案'.tr(lang),
            body: 'プライバシー_方策説明'.tr(lang),
          ),
          _InfoCard(
            title: 'Google AIによる最初の一歩提案'.tr(lang),
            body: 'プライバシー_最初の一歩説明'.tr(lang),
          ),

          const SizedBox(height: 8),
          _LinkTile(
            label: 'プライバシーポリシー'.tr(lang),
            onTap: () => _open(privacyPolicyUrl),
          ),
          _NoteText('プライバシー_ポリシー本文_詳細'.tr(lang)),

          _SectionHeader('関連ポリシー'.tr(lang)),
          _LinkTile(
            label: 'Google プライバシーポリシー'.tr(lang),
            onTap: () => _open(googlePrivacyUrl),
          ),
          _LinkTile(
            label: 'Apple プライバシーポリシー'.tr(lang),
            onTap: () => _open(applePrivacyUrl),
          ),
          _NoteText('プライバシー_関連ポリシー_詳細'.tr(lang)),

          _SectionHeader('プライバシー_端末保存'.tr(lang)),
          _InfoCard(body: 'プライバシー_保存詳細'.tr(lang)),
          _InfoCard(body: 'プライバシー_保持削除詳細'.tr(lang)),
          _NoteText('プライバシー_JSONバックアップ案内'.tr(lang)),

          if (IcloudSyncService.isSupported) ...[
            _SectionHeader('プライバシー_iCloud保存'.tr(lang)),
            _InfoCard(body: 'プライバシー_iCloud保存詳細'.tr(lang)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.cloud_off_outlined),
              label: Text('iCloud同期_クラウドコピーを削除'.tr(lang)),
              onPressed: () => _deleteCloudCopy(context, ref, lang),
            ),
          ],

          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(foregroundColor: Colors.red.shade800),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text('すべてのデータを削除'.tr(lang)),
            onPressed: () => _confirmDelete(context, ref, lang),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _deleteCloudCopy(
    BuildContext context,
    WidgetRef ref,
    AppLanguage lang,
  ) async {
    final confirmed = await showAppAlertDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('iCloud同期_クラウドコピーを削除しますか？'.tr(lang)),
        content: Text('iCloud同期_クラウドコピー削除確認'.tr(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'.tr(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('削除する'.tr(lang)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleted = await IcloudSyncService.deleteCloudCopy();
    if (!context.mounted) return;

    if (deleted) {
      ref.read(icloudSyncProvider.notifier).setEnabled(false);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'iCloud同期_クラウドコピー削除完了'.tr(lang)
              : 'iCloud同期_クラウドコピー削除失敗'.tr(lang),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLanguage lang,
  ) async {
    final confirmed = await showAppAlertDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('すべてのデータを削除'.tr(lang)),
        content: Text('プライバシー_削除確認'.tr(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'.tr(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('削除する'.tr(lang)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final doneMessage = '端末内のアプリデータを削除しました'.tr(lang);
    await ref.read(appResetProvider).resetToFactoryDefaults();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(doneMessage)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: AppPalette.subpageTextMuted,
      ),
    ),
  );
}

class _NoteText extends StatelessWidget {
  const _NoteText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.4,
        color: AppPalette.subpageTextMuted,
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({this.title, required this.body});

  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppPalette.subpageTextMuted.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.subpageText,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppPalette.subpageTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.open_in_new_rounded),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
