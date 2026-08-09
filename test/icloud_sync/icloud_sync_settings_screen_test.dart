import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/icloud_sync/data/icloud_sync_settings_repository.dart';
import 'package:osm_jiritsu/icloud_sync/screens/icloud_sync_settings_screen.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';

import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_icloud_sync_settings_repository.dart';

Future<InMemoryIcloudSyncSettingsRepository> pumpScreen(
  WidgetTester tester, {
  bool enabled = true,
}) async {
  final repository = InMemoryIcloudSyncSettingsRepository(enabled);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        icloudSyncSettingsRepositoryProvider.overrideWithValue(repository),
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(AppLanguage.japanese),
        ),
      ],
      child: const MaterialApp(home: IcloudSyncSettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('shows the enable switch reflecting the persisted value', (
    tester,
  ) async {
    await pumpScreen(tester, enabled: false);

    final toggle = find.byType(SwitchListTile);
    expect(toggle, findsOneWidget);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });

  testWidgets('toggling the switch persists the new value', (tester) async {
    final repository = await pumpScreen(tester, enabled: false);

    expect(repository.isEnabled(), isFalse);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(repository.isEnabled(), isTrue);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
  });

  testWidgets(
    'when disabled, only the switch and its footer are shown — no sync row',
    (tester) async {
      await pumpScreen(tester, enabled: false);

      expect(find.text('今すぐ同期'), findsNothing);
      expect(find.text('最終同期'), findsNothing);
    },
  );

  testWidgets(
    'when enabled, the sync-now row and last-sync row appear',
    (tester) async {
      await pumpScreen(tester, enabled: true);

      expect(find.text('今すぐ同期'), findsOneWidget);
      expect(find.text('最終同期'), findsOneWidget);
      expect(find.text('未同期'), findsOneWidget);
    },
  );
}
