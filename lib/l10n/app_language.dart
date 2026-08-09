/// osmJiritsu's three supported display languages.
///
/// Ports the language dimension of osmWashabe's localization system
/// (`lib/notifiers/app_settings.dart` + `lib/l10n/app_strings.dart`), which
/// represented language as a raw `'ja'/'en'/'vi'` string throughout. Here
/// it's a typed enum instead — consistent with how the rest of osmJiritsu
/// models fixed choices (`SwotCategory`, `WizardStep`, ...) — while
/// [code] still carries the exact same wire-format string, e.g. for
/// persistence (see `AppLanguageRepository`).
///
/// Declaration order is English → Japanese → Vietnamese, matching
/// osmGradus's picker order (`appLanguages` in `lib/data/app_languages.dart`).
/// Settings and the start-screen language sheet both iterate
/// [AppLanguage.values], so this order is what users see.
enum AppLanguage {
  english,
  japanese,
  vietnamese;

  String get code {
    switch (this) {
      case AppLanguage.japanese:
        return 'ja';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.vietnamese:
        return 'vi';
    }
  }

  /// The flag shown in the language picker (see osmWashabe's
  /// `_languages` list in `settings_view.dart`).
  String get flag {
    switch (this) {
      case AppLanguage.japanese:
        return '🇯🇵';
      case AppLanguage.english:
        return '🇺🇸';
      case AppLanguage.vietnamese:
        return '🇻🇳';
    }
  }

  /// Each language's name written in itself (not translated), matching
  /// osmWashabe's picker labels.
  String get displayName {
    switch (this) {
      case AppLanguage.japanese:
        return '日本語';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.vietnamese:
        return 'Tiếng Việt';
    }
  }

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'en':
        return AppLanguage.english;
      case 'ja':
        return AppLanguage.japanese;
      default:
        return AppLanguage.vietnamese;
    }
  }
}
