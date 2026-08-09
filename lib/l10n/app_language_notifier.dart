import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_language.dart';
import 'app_language_repository.dart';

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);

/// The app's current display language. Loaded once from
/// [appLanguageRepositoryProvider] at startup (defaulting to Vietnamese if
/// nothing has been saved yet), and persisted every time it changes.
class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    return ref.read(appLanguageRepositoryProvider).load() ??
        AppLanguage.vietnamese;
  }

  void setLanguage(AppLanguage language) {
    state = language;
    ref.read(appLanguageRepositoryProvider).save(language);
  }

  /// After a factory reset: apply the unset-store default (Vietnamese)
  /// without writing it back to Hive.
  void applyDefault() => state = AppLanguage.vietnamese;
}
