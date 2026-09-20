import 'package:osm_jiritsu/history/data/start_screen_settings_repository.dart';

/// In-memory [StartScreenSettingsRepository] for tests — no Hive box needed.
class InMemoryStartScreenSettingsRepository
    implements StartScreenSettingsRepository {
  bool _stored;
  bool _storedUsage;

  InMemoryStartScreenSettingsRepository([
    this._stored = true,
    this._storedUsage = true,
  ]);

  @override
  bool load() => _stored;

  @override
  void save(bool alwaysShowAtLaunch) => _stored = alwaysShowAtLaunch;

  @override
  bool loadUsageAlwaysShow() => _storedUsage;

  @override
  void saveUsageAlwaysShow(bool alwaysShowAtLaunch) =>
      _storedUsage = alwaysShowAtLaunch;

  @override
  Future<void> clear() async {
    _stored = true;
    _storedUsage = true;
  }
}
