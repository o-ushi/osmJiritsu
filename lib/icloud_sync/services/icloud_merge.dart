import '../../models/project.dart';

/// Result of reconciling the local project library against a full remote
/// iCloud KVS snapshot. Pure data — applying it (repository writes + state
/// update) is the caller's job (see `AnalysisHistoryNotifier.applyIcloudMergePlan`).
class IcloudMergePlan {
  const IcloudMergePlan({
    this.toUpsertLocally = const [],
    this.toDeleteLocally = const [],
  });

  /// Remote projects that are new or newer (by [Project.updatedAt]) than
  /// the local copy.
  final List<Project> toUpsertLocally;

  /// Ids present locally but missing from the remote snapshot — deleted on
  /// another device since the last sync.
  final List<String> toDeleteLocally;
}

/// Reconciles [local] against a full remote snapshot ([remote]) with
/// last-write-wins on [Project.updatedAt]. The synced payload is always the
/// *entire* library (osmPod/osmSolver-style, not per-record CRDT), so a
/// local project absent from [remote] means it was deleted on another
/// device since the last sync.
IcloudMergePlan planFullRemoteSnapshot({
  required List<Project> local,
  required List<Project> remote,
}) {
  final localById = {for (final p in local) p.id: p};
  final remoteIds = {for (final p in remote) p.id};

  final toUpsertLocally = <Project>[];
  for (final r in remote) {
    final l = localById[r.id];
    if (l == null || r.updatedAt.isAfter(l.updatedAt)) {
      toUpsertLocally.add(r);
    }
  }

  final toDeleteLocally = local
      .map((p) => p.id)
      .where((id) => !remoteIds.contains(id))
      .toList();

  return IcloudMergePlan(
    toUpsertLocally: toUpsertLocally,
    toDeleteLocally: toDeleteLocally,
  );
}
