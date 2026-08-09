import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app_language.dart';

/// Where the user's chosen [AppLanguage] is persisted.
///
/// Hive access is synchronous once a box is open (only `Hive.openBox`
/// itself is async), so unlike `AnalysisHistoryRepository` this interface
/// doesn't need `Future`s — matching how cheap a single string read/write
/// actually is.
abstract class AppLanguageRepository {
  AppLanguage? load();
  void save(AppLanguage language);
  Future<void> clear();
}

class HiveAppLanguageRepository implements AppLanguageRepository {
  static const boxName = 'app_settings';
  static const _languageKey = 'language';

  final Box _box;

  const HiveAppLanguageRepository(this._box);

  static Future<HiveAppLanguageRepository> open() async {
    return HiveAppLanguageRepository(await Hive.openBox(boxName));
  }

  @override
  AppLanguage? load() {
    final code = _box.get(_languageKey);
    return code is String ? AppLanguage.fromCode(code) : null;
  }

  @override
  void save(AppLanguage language) => _box.put(_languageKey, language.code);

  @override
  Future<void> clear() => _box.delete(_languageKey);
}

/// Overridden in `main()` with a [HiveAppLanguageRepository] once Hive has
/// been initialized; overridden in tests with an in-memory fake.
final appLanguageRepositoryProvider = Provider<AppLanguageRepository>((ref) {
  throw UnimplementedError(
    'appLanguageRepositoryProvider must be overridden (see main.dart) before use.',
  );
});
