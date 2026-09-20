import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/data/analysis_file_io.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/history/data/start_screen_settings_repository.dart';
import 'package:osm_jiritsu/icloud_sync/data/icloud_sync_settings_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';
import 'package:osm_jiritsu/privacy/screens/privacy_screen.dart';
import 'package:osm_jiritsu/settings/screens/settings_screen.dart';

import '../support/fake_analysis_file_io.dart';
import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_icloud_sync_settings_repository.dart';
import '../support/in_memory_project_order_repository.dart';
import '../support/in_memory_start_screen_settings_repository.dart';

Future<
    ({
      InMemoryStartScreenSettingsRepository startScreen,
      InMemoryAnalysisHistoryRepository history,
      InMemoryAppLanguageRepository language,
      FakeAnalysisFileIO fileIO,
    })> pumpScreen(
  WidgetTester tester, {
  bool alwaysShowStartScreen = false,
  bool alwaysShowUsageScreen = true,
  AppLanguage language = AppLanguage.japanese,
  List<Project> seed = const [],
}) async {
  // Tall enough that every row (including 使い方画面's switch) renders
  // without scrolling — the default test surface would otherwise leave
  // rows below it unbuilt and unfindable.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final startScreenSettingsRepository = InMemoryStartScreenSettingsRepository(
    alwaysShowStartScreen,
    alwaysShowUsageScreen,
  );
  final historyRepository = InMemoryAnalysisHistoryRepository();
  for (final project in seed) {
    await historyRepository.save(project);
  }
  final languageRepository = InMemoryAppLanguageRepository(language);
  final fileIO = FakeAnalysisFileIO();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLanguageRepositoryProvider.overrideWithValue(languageRepository),
        analysisHistoryRepositoryProvider.overrideWithValue(historyRepository),
        projectOrderRepositoryProvider.overrideWithValue(
          InMemoryProjectOrderRepository(),
        ),
        startScreenSettingsRepositoryProvider.overrideWithValue(
          startScreenSettingsRepository,
        ),
        icloudSyncSettingsRepositoryProvider.overrideWithValue(
          InMemoryIcloudSyncSettingsRepository(),
        ),
        analysisFileIOProvider.overrideWithValue(fileIO),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return (
    startScreen: startScreenSettingsRepository,
    history: historyRepository,
    language: languageRepository,
    fileIO: fileIO,
  );
}

void main() {
  testWidgets('lists 言語/削除リンク/プライバシーとデータ in that order', (tester) async {
    await pumpScreen(tester);

    final labels = ['言語', 'すべてのデータを削除', 'プライバシーとデータ'];
    for (final label in labels) {
      expect(find.text(label), findsWidgets);
    }

    final positions = [
      for (final label in labels) tester.getTopLeft(find.text(label).first).dy,
    ];
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i], greaterThan(positions[i - 1]));
    }
  });

  testWidgets(
    'tapping a language switches the app language immediately, without navigating away',
    (tester) async {
      await pumpScreen(tester);

      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(
              find.ancestor(
                of: find.text('日本語'),
                matching: find.byType(ListTile),
              ),
            )
            .selected,
        isTrue,
      );

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(
              find.ancestor(
                of: find.text('English'),
                matching: find.byType(ListTile),
              ),
            )
            .selected,
        isTrue,
      );
      expect(find.text('Privacy & Data'), findsWidgets);
    },
  );

  testWidgets(
    '起動時にスタート画面を表示 toggles and persists the setting',
    (tester) async {
      final repos = await pumpScreen(tester);

      expect(repos.startScreen.load(), isFalse);
      final toggle = find.widgetWithText(
        SwitchListTile,
        '起動時にスタート画面を表示',
      );
      expect(toggle, findsOneWidget);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(repos.startScreen.load(), isTrue);
    },
  );

  testWidgets('起動時にスタート画面を表示 reflects the persisted value on load', (
    tester,
  ) async {
    await pumpScreen(tester, alwaysShowStartScreen: true);

    final toggle = find.widgetWithText(SwitchListTile, '起動時にスタート画面を表示');
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
  });

  testWidgets(
    '使い方画面 toggles and persists when スタート is on, and is disabled when it is off',
    (tester) async {
      final repos = await pumpScreen(tester, alwaysShowStartScreen: true);

      final usageToggle = find.widgetWithText(SwitchListTile, '使い方画面');
      expect(tester.widget<SwitchListTile>(usageToggle).value, isTrue);
      expect(repos.startScreen.loadUsageAlwaysShow(), isTrue);

      await tester.tap(usageToggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(usageToggle).value, isFalse);
      expect(repos.startScreen.loadUsageAlwaysShow(), isFalse);
      // スタートは触っていない — 使い方だけを OFF にできる。
      expect(repos.startScreen.load(), isTrue);
    },
  );

  testWidgets('使い方画面 is disabled (and off) once スタート is off', (tester) async {
    final repos = await pumpScreen(tester, alwaysShowUsageScreen: false);

    final startToggle = find.widgetWithText(
      SwitchListTile,
      '起動時にスタート画面を表示',
    );
    final usageToggle = find.widgetWithText(SwitchListTile, '使い方画面');
    expect(tester.widget<SwitchListTile>(usageToggle).onChanged, isNull);
    expect(tester.widget<SwitchListTile>(usageToggle).value, isFalse);

    // Turning スタート on re-enables it, still following its persisted value.
    await tester.tap(startToggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(usageToggle).onChanged, isNotNull);

    await tester.tap(startToggle);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(usageToggle).onChanged, isNull);
    expect(tester.widget<SwitchListTile>(usageToggle).value, isFalse);
    expect(repos.startScreen.loadUsageAlwaysShow(), isFalse);
  });

  testWidgets(
    'すべてのデータを削除 links to PrivacyScreen (single wipe entry)',
    (tester) async {
      await pumpScreen(
        tester,
        alwaysShowStartScreen: true,
        seed: [
          Project(
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
            theme: '消える案件',
            matrix: const SwotMatrix(),
          ),
        ],
      );

      await tester.tap(find.text('すべてのデータを削除').first);
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(find.text('本当に初期化しますか？'), findsNothing);
    },
  );
}
