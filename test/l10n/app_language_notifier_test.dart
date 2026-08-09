import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_notifier.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';

import '../support/in_memory_app_language_repository.dart';

void main() {
  test('defaults to Vietnamese when the repository has nothing saved', () {
    final container = ProviderContainer(
      overrides: [
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appLanguageProvider), AppLanguage.vietnamese);
  });

  test('loads whatever language was already saved', () {
    final container = ProviderContainer(
      overrides: [
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(AppLanguage.vietnamese),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appLanguageProvider), AppLanguage.vietnamese);
  });

  test('setLanguage updates state and persists to the repository', () {
    final repository = InMemoryAppLanguageRepository();
    final container = ProviderContainer(
      overrides: [appLanguageRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.english);

    expect(container.read(appLanguageProvider), AppLanguage.english);
    expect(repository.load(), AppLanguage.english);
  });
}
