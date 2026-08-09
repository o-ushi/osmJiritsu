import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/history/data/sample_project.dart';
import 'package:osm_jiritsu/history/state/analysis_history_notifier.dart';

import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_project_order_repository.dart';

ProviderContainer _container(InMemoryAnalysisHistoryRepository repository) {
  final container = ProviderContainer(
    overrides: [
      analysisHistoryRepositoryProvider.overrideWithValue(repository),
      projectOrderRepositoryProvider.overrideWithValue(
        InMemoryProjectOrderRepository(),
      ),
    ],
  );
  return container;
}

void main() {
  // `testWidgets` (not `test`) so `rootBundle.loadString` in
  // `loadSampleProjects` has a real, bindings-backed asset bundle to read
  // `assets/data/sample_project.json` from — no widget is ever pumped.
  testWidgets(
    'loadSampleProjects parses the bundled 例題 into a non-empty project',
    (tester) async {
      final projects = await loadSampleProjects();

      expect(projects, hasLength(1));
      expect(projects.single.theme, contains('週末'));
      expect(projects.single.matrix.isNotEmpty, isTrue);
    },
  );

  testWidgets('a fresh install seeds the bundled sample project exactly once', (
    tester,
  ) async {
    final repository = InMemoryAnalysisHistoryRepository(false);
    final container = _container(repository);
    addTearDown(container.dispose);

    final projects = await container.read(analysisHistoryProvider.future);

    expect(projects, hasLength(1));
    expect(await repository.hasSeededSampleProject(), isTrue);
  });

  testWidgets(
    'an already-seeded install does not add the sample project again',
    (tester) async {
      final repository = InMemoryAnalysisHistoryRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final projects = await container.read(analysisHistoryProvider.future);

      expect(projects, isEmpty);
    },
  );

  testWidgets(
    'deleting the seeded sample project keeps it gone on a later launch',
    (tester) async {
      final repository = InMemoryAnalysisHistoryRepository(false);
      final container = _container(repository);
      addTearDown(container.dispose);

      final seeded = await container.read(analysisHistoryProvider.future);
      await container
          .read(analysisHistoryProvider.notifier)
          .delete(seeded.single.id);

      // Simulate a later cold launch reading from the same underlying store.
      final relaunch = _container(repository);
      addTearDown(relaunch.dispose);

      expect(await relaunch.read(analysisHistoryProvider.future), isEmpty);
    },
  );

  testWidgets(
    'a factory reset re-seeds the sample project on the next launch',
    (tester) async {
      final repository = InMemoryAnalysisHistoryRepository(false);
      final container = _container(repository);
      addTearDown(container.dispose);

      await container.read(analysisHistoryProvider.future);
      await container.read(analysisHistoryProvider.notifier).clear();

      // Simulate the next cold launch after "すべてのデータを初期化".
      final relaunch = _container(repository);
      addTearDown(relaunch.dispose);

      expect(
        await relaunch.read(analysisHistoryProvider.future),
        hasLength(1),
      );
    },
  );
}
