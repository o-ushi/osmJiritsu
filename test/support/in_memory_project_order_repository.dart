import 'package:osm_jiritsu/history/data/project_order_repository.dart';

/// In-memory [ProjectOrderRepository] for tests — no Hive, no filesystem.
class InMemoryProjectOrderRepository implements ProjectOrderRepository {
  List<String>? _orderedIds;

  @override
  List<String>? load() => _orderedIds;

  @override
  void save(List<String> orderedIds) {
    _orderedIds = orderedIds;
  }

  @override
  Future<void> clear() async {
    _orderedIds = null;
  }
}
