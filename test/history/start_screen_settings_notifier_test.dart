// Provider-level tests for the「起動時にスタート画面を表示」/「使い方画面」
// invariant: usageScreenAlwaysShow == true is only ever allowed while
// startScreenAlwaysShow == true. See start_screen_settings_notifier.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/data/start_screen_settings_repository.dart';
import 'package:osm_jiritsu/history/state/start_screen_settings_notifier.dart';

import '../support/in_memory_start_screen_settings_repository.dart';

ProviderContainer _container(StartScreenSettingsRepository repository) {
  final container = ProviderContainer(
    overrides: [
      startScreenSettingsRepositoryProvider.overrideWithValue(repository),
    ],
  );
  return container;
}

void main() {
  test('両方 true のときスタートを OFF にすると usage も false になる', () {
    final repository = InMemoryStartScreenSettingsRepository(true, true);
    final container = _container(repository);
    addTearDown(container.dispose);

    container.read(startScreenAlwaysShowProvider.notifier).set(false);

    expect(container.read(startScreenAlwaysShowProvider), isFalse);
    expect(container.read(usageScreenAlwaysShowProvider), isFalse);
    expect(repository.load(), isFalse);
    expect(repository.loadUsageAlwaysShow(), isFalse);
  });

  test('スタート OFF のとき usage を true にしようとしても false のまま', () {
    final repository = InMemoryStartScreenSettingsRepository(false, false);
    final container = _container(repository);
    addTearDown(container.dispose);

    container.read(usageScreenAlwaysShowProvider.notifier).set(true);

    expect(container.read(usageScreenAlwaysShowProvider), isFalse);
    expect(repository.loadUsageAlwaysShow(), isFalse);
  });

  test('usage が false のあとスタートを再び ON にしても usage は false のまま', () {
    final repository = InMemoryStartScreenSettingsRepository(true, true);
    final container = _container(repository);
    addTearDown(container.dispose);

    container.read(startScreenAlwaysShowProvider.notifier).set(false);
    expect(container.read(usageScreenAlwaysShowProvider), isFalse);

    container.read(startScreenAlwaysShowProvider.notifier).set(true);

    expect(container.read(startScreenAlwaysShowProvider), isTrue);
    expect(container.read(usageScreenAlwaysShowProvider), isFalse);
    expect(repository.loadUsageAlwaysShow(), isFalse);
  });

  test('スタート ON のまま使い方だけ OFF にしてもスタートは true のまま', () {
    final repository = InMemoryStartScreenSettingsRepository(true, true);
    final container = _container(repository);
    addTearDown(container.dispose);

    container.read(usageScreenAlwaysShowProvider.notifier).set(false);

    expect(container.read(startScreenAlwaysShowProvider), isTrue);
    expect(container.read(usageScreenAlwaysShowProvider), isFalse);
    expect(repository.load(), isTrue);
  });

  test('未設定なら usage は true で、保存後も保持される', () {
    final repository = InMemoryStartScreenSettingsRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(container.read(usageScreenAlwaysShowProvider), isTrue);

    container.read(usageScreenAlwaysShowProvider.notifier).set(false);
    container.read(usageScreenAlwaysShowProvider.notifier).set(true);

    expect(container.read(usageScreenAlwaysShowProvider), isTrue);
    expect(repository.loadUsageAlwaysShow(), isTrue);
  });
}
