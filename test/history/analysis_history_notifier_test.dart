import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/icloud_sync/services/icloud_merge.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/history/state/analysis_history_notifier.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/models/swot_item.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';

import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_project_order_repository.dart';

Project _project({
  String? id,
  required String theme,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return Project(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    theme: theme,
    desiredGoal: 'ゴール',
    matrix: SwotMatrix(
      strengths: [SwotItem(category: SwotCategory.strength, content: '強み')],
    ),
  );
}

void main() {
  late InMemoryAnalysisHistoryRepository repository;
  late InMemoryProjectOrderRepository orderRepository;
  late ProviderContainer container;

  setUp(() {
    repository = InMemoryAnalysisHistoryRepository();
    orderRepository = InMemoryProjectOrderRepository();
    container = ProviderContainer(
      overrides: [
        analysisHistoryRepositoryProvider.overrideWithValue(repository),
        projectOrderRepositoryProvider.overrideWithValue(orderRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('starts by loading whatever the repository already has', () async {
    final existing = _project(
      theme: '既存',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    await repository.save(existing);

    final sessions = await container.read(analysisHistoryProvider.future);
    expect(sessions.single.theme, '既存');
  });

  test('saveOrUpdate adds a new session', () async {
    await container.read(analysisHistoryProvider.future);
    final notifier = container.read(analysisHistoryProvider.notifier);

    final session = _project(
      theme: '新規分析',
      createdAt: DateTime.utc(2026, 2, 1),
      updatedAt: DateTime.utc(2026, 2, 1),
    );
    await notifier.saveOrUpdate(session);

    final sessions = container.read(analysisHistoryProvider).value!;
    expect(sessions.single.theme, '新規分析');
    expect((await repository.loadAll()).single.theme, '新規分析');
  });

  test(
    'saveOrUpdate refuses to wipe a non-empty SWOT with an empty matrix',
    () async {
      await container.read(analysisHistoryProvider.future);
      final notifier = container.read(analysisHistoryProvider.notifier);

      final original = _project(
        id: 'keep-matrix',
        theme: '夏休みの計画',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      await notifier.saveOrUpdate(original);

      await notifier.saveOrUpdate(
        Project(
          id: 'keep-matrix',
          theme: '夏休みの計画',
          desiredGoal: 'ゴールだけ残った下書き',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
          matrix: const SwotMatrix(),
        ),
      );

      final saved = (await repository.loadAll()).single;
      expect(saved.matrix.strengths.single.content, '強み');
      expect(saved.desiredGoal, 'ゴールだけ残った下書き');
    },
  );

  test(
    'saveOrUpdate on an existing id preserves the original createdAt',
    () async {
      await container.read(analysisHistoryProvider.future);
      final notifier = container.read(analysisHistoryProvider.notifier);

      final original = _project(
        id: 'fixed-id',
        theme: '初回',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      await notifier.saveOrUpdate(original);

      final edited = _project(
        id: 'fixed-id',
        theme: '編集後',
        createdAt: DateTime.utc(
          2099,
          1,
          1,
        ), // should be ignored — not a new record
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      await notifier.saveOrUpdate(edited);

      final sessions = container.read(analysisHistoryProvider).value!;
      expect(sessions, hasLength(1));
      expect(sessions.single.theme, '編集後');
      expect(sessions.single.createdAt, DateTime.utc(2026, 1, 1));
    },
  );

  test('newest updatedAt sorts first', () async {
    await container.read(analysisHistoryProvider.future);
    final notifier = container.read(analysisHistoryProvider.notifier);

    await notifier.saveOrUpdate(
      _project(
        theme: '古い',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await notifier.saveOrUpdate(
      _project(
        theme: '新しい',
        createdAt: DateTime.utc(2026, 1, 2),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );

    final sessions = container.read(analysisHistoryProvider).value!;
    expect(sessions.map((s) => s.theme), ['新しい', '古い']);
  });

  test('delete removes a session from both state and the repository', () async {
    await container.read(analysisHistoryProvider.future);
    final notifier = container.read(analysisHistoryProvider.notifier);

    final session = _project(
      id: 'to-delete',
      theme: '削除対象',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    await notifier.saveOrUpdate(session);
    await notifier.delete('to-delete');

    expect(container.read(analysisHistoryProvider).value, isEmpty);
    expect(await repository.loadAll(), isEmpty);
  });

  group('importSessions merge semantics', () {
    test('adds sessions that do not exist locally yet', () async {
      await container.read(analysisHistoryProvider.future);
      final notifier = container.read(analysisHistoryProvider.notifier);

      final imported = [
        _project(
          theme: '輸入A',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ];
      final count = await notifier.importSessions(imported);

      expect(count, 1);
      expect(
        container.read(analysisHistoryProvider).value!.single.theme,
        '輸入A',
      );
    });

    test(
      'an imported session with a newer updatedAt overwrites the local one',
      () async {
        await container.read(analysisHistoryProvider.future);
        final notifier = container.read(analysisHistoryProvider.notifier);

        await notifier.saveOrUpdate(
          _project(
            id: 'shared',
            theme: 'ローカル版',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );

        final count = await notifier.importSessions([
          _project(
            id: 'shared',
            theme: 'インポート版',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 5),
          ),
        ]);

        expect(count, 1);
        expect(
          container.read(analysisHistoryProvider).value!.single.theme,
          'インポート版',
        );
      },
    );

    test('an imported session older than the local one is ignored', () async {
      await container.read(analysisHistoryProvider.future);
      final notifier = container.read(analysisHistoryProvider.notifier);

      await notifier.saveOrUpdate(
        _project(
          id: 'shared',
          theme: '最新のローカル版',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 10),
        ),
      );

      final count = await notifier.importSessions([
        _project(
          id: 'shared',
          theme: '古いバックアップ',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ]);

      expect(count, 0);
      expect(
        container.read(analysisHistoryProvider).value!.single.theme,
        '最新のローカル版',
      );
    });
  });

  group('manual reorder (登録案件リスト drag-to-reorder)', () {
    test(
      'reorder persists the given order and immediately reflects it',
      () async {
        await container.read(analysisHistoryProvider.future);
        final notifier = container.read(analysisHistoryProvider.notifier);

        final a = _project(
          id: 'a',
          theme: 'A',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        );
        final b = _project(
          id: 'b',
          theme: 'B',
          createdAt: DateTime.utc(2026, 1, 2),
          updatedAt: DateTime.utc(2026, 1, 2),
        );
        await notifier.saveOrUpdate(a);
        await notifier.saveOrUpdate(b);
        // Newest-first default would put B before A.
        expect(
          container.read(analysisHistoryProvider).value!.map((p) => p.id),
          ['b', 'a'],
        );

        await notifier.reorder(['a', 'b']);

        expect(
          container.read(analysisHistoryProvider).value!.map((p) => p.id),
          ['a', 'b'],
        );
        expect(orderRepository.load(), ['a', 'b']);
      },
    );

    test(
      'a saved order survives reloading the notifier from scratch',
      () async {
        final notifier = container.read(analysisHistoryProvider.notifier);
        await notifier.saveOrUpdate(
          _project(
            id: 'a',
            theme: 'A',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );
        await notifier.saveOrUpdate(
          _project(
            id: 'b',
            theme: 'B',
            createdAt: DateTime.utc(2026, 1, 2),
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
        );
        await notifier.reorder(['a', 'b']);

        final freshContainer = ProviderContainer(
          overrides: [
            analysisHistoryRepositoryProvider.overrideWithValue(repository),
            projectOrderRepositoryProvider.overrideWithValue(orderRepository),
          ],
        );
        addTearDown(freshContainer.dispose);

        final reloaded = await freshContainer.read(
          analysisHistoryProvider.future,
        );
        expect(reloaded.map((p) => p.id), ['a', 'b']);
      },
    );

    test(
      'a project not yet in the saved order is appended newest-first',
      () async {
        await container.read(analysisHistoryProvider.future);
        final notifier = container.read(analysisHistoryProvider.notifier);

        await notifier.saveOrUpdate(
          _project(
            id: 'a',
            theme: 'A',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );
        await notifier.reorder(['a']);

        // A brand-new project arrives after the manual order was saved.
        await notifier.saveOrUpdate(
          _project(
            id: 'c',
            theme: 'C',
            createdAt: DateTime.utc(2026, 1, 5),
            updatedAt: DateTime.utc(2026, 1, 5),
          ),
        );

        expect(
          container.read(analysisHistoryProvider).value!.map((p) => p.id),
          ['a', 'c'],
        );
      },
    );
  });

  group('applyIcloudMergePlan', () {
    test('upserts remote projects and deletes ids missing from the snapshot', () async {
      await container.read(analysisHistoryProvider.future);
      final notifier = container.read(analysisHistoryProvider.notifier);

      await notifier.saveOrUpdate(
        _project(
          id: 'keep',
          theme: '残る',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await notifier.saveOrUpdate(
        _project(
          id: 'gone',
          theme: '消える',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final fromRemote = _project(
        id: 'new-from-remote',
        theme: '別端末から',
        createdAt: DateTime.utc(2026, 1, 3),
        updatedAt: DateTime.utc(2026, 1, 3),
      );
      await notifier.applyIcloudMergePlan(
        IcloudMergePlan(
          toUpsertLocally: [fromRemote],
          toDeleteLocally: ['gone'],
        ),
      );

      final ids = container
          .read(analysisHistoryProvider)
          .value!
          .map((p) => p.id)
          .toSet();
      expect(ids, {'keep', 'new-from-remote'});
      expect((await repository.loadAll()).map((p) => p.id).toSet(), {
        'keep',
        'new-from-remote',
      });
    });

    test('an empty plan is a no-op', () async {
      await container.read(analysisHistoryProvider.future);
      final notifier = container.read(analysisHistoryProvider.notifier);

      await notifier.saveOrUpdate(
        _project(
          id: 'a',
          theme: 'A',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      await notifier.applyIcloudMergePlan(const IcloudMergePlan());

      expect(
        container.read(analysisHistoryProvider).value!.map((p) => p.id),
        ['a'],
      );
    });
  });
}
