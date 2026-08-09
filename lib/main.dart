import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'history/data/analysis_history_repository.dart';
import 'history/data/project_order_repository.dart';
import 'history/data/start_screen_settings_repository.dart';
import 'history/screens/history_list_screen.dart';
import 'icloud_sync/data/icloud_sync_settings_repository.dart';
import 'icloud_sync/widgets/icloud_sync_trigger.dart';
import 'l10n/app_language_repository.dart';
import 'theme/app_theme.dart';
import 'theme/widgets/dismiss_keyboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();

  final historyRepository = HiveAnalysisHistoryRepository();
  await historyRepository.init();
  final languageRepository = await HiveAppLanguageRepository.open();
  final projectOrderRepository = await HiveProjectOrderRepository.open();
  final startScreenSettingsRepository =
      await HiveStartScreenSettingsRepository.open();
  final icloudSyncSettingsRepository =
      await HiveIcloudSyncSettingsRepository.open();

  runApp(
    ProviderScope(
      overrides: [
        analysisHistoryRepositoryProvider.overrideWithValue(historyRepository),
        appLanguageRepositoryProvider.overrideWithValue(languageRepository),
        projectOrderRepositoryProvider.overrideWithValue(
          projectOrderRepository,
        ),
        startScreenSettingsRepositoryProvider.overrideWithValue(
          startScreenSettingsRepository,
        ),
        icloudSyncSettingsRepositoryProvider.overrideWithValue(
          icloudSyncSettingsRepository,
        ),
      ],
      child: const IcloudSyncTrigger(child: OsmJiritsuApp()),
    ),
  );
}

class OsmJiritsuApp extends StatelessWidget {
  const OsmJiritsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'osmJiritsu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) =>
          DismissKeyboard(child: child ?? const SizedBox.shrink()),
      home: const HistoryListScreen(),
    );
  }
}
