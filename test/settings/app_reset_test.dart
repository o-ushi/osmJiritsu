import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/data/analysis_file_io.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/history/data/start_screen_settings_repository.dart';
import 'package:osm_jiritsu/history/state/analysis_history_notifier.dart';
import 'package:osm_jiritsu/history/state/start_screen_settings_notifier.dart';
import 'package:osm_jiritsu/icloud_sync/data/icloud_sync_settings_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_notifier.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';
import 'package:osm_jiritsu/settings/app_reset.dart';
import 'package:osm_jiritsu/wizard/state/wizard_notifier.dart';

import '../support/fake_analysis_file_io.dart';
import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_icloud_sync_settings_repository.dart';
import '../support/in_memory_project_order_repository.dart';
import '../support/in_memory_start_screen_settings_repository.dart';

void main() {
  test('全データ初期化で履歴・並び順・設定・一時ファイルを削除する', () async {
    final history = InMemoryAnalysisHistoryRepository();
    await history.save(
      Project(
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        theme: '残すべきでない案件',
        matrix: const SwotMatrix(),
      ),
    );
    final order = InMemoryProjectOrderRepository()
      ..save(['a', 'b']);
    final language = InMemoryAppLanguageRepository(AppLanguage.japanese);
    final startScreen = InMemoryStartScreenSettingsRepository(true);
    final icloudSync = InMemoryIcloudSyncSettingsRepository();
    final fileIO = FakeAnalysisFileIO();

    final container = ProviderContainer(
      overrides: [
        analysisHistoryRepositoryProvider.overrideWithValue(history),
        projectOrderRepositoryProvider.overrideWithValue(order),
        appLanguageRepositoryProvider.overrideWithValue(language),
        startScreenSettingsRepositoryProvider.overrideWithValue(startScreen),
        icloudSyncSettingsRepositoryProvider.overrideWithValue(icloudSync),
        analysisFileIOProvider.overrideWithValue(fileIO),
      ],
    );
    addTearDown(container.dispose);

    // Materialize providers so AppReset refreshes live state, not just stores.
    await container.read(analysisHistoryProvider.future);
    expect(container.read(appLanguageProvider), AppLanguage.japanese);
    expect(container.read(startScreenAlwaysShowProvider), isTrue);

    container.read(wizardProvider.notifier).setTheme('途中の下書き');
    expect(container.read(wizardProvider).theme, '途中の下書き');

    await container.read(appResetProvider).resetToFactoryDefaults();

    expect(await history.loadAll(), isEmpty);
    expect(order.load(), isNull);
    expect(language.load(), isNull);
    expect(startScreen.load(), isTrue);
    expect(fileIO.temporaryExportsDeleted, isTrue);

    expect(container.read(analysisHistoryProvider).value, isEmpty);
    expect(container.read(appLanguageProvider), AppLanguage.vietnamese);
    expect(container.read(startScreenAlwaysShowProvider), isTrue);
    expect(container.read(wizardProvider).theme, isEmpty);
  });
}
