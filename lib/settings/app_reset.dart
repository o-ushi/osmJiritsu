import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../history/data/analysis_file_io.dart';
import '../history/data/project_order_repository.dart';
import '../history/data/start_screen_settings_repository.dart';
import '../history/state/analysis_history_notifier.dart';
import '../history/state/start_screen_settings_notifier.dart';
import '../icloud_sync/data/icloud_sync_settings_repository.dart';
import '../icloud_sync/state/icloud_sync_notifier.dart';
import '../l10n/app_language_notifier.dart';
import '../l10n/app_language_repository.dart';
import '../wizard/state/wizard_notifier.dart';

/// 設定画面の「すべてのデータを初期化」。osmGradusの`AppReset`に相当し、
/// 端末内に保存された分析履歴・設定・一時ファイルをすべて削除して
/// 初めてインストールした状態に戻す。
final appResetProvider = Provider<AppReset>((ref) => AppReset(ref));

class AppReset {
  AppReset(this._ref);

  final Ref _ref;

  Future<void> resetToFactoryDefaults() async {
    await _ref.read(analysisHistoryProvider.notifier).clear();
    await _ref.read(projectOrderRepositoryProvider).clear();
    await _ref.read(startScreenSettingsRepositoryProvider).clear();
    await _ref.read(appLanguageRepositoryProvider).clear();
    await _ref.read(icloudSyncSettingsRepositoryProvider).clear();
    await _ref.read(analysisFileIOProvider).deleteTemporaryExports();
    _ref.read(wizardProvider.notifier).reset();

    // Persistence is empty; refresh in-memory providers that still hold
    // pre-clear values so the running UI matches factory defaults.
    _ref.read(appLanguageProvider.notifier).applyDefault();
    _ref.read(startScreenAlwaysShowProvider.notifier).applyDefault();
    _ref.read(startScreenDismissedProvider.notifier).show();
    _ref.read(usageScreenAlwaysShowProvider.notifier).applyDefault();
    _ref.read(usageScreenSessionShowProvider.notifier).set(false);
    _ref.invalidate(icloudSyncProvider);
  }
}
