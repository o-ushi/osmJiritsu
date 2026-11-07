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
  // No widget is ever pumped, so plain `test` with real async is enough:
  // the binding gives `rootBundle` its asset bundle, and `testWidgets`'
  // fake clock would leave the provider's future waiting forever.
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loadSampleProjects parses the bundled 例題 into a non-empty project',
    () async {
      final projects = await loadSampleProjects();

      expect(projects, hasLength(1));
      expect(projects.single.theme, contains('週末'));
      expect(projects.single.matrix.isNotEmpty, isTrue);
    },
  );

  test(
    'a fresh install seeds the bundled sample project exactly once',
    () async {
      final repository = InMemoryAnalysisHistoryRepository(false);
      final container = _container(repository);
      addTearDown(container.dispose);

      final projects = await container.read(analysisHistoryProvider.future);

      expect(projects, hasLength(1));
      expect(await repository.hasSeededSampleProject(), isTrue);
    },
  );

  test(
    'an already-seeded install does not add the sample project again',
    () async {
      final repository = InMemoryAnalysisHistoryRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final projects = await container.read(analysisHistoryProvider.future);

      expect(projects, isEmpty);
    },
  );

  test(
    'deleting the seeded sample project keeps it gone on a later launch',
    () async {
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

  test(
    'a factory reset re-seeds the sample project on the next launch',
    () async {
      final repository = InMemoryAnalysisHistoryRepository(false);
      final container = _container(repository);
      addTearDown(container.dispose);

      await container.read(analysisHistoryProvider.future);
      await container.read(analysisHistoryProvider.notifier).clear();

      // Simulate the next cold launch after "すべてのデータを初期化".
      final relaunch = _container(repository);
      addTearDown(relaunch.dispose);

      expect(await relaunch.read(analysisHistoryProvider.future), hasLength(1));
    },
  );
}
