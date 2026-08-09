import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../models/project.dart';
import '../../models/situation_note.dart';
import '../../models/swot_matrix.dart';

/// Where [Project]s actually live on disk.
///
/// [AnalysisHistoryNotifier] depends only on this interface, never on Hive
/// directly, so tests can swap in an in-memory fake (see
/// `test/support/in_memory_analysis_history_repository.dart`) instead of
/// touching the filesystem.
abstract class AnalysisHistoryRepository {
  Future<List<Project>> loadAll();
  Future<void> save(Project project);
  Future<void> delete(String id);
  Future<void> clear();

  /// Whether the bundled 例題 (sample) 案件 has already been seeded once —
  /// gates the first-install-only seed in `AnalysisHistoryNotifier.build()`
  /// so a user who deletes the sample project never has it silently
  /// reappear on a later launch. [clear] resets this back to false, so a
  /// factory reset re-seeds it on the next launch, matching "restore to
  /// first-install state".
  Future<bool> hasSeededSampleProject();
  Future<void> markSampleProjectSeeded();
}

/// Hive-backed [AnalysisHistoryRepository].
///
/// Projects are stored as plain `Map<String, dynamic>` (via
/// [Project.toJson]/[Project.fromJson]) rather than a custom
/// `TypeAdapter` — Hive's binary codec already natively supports
/// Map/List/String/num/bool, so the JSON shape doubles as the storage
/// shape with zero codegen.
///
/// A second box ([backupBoxName]) keeps the last non-empty SWOT snapshot
/// per project so a bad save (or a past decode bug that emptied the
/// matrix in memory and then `put` it back) can be auto-healed on the
/// next [loadAll].
class HiveAnalysisHistoryRepository implements AnalysisHistoryRepository {
  static const boxName = 'projects';
  static const backupBoxName = 'projects_swot_backup';

  // Shares the same box the other small settings repositories use (see
  // e.g. `StartScreenSettingsRepository`) — this is just one more
  // app-level flag, not worth a dedicated box.
  static const _settingsBoxName = 'app_settings';
  static const _hasSeededSampleKey = 'hasSeededSampleProject';

  Box<Map>? _box;
  Box<Map>? _backupBox;
  Box? _settingsBox;

  /// Must be called once (after `Hive.initFlutter()`) before any other
  /// method — see `main()`.
  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
    _backupBox = await Hive.openBox<Map>(backupBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  @override
  Future<List<Project>> loadAll() async {
    final box = _requireBox();
    final projects = <Project>[];
    for (final raw in box.values) {
      try {
        var project = Project.fromJson(Map<String, dynamic>.from(raw));
        project = await _restoreMatrixFromBackupIfNeeded(project);
        projects.add(project);
      } on FormatException {
        // Skip a single corrupt record rather than losing the whole
        // history to one bad entry.
      }
    }
    return projects;
  }

  @override
  Future<void> save(Project project) async {
    final box = _requireBox();
    final toWrite = _protectAgainstMatrixWipe(project, box.get(project.id));
    await box.put(toWrite.id, toWrite.toJson());
    await _snapshotMatrixBackup(toWrite);
  }

  @override
  Future<void> delete(String id) async {
    await _requireBox().delete(id);
    await _requireBackupBox().delete(id);
  }

  @override
  Future<void> clear() async {
    await _requireBox().clear();
    await _requireBackupBox().clear();
    await _requireSettingsBox().delete(_hasSeededSampleKey);
  }

  @override
  Future<bool> hasSeededSampleProject() async =>
      (_requireSettingsBox().get(_hasSeededSampleKey) as bool?) ?? false;

  @override
  Future<void> markSampleProjectSeeded() async =>
      _requireSettingsBox().put(_hasSeededSampleKey, true);

  /// If [incoming] would write an empty matrix over a still-populated one
  /// on disk, keep the disk matrix (and situation notes when the same
  /// pattern applies). Covers wizard drafts and any leftover in-memory
  /// empties from before the Hive decode fix.
  Project _protectAgainstMatrixWipe(Project incoming, Map? existingRaw) {
    if (existingRaw == null) return incoming;
    Project existing;
    try {
      existing = Project.fromJson(Map<String, dynamic>.from(existingRaw));
    } on FormatException {
      return incoming;
    }

    var protected = incoming;
    if (incoming.matrix.isEmpty && existing.matrix.isNotEmpty) {
      protected = protected.copyWith(matrix: existing.matrix);
    }
    if (incoming.situationNotes.isEmpty &&
        existing.situationNotes.isNotEmpty) {
      protected = protected.copyWith(situationNotes: existing.situationNotes);
    }
    return protected;
  }

  Future<void> _snapshotMatrixBackup(Project project) async {
    if (project.matrix.isEmpty) return;
    await _requireBackupBox().put(project.id, {
      'id': project.id,
      'savedAt': DateTime.now().toIso8601String(),
      'matrix': project.matrix.toJson(),
      'situationNotes':
          project.situationNotes.map((n) => n.toJson()).toList(),
    });
  }

  /// When the live record has an empty matrix but a backup snapshot still
  /// has items, restore and rewrite the live box — heals projects that
  /// were emptied by the old `whereType<Map<String, dynamic>>` decode bug
  /// after a subsequent dashboard save.
  Future<Project> _restoreMatrixFromBackupIfNeeded(Project project) async {
    if (project.matrix.isNotEmpty) {
      await _snapshotMatrixBackup(project);
      return project;
    }

    final raw = _requireBackupBox().get(project.id);
    if (raw == null) return project;

    final backup = Map<String, dynamic>.from(raw);
    final rawMatrix = backup['matrix'];
    if (rawMatrix is! Map) return project;

    final matrix = SwotMatrix.fromJson(Map<String, dynamic>.from(rawMatrix));
    if (matrix.isEmpty) return project;

    var restored = project.copyWith(matrix: matrix);
    final rawNotes = backup['situationNotes'];
    if (project.situationNotes.isEmpty && rawNotes is List) {
      final notes = <SituationNote>[];
      for (final entry in rawNotes.whereType<Map>()) {
        try {
          notes.add(SituationNote.fromJson(Map<String, dynamic>.from(entry)));
        } on FormatException {
          // Skip one bad note.
        }
      }
      if (notes.isNotEmpty) {
        restored = restored.copyWith(situationNotes: notes);
      }
    }

    await _requireBox().put(restored.id, restored.toJson());
    return restored;
  }

  Box<Map> _requireBox() {
    final box = _box;
    if (box == null) {
      throw StateError(
        'HiveAnalysisHistoryRepository.init() must be called before use.',
      );
    }
    return box;
  }

  Box<Map> _requireBackupBox() {
    final box = _backupBox;
    if (box == null) {
      throw StateError(
        'HiveAnalysisHistoryRepository.init() must be called before use.',
      );
    }
    return box;
  }

  Box _requireSettingsBox() {
    final box = _settingsBox;
    if (box == null) {
      throw StateError(
        'HiveAnalysisHistoryRepository.init() must be called before use.',
      );
    }
    return box;
  }
}

/// Overridden in `main()` with a [HiveAnalysisHistoryRepository] once Hive
/// has been initialized (see `main.dart`); overridden in tests with an
/// in-memory fake.
final analysisHistoryRepositoryProvider = Provider<AnalysisHistoryRepository>((
  ref,
) {
  throw UnimplementedError(
    'analysisHistoryRepositoryProvider must be overridden (see main.dart) before use.',
  );
});
