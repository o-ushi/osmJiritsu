import 'package:osm_jiritsu/icloud_sync/data/icloud_sync_settings_repository.dart';

/// In-memory [IcloudSyncSettingsRepository] for tests — no Hive box needed.
class InMemoryIcloudSyncSettingsRepository
    implements IcloudSyncSettingsRepository {
  bool _enabled;
  DateTime? _lastSyncDate;
  double _lastSyncReference;

  InMemoryIcloudSyncSettingsRepository([
    this._enabled = true,
    this._lastSyncDate,
    this._lastSyncReference = 0,
  ]);

  @override
  bool isEnabled() => _enabled;

  @override
  void setEnabled(bool value) => _enabled = value;

  @override
  DateTime? lastSyncDate() => _lastSyncDate;

  @override
  double lastSyncReference() => _lastSyncReference;

  @override
  Future<DateTime> recordSuccessfulSync({DateTime? when}) async {
    final date = when ?? DateTime.now();
    _lastSyncDate = date;
    _lastSyncReference = date
        .toUtc()
        .difference(DateTime.utc(2001))
        .inMicroseconds /
        1e6;
    return date;
  }

  @override
  Future<void> clear() async {
    _enabled = true;
    _lastSyncDate = null;
    _lastSyncReference = 0;
  }
}
