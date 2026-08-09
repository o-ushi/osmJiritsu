import 'package:osm_jiritsu/history/data/start_screen_settings_repository.dart';

/// In-memory [StartScreenSettingsRepository] for tests — no Hive box needed.
class InMemoryStartScreenSettingsRepository
    implements StartScreenSettingsRepository {
  bool _stored;

  InMemoryStartScreenSettingsRepository([this._stored = true]);

  @override
  bool load() => _stored;

  @override
  void save(bool alwaysShowAtLaunch) => _stored = alwaysShowAtLaunch;

  @override
  Future<void> clear() async {
    _stored = true;
  }
}
