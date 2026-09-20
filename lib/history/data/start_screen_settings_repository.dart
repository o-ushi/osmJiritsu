import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Where the「起動時にスタート画面を表示」and「使い方画面を表示」settings are
/// persisted — same shape/rationale as `AppLanguageRepository`: Hive is
/// synchronous once the box is open, so no method here needs to be async
/// except opening it.
abstract class StartScreenSettingsRepository {
  bool load();
  void save(bool alwaysShowAtLaunch);

  /// 「はじめる」の後に使い方画面を出すか。既定 `true`（[HiveStartScreenSettingsRepository]
  /// 参照）。[load] が `false`（起動時にスタート画面を表示 OFF）のときにこれが
  /// `true` のまま残ることはない — スタートを false にする setter 側が一緒に
  /// false へ揃える（[StartScreenAlwaysShowNotifier.set] 参照）。
  bool loadUsageAlwaysShow();
  void saveUsageAlwaysShow(bool alwaysShowAtLaunch);
  Future<void> clear();
}

class HiveStartScreenSettingsRepository
    implements StartScreenSettingsRepository {
  // Shares `AppLanguageRepository`'s box — this is all "app settings",
  // just under its own key.
  static const boxName = 'app_settings';
  static const _alwaysShowAtLaunchKey = 'startScreenAlwaysShowAtLaunch';
  static const _usageAlwaysShowAtLaunchKey = 'usageScreenAlwaysShowAtLaunch';

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
  // Default `true` matches osmGradus's `showUsageScreen`.
  bool loadUsageAlwaysShow() =>
      (_box.get(_usageAlwaysShowAtLaunchKey) as bool?) ?? true;

  @override
  void saveUsageAlwaysShow(bool alwaysShowAtLaunch) =>
      _box.put(_usageAlwaysShowAtLaunchKey, alwaysShowAtLaunch);

  @override
  Future<void> clear() => Future.wait([
    _box.delete(_alwaysShowAtLaunchKey),
    _box.delete(_usageAlwaysShowAtLaunchKey),
  ]);
}

/// Overridden in `main()` with a [HiveStartScreenSettingsRepository] once
/// Hive has been initialized; overridden in tests with an in-memory fake.
final startScreenSettingsRepositoryProvider =
    Provider<StartScreenSettingsRepository>((ref) {
      throw UnimplementedError(
        'startScreenSettingsRepositoryProvider must be overridden (see main.dart) before use.',
      );
    });
