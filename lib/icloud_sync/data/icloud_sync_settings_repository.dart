import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../services/icloud_sync_payload.dart';

/// Persisted user preference + bookkeeping for iCloud KVS sync — same
/// shape/rationale as `StartScreenSettingsRepository`.
abstract class IcloudSyncSettingsRepository {
  bool isEnabled();
  void setEnabled(bool value);

  /// Last successful sync time (display).
  DateTime? lastSyncDate();

  /// Apple reference timestamp used for the native remote/local compare.
  double lastSyncReference();

  /// Records a successful sync (native side sets it immediately on success).
  Future<DateTime> recordSuccessfulSync({DateTime? when});

  Future<void> clear();
}

class HiveIcloudSyncSettingsRepository implements IcloudSyncSettingsRepository {
  // Shares `AppLanguageRepository`'s box — this is all "app settings", just
  // under its own keys.
  static const boxName = 'app_settings';
  static const _enabledKey = 'icloudSyncEnabled';
  static const _lastSyncMsKey = 'icloudSyncLastSyncMs';
  static const _lastSyncRefKey = 'icloudSyncLastSyncRef';

  final Box _box;

  const HiveIcloudSyncSettingsRepository(this._box);

  static Future<HiveIcloudSyncSettingsRepository> open() async {
    return HiveIcloudSyncSettingsRepository(await Hive.openBox(boxName));
  }

  @override
  bool isEnabled() => (_box.get(_enabledKey) as bool?) ?? true;

  @override
  void setEnabled(bool value) => _box.put(_enabledKey, value);

  @override
  DateTime? lastSyncDate() {
    final ms = _box.get(_lastSyncMsKey) as int?;
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);

    final ref = _box.get(_lastSyncRefKey) as double?;
    return ref == null ? null : appleReferenceToDate(ref);
  }

  @override
  double lastSyncReference() {
    final ref = _box.get(_lastSyncRefKey) as double?;
    if (ref != null) return ref;

    final ms = _box.get(_lastSyncMsKey) as int?;
    if (ms != null) {
      return dateToAppleReference(DateTime.fromMillisecondsSinceEpoch(ms));
    }
    return 0;
  }

  @override
  Future<DateTime> recordSuccessfulSync({DateTime? when}) async {
    final date = when ?? DateTime.now();
    await _box.put(_lastSyncMsKey, date.millisecondsSinceEpoch);
    await _box.put(_lastSyncRefKey, dateToAppleReference(date));
    return date;
  }

  @override
  Future<void> clear() async {
    await _box.delete(_enabledKey);
    await _box.delete(_lastSyncMsKey);
    await _box.delete(_lastSyncRefKey);
  }
}

/// Overridden in `main()` with a [HiveIcloudSyncSettingsRepository] once
/// Hive has been initialized; overridden in tests with an in-memory fake.
final icloudSyncSettingsRepositoryProvider =
    Provider<IcloudSyncSettingsRepository>((ref) {
      throw UnimplementedError(
        'icloudSyncSettingsRepositoryProvider must be overridden (see main.dart) before use.',
      );
    });
