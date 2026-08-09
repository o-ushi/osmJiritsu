import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/subpage_scaffold.dart';
import '../services/icloud_sync_messages.dart';
import '../state/icloud_sync_notifier.dart';

/// iCloud同期の設定画面: オン/オフ、最終同期時刻、今すぐ同期、エラー表示。
class IcloudSyncSettingsScreen extends ConsumerStatefulWidget {
  const IcloudSyncSettingsScreen({super.key});

  @override
  ConsumerState<IcloudSyncSettingsScreen> createState() =>
      _IcloudSyncSettingsScreenState();
}

class _IcloudSyncSettingsScreenState
    extends ConsumerState<IcloudSyncSettingsScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(icloudSyncProvider.notifier).refreshAvailability();
    });
  }

  String _relativeTime(DateTime date, AppLanguage lang) {
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inDays >= 1) {
      return 'iCloud同期_相対時刻_日'.trFmt(lang, ['${diff.inDays}']);
    }
    if (diff.inHours >= 1) {
      return 'iCloud同期_相対時刻_時間'.trFmt(lang, ['${diff.inHours}']);
    }
    if (diff.inMinutes >= 1) {
      return 'iCloud同期_相対時刻_分'.trFmt(lang, ['${diff.inMinutes}']);
    }
    return 'iCloud同期_相対時刻_今'.tr(lang);
  }

  String _syncActionHint(AppLanguage lang, String? action) {
    switch (action) {
      case 'uploaded':
        return 'iCloud同期_アップロード完了'.tr(lang);
      case 'downloaded':
        return 'iCloud同期_ダウンロード完了'.tr(lang);
      default:
        return '';
    }
  }

  Future<void> _onSyncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    ref.read(icloudSyncProvider.notifier).clearError();

    final startedAt = DateTime.now();
    await ref.read(icloudSyncProvider.notifier).syncNow();

    // Keep the spinner visible briefly so the tap feels acknowledged.
    final elapsed = DateTime.now().difference(startedAt);
    const minFeedback = Duration(milliseconds: 400);
    if (elapsed < minFeedback) {
      await Future<void>.delayed(minFeedback - elapsed);
    }

    if (!mounted) return;
    setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final syncState = ref.watch(icloudSyncProvider);
    final lastSync = syncState.lastSyncDate;
    final showSpinner = _isSyncing || syncState.isWorking;

    return SubpageScaffold(
      appBar: OsmAppBar(title: Text('iCloud同期'.tr(lang))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.cloud_outlined),
            title: Text('iCloud同期'.tr(lang)),
            activeThumbColor: AppPalette.mintDark,
            value: syncState.isEnabled,
            onChanged: (value) =>
                ref.read(icloudSyncProvider.notifier).setEnabled(value),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'iCloud同期_有効化フッター'.tr(lang),
              style: TextStyle(fontSize: 13, color: AppPalette.subpageTextMuted),
            ),
          ),
          if (syncState.isEnabled) ...[
            if (!syncState.isICloudAvailable)
              ListTile(
                leading: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.orange,
                ),
                title: Text(
                  'iCloud同期_利用不可'.tr(lang),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ListTile(
              leading: Icon(
                Icons.schedule_rounded,
                color: AppPalette.subpageTextMuted,
              ),
              title: Text('iCloud同期_最終同期'.tr(lang)),
              trailing: Text(
                lastSync == null
                    ? 'iCloud同期_未同期'.tr(lang)
                    : _relativeTime(lastSync, lang),
                style: TextStyle(color: AppPalette.subpageTextMuted),
              ),
            ),
            ListTile(
              enabled: !_isSyncing,
              leading: Icon(
                Icons.sync_rounded,
                color: showSpinner ? AppPalette.subpageTextMuted : AppPalette.mintDark,
              ),
              title: Text('iCloud同期_今すぐ同期'.tr(lang)),
              trailing: showSpinner
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _onSyncNow,
            ),
            if (syncState.status == IcloudSyncStatus.error &&
                syncState.errorCode != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Text(
                  localizedIcloudSyncError(
                    lang,
                    syncState.errorCode,
                    detail: syncState.errorDetail,
                  ),
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              )
            else if (_syncActionHint(lang, syncState.lastSyncAction)
                .isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Text(
                  _syncActionHint(lang, syncState.lastSyncAction),
                  style: TextStyle(
                    color: AppPalette.strength,
                    fontSize: 13,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'iCloud同期_フッター'.tr(lang),
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.subpageTextMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
