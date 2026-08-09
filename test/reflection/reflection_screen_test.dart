import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/project_status.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/models/swot_item.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';
import 'package:osm_jiritsu/reflection/screens/reflection_screen.dart';

import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_project_order_repository.dart';

final _now = DateTime(2026, 1, 1);

Project _project({ProjectStatus status = ProjectStatus.inProgress}) {
  return Project(
    createdAt: _now,
    updatedAt: _now,
    theme: '新しいキャリアについて',
    desiredGoal: '在りたい姿',
    decidedStrategy: '決めた方策',
    decidedFirstStep: '決めた最初の一歩',
    status: status,
    matrix: SwotMatrix(
      strengths: [SwotItem(category: SwotCategory.strength, content: '強み1')],
    ),
  );
}

/// Pushes `ReflectionScreen` on top of a real "home" route (a bare button)
/// rather than making it the app's root route — the 一旦休む/完了 branches
/// call `Navigator.pop()`, which is a no-op with nothing underneath.
Future<InMemoryAnalysisHistoryRepository> pumpScreen(
  WidgetTester tester, {
  required Project project,
}) async {
  final repository = InMemoryAnalysisHistoryRepository();
  await repository.save(project);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analysisHistoryRepositoryProvider.overrideWithValue(repository),
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(AppLanguage.japanese),
        ),
        projectOrderRepositoryProvider.overrideWithValue(
          InMemoryProjectOrderRepository(),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReflectionScreen(project: project),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _submitHowItWent(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    '保存 stays untappable until どうだった？ has text, then advances to the choice screen',
    (tester) async {
      await pumpScreen(tester, project: _project());

      final cta = find.text('保存');
      expect(cta.hitTestable(), findsNothing);

      await tester.enterText(find.byType(TextField), '順調に進んでいます');
      await tester.pumpAndSettle();
      expect(cta.hitTestable(), findsOneWidget);

      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.text('次はどうする？'), findsOneWidget);
    },
  );

  testWidgets(
    '続ける saves the reflection, sets 実施中, and opens Step9 (最初の一歩)',
    (tester) async {
      final repository = await pumpScreen(
        tester,
        project: _project(status: ProjectStatus.onBreak),
      );

      await _submitHowItWent(tester, '一区切りついた');
      await tester.tap(find.text('続ける'));
      // FirstStepFlowScreen starts in a Launching state with an
      // indeterminate spinner, which never lets pumpAndSettle terminate.
      await tester.pump();
      await tester.pump();

      expect(find.text('最初の一歩を決める'), findsOneWidget);

      final saved = (await repository.loadAll()).single;
      expect(saved.status, ProjectStatus.inProgress);
      expect(saved.reflectionHistory, hasLength(1));
      expect(saved.reflectionHistory.single.howItWent, '一区切りついた');
      expect(saved.reflectionHistory.single.nextChoice, '続ける');
    },
  );

  testWidgets(
    '方策を変更する saves the reflection, sets 実施中, and opens Step5 (方策発散)',
    (tester) async {
      final repository = await pumpScreen(
        tester,
        project: _project(status: ProjectStatus.onBreak),
      );

      await _submitHowItWent(tester, '方策が合わなかった');
      await tester.tap(find.text('方策を変更する'));
      // Same Launching-state spinner issue as above.
      await tester.pump();
      await tester.pump();

      expect(find.text('方策を決める'), findsOneWidget);

      final saved = (await repository.loadAll()).single;
      expect(saved.status, ProjectStatus.inProgress);
      expect(saved.reflectionHistory.single.nextChoice, '方策を変更する');
    },
  );

  testWidgets(
    '新しいテーマに取り組む saves the reflection, leaves 現況 unchanged, and starts a fresh wizard',
    (tester) async {
      final repository = await pumpScreen(
        tester,
        project: _project(status: ProjectStatus.inProgress),
      );

      await _submitHowItWent(tester, '別のテーマもやってみたい');
      await tester.tap(find.text('新しいテーマに取り組む'));
      await tester.pumpAndSettle();

      // Lands on the wizard's theme step, not the still-open project.
      expect(find.text('それでは始めましょう'), findsOneWidget);

      final saved = (await repository.loadAll()).single;
      expect(saved.status, ProjectStatus.inProgress);
      expect(saved.reflectionHistory.single.nextChoice, '新しいテーマに取り組む');
    },
  );

  testWidgets('一旦休む saves 休憩中 and returns to the previous screen', (
    tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      project: _project(status: ProjectStatus.inProgress),
    );

    await _submitHowItWent(tester, '少し疲れた');
    await tester.tap(find.text('一旦休む'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(find.text('どうだった？'), findsNothing);

    final saved = (await repository.loadAll()).single;
    expect(saved.status, ProjectStatus.onBreak);
    expect(saved.reflectionHistory.single.nextChoice, '一旦休む');
  });

  testWidgets('完了 saves 完了 and returns to the previous screen', (
    tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      project: _project(status: ProjectStatus.inProgress),
    );

    await _submitHowItWent(tester, 'やりきった');
    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);

    final saved = (await repository.loadAll()).single;
    expect(saved.status, ProjectStatus.completed);
    expect(saved.reflectionHistory.single.nextChoice, '完了');
  });
}
