import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../icloud_sync/services/icloud_merge.dart';
import '../../models/project.dart';
import '../data/analysis_history_repository.dart';
import '../data/project_order_repository.dart';
import '../data/sample_project.dart';
import '../services/analysis_export_service.dart';

final analysisHistoryProvider =
    AsyncNotifierProvider<AnalysisHistoryNotifier, List<Project>>(
      AnalysisHistoryNotifier.new,
    );

/// Owns the saved-project history end to end: loading it from
/// [analysisHistoryRepositoryProvider] on startup, upserting a project as
/// the wizard/matrix/action-plan screens progress, merging imported
/// projects from a backup file, and persisting the 登録案件リスト's manual
/// drag-to-reorder order.
///
/// Projects are exposed in [projectOrderRepositoryProvider]'s saved order
/// once the user has reordered anything; any project not yet in that saved
/// order (new, or from before reordering was ever used) is appended
/// newest-first by [Project.updatedAt] — see [_sorted].
class AnalysisHistoryNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final repo = ref.read(analysisHistoryRepositoryProvider);
    var projects = await repo.loadAll();

    if (!await repo.hasSeededSampleProject()) {
      final existingIds = {for (final p in projects) p.id};
      for (final sample in await loadSampleProjects()) {
        if (existingIds.contains(sample.id)) continue;
        await repo.save(sample);
      }
      await repo.markSampleProjectSeeded();
      projects = await repo.loadAll();
    }

    return _sorted(projects);
  }

  /// Creates or updates a project. If a project with the same [id][
  /// Project.id] already exists, its original `createdAt` is preserved
  /// (only `updatedAt` and the content fields change) — callers always
  /// pass a freshly-stamped [project] and let this decide whether that's
  /// really a "first save" or just an edit.
  ///
  /// Also refuses to replace a non-empty SWOT / situation-notes wall with
  /// an empty one for the same id (defense in depth on top of
  /// [HiveAnalysisHistoryRepository]'s own disk-level guard).
  Future<void> saveOrUpdate(Project project) async {
    final current = await future;
    final existing = _findById(current, project.id);
    var toSave = existing != null
        ? project.copyWith(createdAt: existing.createdAt)
        : project;

    if (existing != null) {
      if (toSave.matrix.isEmpty && existing.matrix.isNotEmpty) {
        toSave = toSave.copyWith(matrix: existing.matrix);
      }
      if (toSave.situationNotes.isEmpty &&
          existing.situationNotes.isNotEmpty) {
        toSave = toSave.copyWith(situationNotes: existing.situationNotes);
      }
    }

    await ref.read(analysisHistoryRepositoryProvider).save(toSave);
    state = AsyncData(_sorted(_upsert(current, toSave)));
  }

  Future<void> delete(String id) async {
    await ref.read(analysisHistoryRepositoryProvider).delete(id);
    final current = state.value ?? await future;
    state = AsyncData(current.where((p) => p.id != id).toList());
  }

  Future<void> clear() async {
    // Wait for any in-flight initial build to settle first — otherwise it
    // can complete after this method returns and overwrite the just-cleared
    // state with whatever it loaded (e.g. re-seeding the sample project).
    await future;
    await ref.read(analysisHistoryRepositoryProvider).clear();
    state = const AsyncData([]);
  }

  /// Merges [imported] projects into local history. For any id that
  /// already exists locally, the newer `updatedAt` wins — so restoring an
  /// old backup can never silently overwrite more recent local edits.
  /// Returns how many projects were actually written (added or updated).
  Future<int> importSessions(List<Project> imported) =>
      importBackup(AnalysisBackup(projects: imported));

  /// Merges every project in [backup] and, when [AnalysisBackup.projectOrder]
  /// is present, restores the home-list display order too.
  Future<int> importBackup(AnalysisBackup backup) async {
    var current = await future;
    final repo = ref.read(analysisHistoryRepositoryProvider);
    var writtenCount = 0;

    for (final project in backup.projects) {
      final existing = _findById(current, project.id);
      if (existing == null || project.updatedAt.isAfter(existing.updatedAt)) {
        await repo.save(project);
        current = _upsert(current, project);
        writtenCount++;
      }
    }

    if (backup.projectOrder != null && backup.projectOrder!.isNotEmpty) {
      current = _applyOrder(current, backup.projectOrder!);
      ref.read(projectOrderRepositoryProvider).save(
        current.map((p) => p.id).toList(),
      );
    }

    state = AsyncData(_sorted(current));
    return writtenCount;
  }

  List<Project> _applyOrder(List<Project> projects, List<String> orderedIds) {
    final byId = {for (final p in projects) p.id: p};
    final ordered = <Project>[];
    for (final id in orderedIds) {
      final project = byId.remove(id);
      if (project != null) ordered.add(project);
    }
    final remainder = [...byId.values]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    ordered.addAll(remainder);
    return ordered;
  }

  /// Persists a new manual display order (drag-to-reorder in
  /// `HistoryListScreen`) and reflects it in state immediately.
  /// [orderedIds] should be every currently-listed project's id, in its
  /// new order — anything missing just falls back to [_sorted]'s
  /// newest-first default on the next load, so a partial list is never
  /// destructive.
  Future<void> reorder(List<String> orderedIds) async {
    final current = state.value ?? await future;
    ref.read(projectOrderRepositoryProvider).save(orderedIds);
    state = AsyncData(_sorted(current));
  }

  /// Applies a merge plan produced by `planFullRemoteSnapshot` (iCloud
  /// sync): writes each upsert/delete to the repository, then reflects the
  /// result in state without disturbing the current display order.
  Future<void> applyIcloudMergePlan(IcloudMergePlan plan) async {
    if (plan.toUpsertLocally.isEmpty && plan.toDeleteLocally.isEmpty) return;

    final repo = ref.read(analysisHistoryRepositoryProvider);
    for (final project in plan.toUpsertLocally) {
      await repo.save(project);
    }
    for (final id in plan.toDeleteLocally) {
      await repo.delete(id);
    }

    final current = state.value ?? await future;
    final byId = {for (final p in current) p.id: p};
    for (final project in plan.toUpsertLocally) {
      byId[project.id] = project;
    }
    for (final id in plan.toDeleteLocally) {
      byId.remove(id);
    }
    state = AsyncData(_sorted(byId.values.toList()));
  }

  Project? _findById(List<Project> projects, String id) {
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  List<Project> _upsert(List<Project> projects, Project project) {
    return [
      for (final p in projects)
        if (p.id != project.id) p,
      project,
    ];
  }

  /// Orders [projects] by the saved manual order (see
  /// [ProjectOrderRepository.load]) when one exists; any project not in
  /// that saved order — new, imported, or from before reordering was ever
  /// used — is appended after it, newest-first by [Project.updatedAt].
  /// Falls back to newest-first entirely when nothing's ever been
  /// reordered.
  List<Project> _sorted(List<Project> projects) {
    List<Project> newestFirst(List<Project> list) {
      final copy = [...list];
      copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return copy;
    }

    final savedOrder = ref.read(projectOrderRepositoryProvider).load();
    if (savedOrder == null || savedOrder.isEmpty) {
      return newestFirst(projects);
    }

    final byId = {for (final p in projects) p.id: p};
    final ordered = <Project>[];
    for (final id in savedOrder) {
      final project = byId.remove(id);
      if (project != null) ordered.add(project);
    }
    ordered.addAll(newestFirst(byId.values.toList()));
    return ordered;
  }
}
