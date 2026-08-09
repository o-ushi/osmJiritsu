import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Where the 登録案件リスト's manual drag-to-reorder order is persisted.
///
/// Deliberately a separate small settings-style store (mirrors
/// `AppLanguageRepository`'s shape) rather than a field on [Project]
/// itself: display order is a list-level UI preference, not project data,
/// so it shouldn't need a `Project` schema/version bump, doesn't touch
/// each project's own `updatedAt`, and round-trips through JSON
/// export/import unaffected (a restored backup keeps whatever local order
/// was already saved, rather than importing someone else's).
abstract class ProjectOrderRepository {
  /// The last-saved display order, as project ids — `null` if the user has
  /// never reordered anything yet (so callers fall back to their own
  /// default sort, e.g. newest-first).
  List<String>? load();
  void save(List<String> orderedIds);
  Future<void> clear();
}

class HiveProjectOrderRepository implements ProjectOrderRepository {
  /// Shares the same box `AppLanguageRepository` uses — both are small,
  /// single-key app-level settings, not worth a dedicated box each.
  static const boxName = 'app_settings';
  static const _orderKey = 'project_order';

  final Box _box;

  const HiveProjectOrderRepository(this._box);

  static Future<HiveProjectOrderRepository> open() async {
    return HiveProjectOrderRepository(await Hive.openBox(boxName));
  }

  @override
  List<String>? load() {
    final raw = _box.get(_orderKey);
    if (raw is! List) return null;
    return raw.whereType<String>().toList();
  }

  @override
  void save(List<String> orderedIds) => _box.put(_orderKey, orderedIds);

  @override
  Future<void> clear() => _box.delete(_orderKey);
}

/// Overridden in `main()` with a [HiveProjectOrderRepository] once Hive has
/// been initialized; overridden in tests with an in-memory fake.
final projectOrderRepositoryProvider = Provider<ProjectOrderRepository>((
  ref,
) {
  throw UnimplementedError(
    'projectOrderRepositoryProvider must be overridden (see main.dart) before use.',
  );
});
