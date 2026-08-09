import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/models/project.dart';

/// In-memory [AnalysisHistoryRepository] for tests — no Hive, no
/// filesystem, so widget tests exercising `SwotMatrixScreen`'s or
/// `StrategyFlowScreen`'s auto-save don't need real persistence wired up.
class InMemoryAnalysisHistoryRepository implements AnalysisHistoryRepository {
  final Map<String, Project> _projects = {};

  /// Defaults to already-seeded so existing tests aren't surprised by the
  /// bundled sample 案件 appearing in `AnalysisHistoryNotifier.build()` —
  /// pass `false` to opt into exercising that seed path.
  bool _hasSeededSample;

  InMemoryAnalysisHistoryRepository([this._hasSeededSample = true]);

  @override
  Future<List<Project>> loadAll() async => _projects.values.toList();

  @override
  Future<void> save(Project project) async {
    _projects[project.id] = project;
  }

  @override
  Future<void> delete(String id) async {
    _projects.remove(id);
  }

  @override
  Future<void> clear() async {
    _projects.clear();
    _hasSeededSample = false;
  }

  @override
  Future<bool> hasSeededSampleProject() async => _hasSeededSample;

  @override
  Future<void> markSampleProjectSeeded() async {
    _hasSeededSample = true;
  }
}
