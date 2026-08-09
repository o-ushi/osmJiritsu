import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Where the「起動時にスタート画面を表示」setting is persisted — same
/// shape/rationale as `AppLanguageRepository`: Hive is synchronous once the
/// box is open, so no method here needs to be async except opening it.
abstract class StartScreenSettingsRepository {
  bool load();
  void save(bool alwaysShowAtLaunch);
  Future<void> clear();
}

class HiveStartScreenSettingsRepository
    implements StartScreenSettingsRepository {
  // Shares `AppLanguageRepository`'s box — this is all "app settings",
  // just under its own key.
  static const boxName = 'app_settings';
  static const _alwaysShowAtLaunchKey = 'startScreenAlwaysShowAtLaunch';

  final Box _box;

  const HiveStartScreenSettingsRepository(this._box);

  static Future<HiveStartScreenSettingsRepository> open() async {
    return HiveStartScreenSettingsRepository(await Hive.openBox(boxName));
  }

  @override
  // Default `true` matches osmGradus's `showStartupScreen` — first launch
  // (and factory reset) show the start screen until the user opts out.
  bool load() => (_box.get(_alwaysShowAtLaunchKey) as bool?) ?? true;

  @override
  void save(bool alwaysShowAtLaunch) =>
      _box.put(_alwaysShowAtLaunchKey, alwaysShowAtLaunch);

  @override
  Future<void> clear() => _box.delete(_alwaysShowAtLaunchKey);
}

/// Overridden in `main()` with a [HiveStartScreenSettingsRepository] once
/// Hive has been initialized; overridden in tests with an in-memory fake.
final startScreenSettingsRepositoryProvider =
    Provider<StartScreenSettingsRepository>((ref) {
      throw UnimplementedError(
        'startScreenSettingsRepositoryProvider must be overridden (see main.dart) before use.',
      );
    });
