import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/icloud_sync/services/icloud_merge.dart';
import 'package:osm_jiritsu/models/project.dart';

Project _project({
  required String id,
  String theme = 'Theme',
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 1, 1);
  return Project(
    id: id,
    theme: theme,
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  group('planFullRemoteSnapshot', () {
    test('inserts a remote-only project locally', () {
      final remote = _project(id: 'a', updatedAt: DateTime(2026, 1, 2));
      final plan = planFullRemoteSnapshot(local: const [], remote: [remote]);

      expect(plan.toUpsertLocally, [remote]);
      expect(plan.toDeleteLocally, isEmpty);
    });

    test('local-only project is deleted (remote is the full snapshot)', () {
      final local = _project(id: 'a', updatedAt: DateTime(2026, 1, 2));
      final plan = planFullRemoteSnapshot(local: [local], remote: const []);

      expect(plan.toUpsertLocally, isEmpty);
      expect(plan.toDeleteLocally, ['a']);
    });

    test('local newer than remote wins: no upsert, no delete', () {
      final local = _project(
        id: 'a',
        theme: 'Local',
        updatedAt: DateTime(2026, 1, 5),
      );
      final remote = _project(
        id: 'a',
        theme: 'Remote',
        updatedAt: DateTime(2026, 1, 1),
      );
      final plan = planFullRemoteSnapshot(local: [local], remote: [remote]);

      expect(plan.toUpsertLocally, isEmpty);
      expect(plan.toDeleteLocally, isEmpty);
    });

    test('remote newer than local wins: upserted locally', () {
      final local = _project(
        id: 'a',
        theme: 'Local',
        updatedAt: DateTime(2026, 1, 1),
      );
      final remote = _project(
        id: 'a',
        theme: 'Remote',
        updatedAt: DateTime(2026, 1, 5),
      );
      final plan = planFullRemoteSnapshot(local: [local], remote: [remote]);

      expect(plan.toUpsertLocally, hasLength(1));
      expect(plan.toUpsertLocally.single.theme, 'Remote');
      expect(plan.toDeleteLocally, isEmpty);
    });

    test('equal updatedAt on both sides triggers no action', () {
      final ts = DateTime(2026, 1, 3);
      final local = _project(id: 'a', updatedAt: ts);
      final remote = _project(id: 'a', updatedAt: ts);
      final plan = planFullRemoteSnapshot(local: [local], remote: [remote]);

      expect(plan.toUpsertLocally, isEmpty);
      expect(plan.toDeleteLocally, isEmpty);
    });

    test('multiple projects are reconciled independently', () {
      final keepLocal = _project(id: 'keep-local', updatedAt: DateTime(2026, 1, 9));
      final keepLocalRemote = _project(
        id: 'keep-local',
        updatedAt: DateTime(2026, 1, 1),
      );
      final pullRemote = _project(
        id: 'pull-remote',
        theme: 'FromRemote',
        updatedAt: DateTime(2026, 1, 9),
      );
      final deletedLocal = _project(id: 'deleted', updatedAt: DateTime(2026, 1, 1));

      final plan = planFullRemoteSnapshot(
        local: [keepLocal, deletedLocal],
        remote: [keepLocalRemote, pullRemote],
      );

      expect(plan.toUpsertLocally.map((p) => p.id), ['pull-remote']);
      expect(plan.toDeleteLocally, ['deleted']);
    });
  });
}
